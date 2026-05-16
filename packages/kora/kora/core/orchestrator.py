# =============================================================================
# Kora — Core Orchestrator
#
# O orquestrador central da Kora. Recebe uma mensagem, decide a estratégia,
# monta o contexto, chama o LLM e retorna a resposta.
#
# Modos de operação:
#   - direct: envia direto ao Ollama com system prompt (streaming preferido)
#   - rag:    busca contexto no Brain API e injeta no prompt
#   - auto:   usa Smart Routing (grounding.py) para escolher entre direct/rag
# =============================================================================

from __future__ import annotations

import asyncio
import json
import logging
import re
import subprocess
import time
from pathlib import Path
from typing import Any, AsyncGenerator, Dict, List, Optional

from ..audit.events import log_event
from ..core.config import load_system_prompt
from ..core.policy import AUTHORIZED_ADMINS, PolicyContext, RiskLevel, classify_command
from ..integrations import brain as brain_adapter
from ..integrations.n8n import N8nClient
from ..llm import ollama as ollama_adapter
from ..memory import MemoryCandidate, MemoryClassifier, MemoryQueue, MemoryType
from .grounding import requires_rag, validate_command_hallucination
from .tool_registry import get_registry_summary, find_tool
from .identity import (
    detect_runtime_identity,
    get_known_user_profile,
    should_greet,
    get_greeting,
    is_identity_query,
    get_identity_response
)

logger = logging.getLogger("kora.core.orchestrator")

# Regex to find action proposal JSON blocks
ACTION_PROPOSAL_RE = re.compile(r"```json\s*(\{.*?" + re.escape('"type": "action_proposal"') + r".*?\})\s*```", re.DOTALL)

# In-memory session tracking
SESSION_METADATA: Dict[str, Any] = {}

async def _prepare_session_and_context(
    message: str,
    session_id: str,
    user: str,
    speaker: Optional[str],
    is_voice: bool,
    mode: str,
) -> Dict[str, Any]:
    """Unified helper to handle session state, routing, and context retrieval."""
    t0 = time.monotonic()
    is_new_session = session_id not in SESSION_METADATA
    
    if is_new_session:
        SESSION_METADATA[session_id] = {"user": user, "speaker": speaker, "timestamp": t0}
    else:
        old_meta = SESSION_METADATA[session_id]
        if old_meta.get("user") != user or old_meta.get("speaker") != speaker:
            SESSION_METADATA[session_id] = {"user": user, "speaker": speaker, "timestamp": t0}

    runtime_id = detect_runtime_identity()
    profile = get_known_user_profile(user)
    
    greeting = ""
    if should_greet(session_id, user):
        greeting = get_greeting(profile)

    system_prompt = load_system_prompt()
    
    # Injetar informações de perfil se disponível
    if profile:
        profile_context = (
            f"\n\n## Perfil do Usuário Reconhecido\n"
            f"- Nome: {profile['full_name']} ({profile['display_name']})\n"
            f"- Papel: {profile['role']}\n"
            f"- Preferências: {', '.join(profile['preferences'])}\n"
        )
        system_prompt += profile_context

    identity_context = (
        f"\n\n## Identidade do Usuário Atual\n"
        f"- Usuário do sistema: {user}\n"
        f"- Orígem: {'Voz' if is_voice else 'Terminal/Chat'}\n"
        f"- Reconhecido como: {profile['display_name'] if profile else 'Desconhecido'}\n"
        f"- Sessão: {session_id}\n"
        f"- Primeira interação na sessão: {'Sim' if is_new_session else 'Não'}\n"
    )
    if user in AUTHORIZED_ADMINS:
        identity_context += "- Autorização: Administrador Kryonix (Local)\n"
    else:
        identity_context += "- Autorização: Usuário não privilegiado (Restrito)\n"
    
    if greeting:
        identity_context += f"- Saudação sugerida: {greeting}\n"
    
    system_prompt += identity_context
    registry_summary = get_registry_summary()
    system_prompt += f"\n\n## Ferramentas Disponíveis (Tool Registry)\n{registry_summary}"
    
    active_mode = mode
    if mode == "auto":
        active_mode = "rag" if requires_rag(message) else "direct"

    context_text = ""
    brain_used = False
    if active_mode == "rag":
        brain_result = await brain_adapter.search(query=message)
        if brain_result.get("status") != "error" and brain_result.get("answer"):
            context_text = brain_result["answer"]
            brain_used = True

    return {
        "system_prompt": system_prompt,
        "context_text": context_text,
        "active_mode": active_mode,
        "brain_used": brain_used,
        "start_time": t0,
    }

async def _handle_action_proposal(answer: str, user: str, session_id: str) -> tuple[str, Optional[dict]]:
    """
    Extract action proposal from answer, validate it, and return cleaned answer + action metadata.
    """
    match = ACTION_PROPOSAL_RE.search(answer)
    if not match:
        return answer, None

    json_text = match.group(1)
    cleaned_answer = answer[:match.start()].strip() + "\n" + answer[match.end():].strip()
    
    try:
        proposal = json.loads(json_text)
        action_type = proposal.get("action")
        
        # Validation
        if action_type == "command_execute":
            command = proposal.get("command")
            if not command:
                return cleaned_answer, {"error": "Comando não especificado na proposta."}
            
            # Grounding check
            hallucination_error = validate_command_hallucination(command)
            if hallucination_error:
                return cleaned_answer + f"\n\n⚠️ {hallucination_error}", None
            
            # Policy check
            ctx = PolicyContext(user=user)
            risk = classify_command(command, context=ctx)
            proposal["risk"] = risk.value
            
            # Save as pending if risk is medium/high or requires_confirmation is True
            if risk in [RiskLevel.MEDIUM, RiskLevel.HIGH, RiskLevel.CRITICAL] or proposal.get("requires_confirmation"):
                await _save_pending_action(command, risk, user)
                proposal["requires_confirmation"] = True
                return cleaned_answer, proposal
            
            return cleaned_answer, proposal

        elif action_type == "n8n_workflow":
            # n8n always requires confirmation in this phase
            proposal["requires_confirmation"] = True
            await _save_pending_action(f"n8n:{proposal.get('path')}", RiskLevel.MEDIUM, user)
            return cleaned_answer, proposal

    except Exception as e:
        logger.error("Failed to parse action proposal: %s", e)
        return answer, {"error": f"Erro ao processar proposta: {e}"}

    return cleaned_answer, None

async def _save_pending_action(command: str, risk: RiskLevel, user: str):
    """Save a command to the pending actions file."""
    state_dir = Path.home() / ".local/state/kryonix/kora"
    state_dir.mkdir(parents=True, exist_ok=True)
    state_file = state_dir / "pending_action.json"
    
    data = {
        "command": command,
        "risk": risk.value,
        "user": user,
        "timestamp": time.time()
    }
    with open(state_file, "w") as f:
        json.dump(data, f)
    logger.info("Pending action saved: %s (Risk: %s)", command, risk.value)

async def process_message(
    message: str,
    session_id: str = "default",
    user: str = "unknown",
    speaker: str | None = None,
    is_voice: bool = False,
    mode: str = "auto",
) -> dict[str, Any]:
    """Process an incoming message (Non-streaming)."""
    ctx = await _prepare_session_and_context(message, session_id, user, speaker, is_voice, mode)
    
    # Detecção determinística de identidade
    if is_identity_query(message):
        profile = get_known_user_profile(user)
        if profile:
            answer = get_identity_response(profile)
            asyncio.create_task(_process_background_memory(message, answer, user))
            return {
                "answer": answer,
                "action": None,
                "mode": "deterministic",
                "brain_used": False,
                "elapsed_sec": time.monotonic() - ctx["start_time"],
                "model": "identity-module",
            }
    
    llm_result = await ollama_adapter.generate_completion(
        prompt=message,
        system_prompt=ctx["system_prompt"],
        context=ctx["context_text"]
    )
    
    raw_answer = llm_result.get("answer", "Erro interno.")
    answer, action = await _handle_action_proposal(raw_answer, user, session_id)
    
    asyncio.create_task(_process_background_memory(message, answer, user))

    return {
        "answer": answer.strip(),
        "action": action,
        "mode": ctx["active_mode"],
        "brain_used": ctx["brain_used"],
        "elapsed_sec": time.monotonic() - ctx["start_time"],
        "model": llm_result.get("model"),
    }

async def process_message_stream(
    message: str,
    session_id: str = "default",
    user: str = "unknown",
    speaker: str | None = None,
    is_voice: bool = False,
    mode: str = "auto",
) -> AsyncGenerator[str, None]:
    """Process an incoming message and yield a stream of chunks."""
    ctx = await _prepare_session_and_context(message, session_id, user, speaker, is_voice, mode)
    
    # Detecção determinística de identidade
    if is_identity_query(message):
        profile = get_known_user_profile(user)
        if profile:
            yield f"data: {json.dumps({'type': 'meta', 'mode': 'deterministic', 'session_id': session_id})}\n\n"
            answer = get_identity_response(profile)
            for chunk in [answer[i:i+20] for i in range(0, len(answer), 20)]:
                yield f"data: {json.dumps({'type': 'content', 'chunk': chunk})}\n\n"
                await asyncio.sleep(0.02)
            asyncio.create_task(_process_background_memory(message, answer, user))
            yield f"data: {json.dumps({'type': 'stats', 'elapsed_sec': time.monotonic() - ctx['start_time']})}\n\n"
            return

    yield f"data: {json.dumps({'type': 'meta', 'mode': ctx['active_mode'], 'session_id': session_id})}\n\n"
    
    full_answer = ""
    async for chunk in ollama_adapter.generate_stream(
        prompt=message,
        system_prompt=ctx["system_prompt"],
        context=ctx["context_text"]
    ):
        full_answer += chunk
        yield f"data: {json.dumps({'type': 'content', 'chunk': chunk})}\n\n"
    
    # Post-processing for actions
    answer, action = await _handle_action_proposal(full_answer, user, session_id)
    if action:
        yield f"data: {json.dumps({'type': 'action', 'proposal': action})}\n\n"
    
    asyncio.create_task(_process_background_memory(message, answer, user))
    yield f"data: {json.dumps({'type': 'stats', 'elapsed_sec': time.monotonic() - ctx['start_time']})}\n\n"

async def _process_background_memory(message: str, answer: str, user: str):
    """Extract and queue memories from the conversation exchange."""
    try:
        # Note: Internal imports to avoid circular dependency
        from kora.memory import MemoryClassifier, MemoryQueue
        from kora.llm.ollama import OllamaAdapter
        
        # We can use the default model for memory extraction
        llm = OllamaAdapter()
        classifier = MemoryClassifier(llm_provider=llm)
        candidates = await classifier.classify(message, answer, user=user)
        if candidates:
            queue = MemoryQueue()
            for c in candidates:
                queue.push(c)
    except Exception as e:
        logger.error("Background memory processing failed: %s", e)

async def confirm_pending_action(session_id: str = "default") -> dict[str, Any]:
    """Confirm and execute the last pending action."""
    state_file = Path.home() / ".local/state/kryonix/kora/pending_action.json"
    if not state_file.exists():
        return {"status": "error", "message": "Nenhuma ação pendente."}

    try:
        with open(state_file, "r") as f:
            data = json.load(f)
        command = data.get("command")
        
        if command.startswith("n8n:"):
            # Handle n8n trigger
            path = command.split(":", 1)[1]
            client = N8nClient()
            # This is a placeholder for actual n8n triggering
            # res = await client.trigger_webhook(path, payload={})
            return {"status": "success", "message": f"Workflow n8n disparado: {path}"}

        # Handle system command
        process = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=60)
        state_file.unlink()
        return {
            "status": "success" if process.returncode == 0 else "failed",
            "command": command,
            "stdout": process.stdout,
            "stderr": process.stderr,
            "returncode": process.returncode
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

# =============================================================================
# Kora — Core Orchestrator (Intelligence Core)
#
# O orquestrador central da Kora. Recebe uma mensagem, decide a intenção
# via router, monta o plano, puxa contexto, chama o LLM, e avalia a resposta
# via quality guard.
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
from .conversation import get_recent_turns
from .identity import (
    detect_runtime_identity,
    resolve_identity,
    should_greet,
    get_identity_response,
    is_identity_query
)

from .router import CognitiveRouter, Intent
from .capabilities import get_deterministic_capabilities_response
from .answer_planner import AnswerPlanner
from .quality import QualityGuard
from .normalizer import normalize_text
from ..mind import KoraMind, MindInput
from ..training import record_interaction

logger = logging.getLogger("kora.core.orchestrator")

import collections
import hashlib
import httpx
from ..llm.ollama import OLLAMA_URL

class SimpleLRUCache:
    def __init__(self, capacity: int = 256):
        self.capacity = capacity
        self.cache = collections.OrderedDict()

    def get(self, key: str) -> Any | None:
        if key not in self.cache:
            return None
        self.cache.move_to_end(key)
        return self.cache[key]

    def put(self, key: str, value: Any):
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = value
        if len(self.cache) > self.capacity:
            self.cache.popitem(last=False)

    def clear(self):
        self.cache.clear()

_CAG_CACHE = SimpleLRUCache(capacity=256)
_LAST_GRAPH_MTIME = 0.0

def _check_and_invalidate_cache():
    global _LAST_GRAPH_MTIME
    graph_path = Path("/var/lib/kryonix/brain/storage/graph_chunk_entity_relation.graphml")
    if graph_path.exists():
        try:
            mtime = graph_path.stat().st_mtime
            if _LAST_GRAPH_MTIME == 0.0:
                _LAST_GRAPH_MTIME = mtime
            elif mtime > _LAST_GRAPH_MTIME:
                logger.info("GraphRAG index rebuild detected. Clearing CAG cache.")
                _CAG_CACHE.clear()
                _LAST_GRAPH_MTIME = mtime
        except Exception as e:
            logger.warning(f"Error checking graph file modification time: {e}")

async def get_query_embedding(text: str) -> list[float] | None:
    try:
        payload = {
            "model": "nomic-embed-text",
            "prompt": text
        }
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.post(f"{OLLAMA_URL}/api/embeddings", json=payload)
            if resp.status_code == 200:
                return resp.json().get("embedding")
    except Exception as e:
        logger.warning(f"Error fetching query embedding: {e}")
    return None

ACTION_PROPOSAL_RE = re.compile(r"```json\s*(\{.*?" + re.escape('"type": "action_proposal"') + r".*?\})\s*```", re.DOTALL)
SESSION_METADATA: Dict[str, Any] = {}

async def _prepare_session_and_context(
    message: str,
    session_id: str,
    user: str,
    speaker: Optional[str],
    is_voice: bool,
    mode: str,
    intent: str = "general_chat"
) -> Dict[str, Any]:
    t0 = time.monotonic()
    is_new_session = session_id not in SESSION_METADATA

    if is_new_session:
        SESSION_METADATA[session_id] = {"user": user, "speaker": speaker, "timestamp": t0}
    else:
        old_meta = SESSION_METADATA[session_id]
        if old_meta.get("user") != user or old_meta.get("speaker") != speaker:
            SESSION_METADATA[session_id] = {"user": user, "speaker": speaker, "timestamp": t0}

    runtime_info = detect_runtime_identity()
    if user and user != "unknown":
        runtime_info["user"] = user

    identity_ctx = resolve_identity(runtime_info)
    profile = identity_ctx["resolved_identity"]
    identity_trust = identity_ctx["identity_trust"]

    greeting = ""
    if should_greet(profile):
        greeting = get_identity_response(profile)

    system_prompt = load_system_prompt()

    profile_context = ""
    if profile:
        profile_context = (
            f"\n\n## Perfil do Usuário Reconhecido\n"
            f"- Nome: {profile['full_name']} ({profile['display_name']})\n"
            f"- Papel: {profile['role']}\n"
            f"- Preferências Estáticas: {', '.join(profile['preferences'])}\n"
        )
        system_prompt += profile_context

    # Injeção de aprendizados dinâmicos (Personal Learning Engine)
    try:
        from kora.core.learning import LearningEngine
        learning_engine = LearningEngine()
        learned_profile = learning_engine.get_profile(user)

        learned_context = f"\n\n## Perfil de Aprendizado Dinâmico (Kora Learning Engine)\n"
        if learned_profile.get("active_projects"):
            learned_context += f"- Projetos Ativos: {', '.join(learned_profile['active_projects'])}\n"
        if learned_profile.get("technical_vocabulary"):
            learned_context += f"- Vocabulário de Interesse: {', '.join(learned_profile['technical_vocabulary'])}\n"
        if learned_profile.get("user_preferences"):
            learned_context += f"- Preferências Aprendidas: {', '.join(learned_profile['user_preferences'])}\n"
        system_prompt += learned_context
        profile_context += learned_context
    except Exception as e:
        logger.error(f"Erro ao injetar perfil de aprendizado dinâmico: {e}")

    # Injeção de Diretrizes de Estilo de Voz (Voice Style Profile)
    if user in ["rocha", "ragton"]:
        style_directive = (
            "\n\n## 🎙️ Diretrizes de Voz e Tom (Gabriel/Ragton)\n"
            "- **Tom de Voz**: Responda com naturalidade tecnica, calma e profissional. Sem firula e sem despejar status interno em conversa casual.\n"
            "- **Estilo Cognitivo**: Seja uma parceira de engenharia técnica. Use termos técnicos avançados do NixOS/Glacier e Linux com precisão.\n"
            "- **Estrutura de Fala**: Suas respostas devem ser concisas e estruturadas em parágrafos ou tópicos curtos (ideal para leitura TTS fluida, sem blocos de texto massivos).\n"
            "- **Anti-Programa**: Responda primeiro ao humano, depois ao sistema.\n"
        )
    elif user in ["nina", "nicoly"]:
        style_directive = (
            "\n\n## 🎙️ Diretrizes de Voz e Tom (Nicoly)\n"
            "- **Tom de Voz**: Responda com um tom feminino, amigável, educado e prestativo.\n"
            "- **Estilo Cognitivo**: Ajude com tarefas gerais, mantendo segredo sobre memórias ou privilégios de administrador do Ragton.\n"
            "- **Estrutura de Fala**: Simples, direta e agradável.\n"
        )
    else:
        style_directive = (
            "\n\n## 🎙️ Diretrizes de Voz e Tom (Visitante)\n"
            "- **Tom de Voz**: Responda com um tom feminino, neutro, impessoal e estritamente informativo.\n"
            "- **Restrição**: Não revele detalhes operacionais ou preferências privadas.\n"
        )
    system_prompt += style_directive

    # Injeção de Consciência Operacional (Live System State)
    try:
        from kora.core.operational import get_operational_context, format_operational_prompt
        oper_ctx = get_operational_context()
        oper_prompt = format_operational_prompt(oper_ctx)
        system_prompt += f"\n\n{oper_prompt}"
    except Exception as e:
        logger.error(f"Erro ao injetar consciência operacional: {e}")

    identity_context = (
        f"\n\n## Identidade do Usuário Atual\n"
        f"- Usuário do sistema (Claimed): {user}\n"
        f"- Nível de Confiança: {identity_trust}\n"
        f"- Orígem: {'Voz' if is_voice else 'Terminal/Chat'}\n"
        f"- Reconhecido como: {profile['display_name'] if profile else 'Desconhecido'}\n"
        f"- Sessão: {session_id}\n"
    )
    if user in AUTHORIZED_ADMINS:
        identity_context += "- Autorização: Administrador Kryonix (Local)\n"
    else:
        identity_context += "- Autorização: Usuário não privilegiado (Restrito)\n"

    if greeting:
        identity_context += f"- Saudação sugerida: {greeting}\n"

    system_prompt += identity_context

    if identity_trust == "hint":
        system_prompt += (
            "\n\n## CONSTRANGIMENTOS DE SEGURANÇA (TRUST: HINT)\n"
            "O usuário atual foi identificado apenas por hint de ambiente/USER (não verificado).\n"
            "1. Você PODE usar o nome e preferências do usuário para personalizar a conversa e saudação.\n"
            "2. Você **NÃO DEVE** revelar segredos, senhas, chaves privadas ou dados de alta confidencialidade.\n"
            "3. Você **NÃO DEVE** propor comandos de alto risco silenciosamente.\n"
        )

    registry_summary = get_registry_summary()
    system_prompt += f"\n\n## Ferramentas Disponíveis (Tool Registry)\n{registry_summary}"



    active_mode = mode
    if mode == "auto":
        active_mode = "rag" if (requires_rag(message) or intent == Intent.PROJECT_KNOWLEDGE) else "direct"

    context_text = ""
    brain_used = False
    searched_files = []
    if active_mode == "rag":
        brain_result = await brain_adapter.search(query=message)
        status = brain_result.get("status")
        answer_text = brain_result.get("answer", "")
        
        is_no_grounding = (
            status in ["no_grounding", "low_confidence"]
            or "não encontrei grounding suficiente" in answer_text.lower()
            or "grounding recuperado, mas" in answer_text.lower()
        )
        
        sources = brain_result.get("sources", [])
        if sources:
            searched_files = list(dict.fromkeys(s.get("file") for s in sources if s.get("file")))
            
        if not is_no_grounding and answer_text:
            context_text = answer_text
            brain_used = True

    # Injecting capabilities/status awareness to avoid hallucination
    # Wake-word false
    system_prompt += "\n\n## Wake-Word Status\nO wake-word está INATIVO/PENDENTE. Não diga que você já acorda ouvindo seu nome."

    return {
        "system_prompt": system_prompt,
        "context_text": context_text,
        "active_mode": active_mode,
        "brain_used": brain_used,
        "searched_files": searched_files,
        "start_time": t0,
        "trust_level": identity_trust,
        "wake_word_ready": False,
        "speaker_id_ready": False,
        "greeting": greeting,
        "profile_context": profile_context,
        "identity_trust": identity_trust,
        "system_state": {
            "active_mode": active_mode,
            "brain_used": brain_used,
            "wake_word_ready": False,
            "speaker_id_ready": False,
        },
        "safety_context": {
            "voice_never_authorizes_critical_actions": True,
            "wake_word_ready": False,
            "speaker_id_ready": False,
            "identity_trust": identity_trust,
        },
    }

async def _handle_action_proposal(answer: str, user: str, session_id: str) -> tuple[str, Optional[dict]]:
    match = ACTION_PROPOSAL_RE.search(answer)
    if not match:
        return answer, None

    json_text = match.group(1)
    cleaned_answer = answer[:match.start()].strip() + "\n" + answer[match.end():].strip()

    try:
        proposal = json.loads(json_text)
        action_type = proposal.get("action")

        if action_type == "command_execute":
            command = proposal.get("command")
            if not command:
                return cleaned_answer, {"error": "Comando não especificado na proposta."}

            hallucination_error = validate_command_hallucination(command)
            if hallucination_error:
                return cleaned_answer + f"\n\n⚠️ {hallucination_error}", None

            id_ctx = resolve_identity({"user": user})
            ctx = PolicyContext(user=user, trust=id_ctx["identity_trust"], source=id_ctx["permission_source"])
            risk = classify_command(command, context=ctx)
            proposal["risk"] = risk.value

            if risk in [RiskLevel.MEDIUM, RiskLevel.HIGH, RiskLevel.CRITICAL] or proposal.get("requires_confirmation"):
                await _save_pending_action(command, risk, user)
                proposal["requires_confirmation"] = True

            return cleaned_answer, proposal

        elif action_type == "n8n_workflow":
            proposal["requires_confirmation"] = True
            await _save_pending_action(f"n8n:{proposal.get('path')}", RiskLevel.MEDIUM, user)
            return cleaned_answer, proposal

    except Exception as e:
        logger.error("Failed to parse action proposal: %s", e)
        return answer, {"error": f"Erro ao processar proposta: {e}"}

    return cleaned_answer, None

async def _save_pending_action(command: str, risk: RiskLevel, user: str):
    state_dir = Path.home() / ".local/state/kryonix/kora"
    state_dir.mkdir(parents=True, exist_ok=True)
    state_file = state_dir / "pending_action.json"
    data = {"command": command, "risk": risk.value, "user": user, "timestamp": time.time()}
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
    t0 = time.monotonic()
    original_message = message

    normalized = normalize_text(message, user)
    message = normalized.normalized

    # Cache Augmented Generation (CAG) Lookup
    _check_and_invalidate_cache()
    embedding = await get_query_embedding(message)
    if embedding:
        cache_key = hashlib.sha256(json.dumps(embedding).encode()).hexdigest()
    else:
        cache_key = hashlib.sha256(message.encode()).hexdigest()

    cached_entry = _CAG_CACHE.get(cache_key)
    if cached_entry:
        logger.info(f"CAG Cache HIT for query: '{message}'")
        cached_result = dict(cached_entry)
        cached_result["elapsed_sec"] = time.monotonic() - t0
        cached_result["model"] = "kora-cag-cache"
        return cached_result

    router = CognitiveRouter()
    route = await router.route(message)

    if route.intent == Intent.IDENTITY_QUERY or is_identity_query(message):
        runtime_info = detect_runtime_identity()
        if user and user != "unknown":
            runtime_info["user"] = user
        identity_ctx = resolve_identity(runtime_info)
        profile = identity_ctx["resolved_identity"]
        if profile:
            answer = get_identity_response(profile)
            asyncio.create_task(_process_background_memory(message, answer, normalized.user_id))
            from .conversation import append_turn
            append_turn(user_text=message, assistant_text=answer, intent=route.intent)
            _record_training_event(
                user=normalized.user_id,
                source="voice" if is_voice else "text",
                original_message=original_message,
                normalized_message=message,
                intent=route.intent,
                answer=answer,
                brain_used=False,
                used_tool=False,
            )
            return {
                "answer": answer,
                "action": None,
                "mode": "deterministic",
                "brain_used": False,
                "elapsed_sec": time.monotonic() - t0,
                "model": "identity-module"
            }

    ctx = await _prepare_session_and_context(message, session_id, normalized.user_id, speaker, is_voice, mode, intent=route.intent)

    if ctx["active_mode"] == "rag" and not ctx["brain_used"]:
        from kora.core.grounding import requires_rag
        if requires_rag(message) or route.intent == Intent.PROJECT_KNOWLEDGE:
            files_str = ""
            if ctx.get("searched_files"):
                files_str = "\n\nArquivos consultados no índice:\n" + "\n".join(f"- {f}" for f in ctx["searched_files"][:5])
            
            refusal_msg = (
                "Não encontrei informações suficientes no meu cérebro técnico (GraphRAG/Vault) para responder sobre isso com segurança.\n\n"
                "Por favor, ingira a documentação ou notas correspondentes no meu Obsidian Vault ou registre uma proposta de aprendizado para que eu possa aprender."
                f"{files_str}"
            )
            
            return {
                "answer": refusal_msg,
                "action": None,
                "mode": "rag",
                "brain_used": False,
                "elapsed_sec": time.monotonic() - t0,
                "model": "kora-anti-hallucination",
            }
    planner = AnswerPlanner()
    plan = await planner.plan(message, route.intent, ctx["trust_level"])

    if plan.must_answer:
        ctx["system_prompt"] += "\n\n## Plano de Resposta Obrigatório\nVocê deve obrigatoriamente abordar:\n- " + "\n- ".join(plan.must_answer)

    if normalized.corrections_applied:
        ctx["system_prompt"] += (
            "\n\n## Normalizacao aplicada\n"
            f"- original: {original_message}\n"
            f"- normalizado: {message}\n"
            f"- correcoes: {normalized.corrections_applied}\n"
        )
    if normalized.aliases_detected:
        ctx["system_prompt"] += f"\n\n## Aliases detectados\n{json.dumps(normalized.aliases_detected, ensure_ascii=False)}\n"

    system_state = dict(ctx.get("system_state", {}))
    if route.intent == Intent.CAPABILITIES_QUERY:
        runtime_info = detect_runtime_identity()
        if user and user != "unknown":
            runtime_info["user"] = user
        identity_ctx = resolve_identity(runtime_info)
        profile = identity_ctx["resolved_identity"]
        system_state["capabilities_summary"] = get_deterministic_capabilities_response(normalized.user_id, profile)

    mind = KoraMind()
    mind_output = await mind.respond(
        MindInput(
            user_text=original_message,
            normalized_text=message,
            user_id=normalized.user_id,
            identity_trust=ctx["identity_trust"],
            source="voice" if is_voice else "text",
            intent=route.intent,
            conversation_history=get_recent_turns(limit=6),
            profile_context=ctx.get("profile_context", ""),
            system_state=system_state,
            safety_context=ctx.get("safety_context", {}),
        ),
        system_prompt=ctx["system_prompt"],
        rag_context=ctx["context_text"],
    )

    raw_answer = mind_output.answer
    answer, action = await _handle_action_proposal(raw_answer, user, session_id)

    guard = QualityGuard()
    q_result = guard.check_answer(message, answer, plan, ctx)
    if not q_result.passed:
        logger.warning(f"Quality guard failed: {q_result.reason}. Using repaired answer.")
        answer = q_result.repaired_answer

    asyncio.create_task(_process_background_memory(message, answer, normalized.user_id))
    from .conversation import append_turn
    append_turn(user_text=message, assistant_text=answer, intent=route.intent)

    _record_training_event(
        user=normalized.user_id,
        source="voice" if is_voice else "text",
        original_message=original_message,
        normalized_message=message,
        intent=route.intent,
        answer=answer,
        brain_used=ctx["brain_used"],
        used_tool=bool(action),
    )

    response_dict = {
        "answer": answer.strip(),
        "action": action,
        "mode": ctx["active_mode"],
        "brain_used": ctx["brain_used"],
        "elapsed_sec": time.monotonic() - t0,
        "model": "kora-mind",
    }

    if response_dict["brain_used"]:
        _CAG_CACHE.put(cache_key, response_dict)

    return response_dict


def _record_training_event(
    *,
    user: str,
    source: str,
    original_message: str,
    normalized_message: str,
    intent: str,
    answer: str,
    brain_used: bool,
    used_tool: bool,
) -> None:
    try:
        record_interaction(
            user_id=user,
            source=source,
            original_text=original_message,
            normalized_text=normalized_message,
            intent=intent,
            answer=answer,
            used_rag=brain_used,
            used_tool=used_tool,
        )
    except Exception as exc:
        logger.error("Training event logging failed: %s", exc)

async def process_message_stream(
    message: str,
    session_id: str = "default",
    user: str = "unknown",
    speaker: str | None = None,
    is_voice: bool = False,
    mode: str = "auto",
) -> AsyncGenerator[str, None]:
    result = await process_message(
        message=message,
        session_id=session_id,
        user=user,
        speaker=speaker,
        is_voice=is_voice,
        mode=mode,
    )
    yield f"data: {json.dumps({'type': 'meta', 'mode': result.get('mode'), 'session_id': session_id})}\n\n"
    answer = result.get("answer", "")
    for chunk in [answer[i:i + 40] for i in range(0, len(answer), 40)]:
        yield f"data: {json.dumps({'type': 'content', 'chunk': chunk})}\n\n"
        await asyncio.sleep(0.01)
    if result.get("action"):
        yield f"data: {json.dumps({'type': 'action', 'proposal': result['action']})}\n\n"
    yield f"data: {json.dumps({'type': 'stats', 'elapsed_sec': result.get('elapsed_sec', 0)})}\n\n"

async def _process_background_memory(message: str, answer: str, user: str):
    try:
        from kora.core.learning import LearningEngine
        learning_engine = LearningEngine()
        await learning_engine.learn_from_turn(message, answer, user)
    except Exception as e:
        logger.error("Background learning execution failed: %s", e)

    try:
        from kora.memory import MemoryClassifier, MemoryQueue
        from kora.llm.ollama import OllamaAdapter

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
    state_file = Path.home() / ".local/state/kryonix/kora/pending_action.json"
    if not state_file.exists():
        return {"status": "error", "message": "Nenhuma ação pendente."}

    try:
        with open(state_file, "r") as f:
            data = json.load(f)
        command = data.get("command")

        if command.startswith("n8n:"):
            path = command.split(":", 1)[1]
            return {"status": "success", "message": f"Workflow n8n disparado: {path}"}

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

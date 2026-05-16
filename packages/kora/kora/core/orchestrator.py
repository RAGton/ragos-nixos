# =============================================================================
# Kora — Core Orchestrator
#
# O orquestrador central da Kora. Recebe uma mensagem, decide a estratégia,
# monta o contexto, chama o LLM e retorna a resposta.
#
# Modos de operação (Fase 1):
#   - direct: envia direto ao Ollama com system prompt
#   - rag:    busca contexto no Brain API e injeta no prompt
#   - auto:   tenta RAG primeiro, fallback para direct
#
# A Kora é o gateway. O Brain é o backend de conhecimento.
# O Ollama é o runtime de inferência.
# =============================================================================

from __future__ import annotations

import logging
import time
from typing import Any

import json
import re

from ..audit.events import log_event
from ..core.config import load_system_prompt
from ..integrations import brain as brain_adapter
from ..integrations.n8n import N8nClient
from ..llm import ollama as ollama_adapter

logger = logging.getLogger("kora.core.orchestrator")

# Regex to find JSON blocks in the LLM response
JSON_BLOCK_RE = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL)


async def process_message(
    message: str,
    session_id: str = "default",
    mode: str = "auto",
) -> dict[str, Any]:
    """
    Process an incoming message through the Kora pipeline.

    Args:
        message: User message text.
        session_id: Session identifier (stateless in Phase 1).
        mode: Processing mode — "direct", "rag", or "auto".

    Returns:
        Response dict with answer, grounding, risk, and metadata.
    """
    t0 = time.monotonic()
    system_prompt = load_system_prompt()

    # ── Context retrieval ────────────────────────────────────────
    context_text = ""
    grounding: dict[str, Any] = {"level": "none", "sources": []}
    brain_used = False

    if mode in ("rag", "auto"):
        brain_result = await brain_adapter.search(query=message)
        if brain_result.get("status") != "error" and brain_result.get("answer"):
            context_text = brain_result["answer"]
            grounding = {
                "level": brain_result.get("grounding", {}).get("grounding_label", "medium"),
                "sources": brain_result.get("sources", []),
                "retrieval_score": brain_result.get("retrieval_score"),
                "mode": brain_result.get("mode"),
            }
            brain_used = True
            logger.info("Brain context retrieved (mode=%s)", mode)
        elif mode == "rag":
            # RAG mode but Brain offline — report degradation
            logger.warning("Brain unavailable in RAG mode, answering without context")

    # ── Build messages ───────────────────────────────────────────
    messages: list[dict[str, str]] = [
        {"role": "system", "content": system_prompt},
    ]

    if context_text:
        context_block = (
            "## Contexto recuperado do Kryonix Brain\n\n"
            f"{context_text}\n\n"
            "---\n\n"
            "Use o contexto acima para fundamentar sua resposta. "
            "Se o contexto for insuficiente, diga claramente."
        )
        messages.append({"role": "system", "content": context_block})

    messages.append({"role": "user", "content": message})

    # ── LLM call ─────────────────────────────────────────────────
    llm_result = await ollama_adapter.chat(messages=messages)
    answer = llm_result.get("answer", "")
    
    # ── Tool execution (n8n) ─────────────────────────────────────
    tool_executed = False
    tool_status = None
    
    # Check for tool calls in the answer
    json_match = JSON_BLOCK_RE.search(answer)
    if json_match:
        try:
            tool_call = json.loads(json_match.group(1))
            if tool_call.get("tool") == "n8n":
                logger.info("n8n tool call detected: %s", tool_call.get("path"))
                client = N8nClient()
                
                # Append session info to payload
                payload = tool_call.get("payload", {})
                payload["_kora_session"] = session_id
                
                tool_res = await client.trigger_webhook(
                    path=tool_call.get("path", "webhook/kora-task"),
                    payload=payload
                )
                tool_executed = True
                tool_status = tool_res.get("status", "success")
                logger.info("n8n tool executed. Status: %s", tool_status)
                
                # Strip the JSON block from the final answer displayed to the user
                # answer = answer.replace(json_match.group(0), "").strip()
        except Exception as e:
            logger.error("Failed to parse or execute tool call: %s", e)
            tool_status = f"error: {str(e)}"

    elapsed = round(time.monotonic() - t0, 3)

    # ── Audit ────────────────────────────────────────────────────
    log_event(
        event_type="chat",
        description=f"Chat processed (mode={mode}, brain={brain_used}, tool={tool_executed})",
        metadata={
            "session_id": session_id,
            "mode": mode,
            "brain_used": brain_used,
            "tool_executed": tool_executed,
            "tool_status": tool_status,
            "model": llm_result.get("model"),
            "elapsed_sec": elapsed,
            "has_error": "error" in llm_result,
        },
        risk="read_only" if not tool_executed else "medium_risk",
    )

    return {
        "answer": answer,
        "mode": mode,
        "grounding": grounding,
        "risk": "read_only" if not tool_executed else "medium_risk",
        "tool_executed": tool_executed,
        "tool_status": tool_status,
        "provider_used": llm_result.get("provider", "ollama"),
        "model": llm_result.get("model"),
        "brain_used": brain_used,
        "elapsed_sec": elapsed,
        "error": llm_result.get("error"),
    }


def _log_audit(metadata: dict[str, Any]) -> None:
    """
    Legacy compatibility wrapper for log_event.
    Used by streaming routes until fully migrated.
    """
    log_event(
        event_type="audit",
        description="Kora Legacy Audit",
        metadata=metadata,
        risk="read_only",
    )

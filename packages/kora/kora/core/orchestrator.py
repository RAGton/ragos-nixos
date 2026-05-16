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

from ..audit.events import log_event
from ..core.config import load_system_prompt
from ..integrations import brain as brain_adapter
from ..llm import ollama as ollama_adapter

logger = logging.getLogger("kora.core.orchestrator")


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

    elapsed = round(time.monotonic() - t0, 3)

    # ── Audit ────────────────────────────────────────────────────
    log_event(
        event_type="chat",
        description=f"Chat processed (mode={mode}, brain={brain_used})",
        metadata={
            "session_id": session_id,
            "mode": mode,
            "brain_used": brain_used,
            "model": llm_result.get("model"),
            "elapsed_sec": elapsed,
            "has_error": "error" in llm_result,
        },
        risk="read_only",
    )

    return {
        "answer": llm_result.get("answer", ""),
        "mode": mode,
        "grounding": grounding,
        "risk": "read_only",
        "memory_written": False,
        "provider_used": llm_result.get("provider", "ollama"),
        "model": llm_result.get("model"),
        "brain_used": brain_used,
        "elapsed_sec": elapsed,
        "error": llm_result.get("error"),
    }

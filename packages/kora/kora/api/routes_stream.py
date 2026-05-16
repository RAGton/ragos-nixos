# =============================================================================
# Kora — Streaming API Routes
#
# Rotas para streaming de resposta (SSE).
# Status na Fase 2: PARTIAL (fundação implementada).
# =============================================================================

from __future__ import annotations

import json
import logging

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from ..audit.events import log_event
from ..llm import ollama as ollama_adapter

logger = logging.getLogger("kora.api.routes_stream")

router = APIRouter()


class StreamRequest(BaseModel):
    """Chat stream request."""
    message: str = Field(..., description="User message")
    session_id: str = Field(default="default", description="Session identifier")
    mode: str = Field(
        default="direct",
        description="Processing mode. Stream currently only supports direct mode.",
    )


@router.post("/chat/stream")
async def chat_stream(req: StreamRequest) -> StreamingResponse:
    """
    Server-Sent Events endpoint for chat streaming.
    Phase 2: Currently only supports direct mode.
    """
    # Para Fase 2, o stream funciona de forma rudimentar apenas no modo direto
    # e sem interceptar chamadas ao Brain.

    async def stream_generator():
        # TODO Phase 3: Integrate with full orchestrator and Brain context.
        # This is a direct pass-through for now.
        logger.info(f"Stream requested for session {req.session_id}")

        full_text = ""
        try:
            async for chunk in ollama_adapter.generate_stream(
                prompt=req.message,
                system_prompt="Você é a Kora. Responda diretamente e de forma concisa.",
                context=None,
            ):
                full_text += chunk
                # SSE format: data: {"chunk": "..."}
                yield f"data: {json.dumps({'chunk': chunk})}\n\n"

            # Send end event
            yield f"data: {json.dumps({'done': True})}\n\n"

            # Audit log (post-generation)
            log_event(
                event_type="chat_stream",
                description="Stream generation completed",
                metadata={
                    "endpoint": "/chat/stream",
                    "session_id": req.session_id,
                    "mode": req.mode,
                    "answer_length": len(full_text),
                    "provider": "ollama",
                },
                risk="read_only",
            )

        except Exception as e:
            logger.error(f"Stream error: {e}")
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return StreamingResponse(
        stream_generator(),
        media_type="text/event-stream"
    )

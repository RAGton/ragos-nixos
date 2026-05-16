# =============================================================================
# Kora — Chat API Routes
#
# Rotas de chat e conversação da Kora.
# Contrato público da assistente: /chat, /ask, /memory/search
#
# Estas rotas são o contrato da Kora, não proxy do Brain.
# =============================================================================

from __future__ import annotations

import logging
from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..core.orchestrator import process_message
from ..integrations import brain as brain_adapter

logger = logging.getLogger("kora.api.routes_chat")

router = APIRouter()


# ── Models ───────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    """Chat request to the Kora assistant."""
    message: str = Field(..., description="User message")
    session_id: str = Field(default="default", description="Session identifier")
    mode: str = Field(
        default="auto",
        description="Processing mode: direct (LLM only), rag (with Brain context), auto (try RAG then direct)",
    )


class ChatResponse(BaseModel):
    """Chat response from the Kora assistant."""
    answer: str
    mode: str
    grounding: dict = {}
    risk: str = "read_only"
    memory_written: bool = False
    provider_used: str | None = None
    model: str | None = None
    brain_used: bool = False
    elapsed_sec: float | None = None
    error: str | None = None


class AskRequest(BaseModel):
    """Quick question request — alias for /chat with mode=auto."""
    question: str = Field(..., description="Question to ask Kora")


class MemorySearchRequest(BaseModel):
    """Search the Kora/Brain memory for relevant information."""
    query: str = Field(..., description="Search query")
    mode: str = Field(default="hybrid", description="Search mode: hybrid, naive, local, global")


# ── Routes ───────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest) -> ChatResponse:
    """
    Main chat endpoint. Sends message through the Kora orchestrator.

    The Kora processes the message, optionally retrieves context from the
    Brain knowledge base, generates a response via Ollama, and returns
    the result with grounding and risk information.
    """
    result = await process_message(
        message=req.message,
        session_id=req.session_id,
        mode=req.mode,
    )
    return ChatResponse(**result)


@router.post("/ask", response_model=ChatResponse)
async def ask(req: AskRequest) -> ChatResponse:
    """
    Quick question endpoint — convenience alias for /chat with mode=auto.
    Designed for CLI usage: `kora ask "resumo do estado do Glacier"`.
    """
    result = await process_message(
        message=req.question,
        session_id="quick",
        mode="auto",
    )
    return ChatResponse(**result)


@router.post("/memory/search")
async def memory_search(req: MemorySearchRequest) -> dict[str, Any]:
    """
    Search the knowledge base via the Brain API.

    This is the Kora-mediated interface to Brain search.
    In future phases, this will also search session memory, Neo4j graph,
    and Obsidian notes.
    """
    result = await brain_adapter.search(
        query=req.query,
        mode=req.mode,
    )
    return {
        "source": "brain",
        "query": req.query,
        "mode": req.mode,
        "result": result,
    }

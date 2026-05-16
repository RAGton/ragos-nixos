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
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from ..core.orchestrator import process_message, confirm_pending_action, process_message_stream
from ..integrations import brain as brain_adapter
from ..memory import MemorySearch, MemoryQueue, MemoryWorker

logger = logging.getLogger("kora.api.routes_chat")

router = APIRouter()


# ── Models ───────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    """Chat request to the Kora assistant."""
    message: str = Field(..., description="User message")
    session_id: str = Field(default="default", description="Session identifier")
    user: str = Field(default="unknown", description="System user name (e.g. rocha)")
    speaker: str | None = Field(default=None, description="Recognized speaker name for voice")
    is_voice: bool = Field(default=False, description="Whether the input came from voice")
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
        user=req.user,
        speaker=req.speaker,
        is_voice=req.is_voice,
        mode=req.mode,
    )
    return ChatResponse(**result)


@router.post("/chat/stream")
async def chat_stream(req: ChatRequest):
    """
    Streaming version of the main chat endpoint.
    Uses Server-Sent Events (SSE) to deliver response chunks.
    """
    return StreamingResponse(
        process_message_stream(
            message=req.message,
            session_id=req.session_id,
            user=req.user,
            speaker=req.speaker,
            is_voice=req.is_voice,
            mode=req.mode,
        ),
        media_type="text/event-stream"
    )


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


@router.post("/brain/search")
async def brain_search(req: MemorySearchRequest) -> dict[str, Any]:
    """
    Search the knowledge base via the Brain API.

    This is the Kora-mediated interface to Brain search.
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


@router.post("/confirm")
async def confirm(session_id: str = "default") -> dict[str, Any]:
    """
    Confirm and execute the last pending action proposed by Kora.
    """
    result = await confirm_pending_action(session_id=session_id)
    return result


# ── Memory Endpoints ──────────────────────────────────────────

@router.get("/memory/status")
async def get_memory_status():
    """Get memory queue and vault status."""
    queue = MemoryQueue()
    search = MemorySearch()
    return {
        "queue": queue.get_status(),
        "vault": {
            "path": str(search.vault_dir),
            "exists": search.vault_dir.exists()
        }
    }


@router.post("/memory/search")
async def search_memory(query: str, limit: int = 5):
    """Search for memories in the vault."""
    search = MemorySearch()
    results = search.search(query, limit=limit)
    return {"results": results}


@router.get("/memory/recent")
async def get_recent_memory(limit: int = 10):
    """Get recent memories from the vault."""
    search = MemorySearch()
    results = search.get_recent(limit=limit)
    return {"results": results}


@router.post("/memory/flush")
async def flush_memory():
    """Manually trigger the memory worker to process the queue."""
    worker = MemoryWorker()
    count = worker.run_once()
    return {"status": "success", "processed_items": count}


# ── Indexing Endpoints ────────────────────────────────────────

@router.get("/memory/index/status")
async def get_index_status():
    """Get indexing manifest status."""
    indexer = MemoryIndexer()
    return indexer.get_status()


@router.get("/memory/index/pending")
async def get_index_pending():
    """Get list of pending files to index."""
    indexer = MemoryIndexer()
    return {"pending": indexer.get_pending()}


@router.post("/memory/index")
async def run_index():
    """Manually trigger incremental indexing."""
    indexer = MemoryIndexer()
    count = await indexer.index_all()
    return {"status": "success", "indexed_items": count}

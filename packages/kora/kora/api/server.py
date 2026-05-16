# =============================================================================
# Kora — FastAPI Server
#
# Ponto de entrada da API da Kora.
# Gateway/orchestrator — contrato público da assistente pessoal.
#
# Endpoints:
#   GET  /health        → status de todas as dependências (público)
#   GET  /status        → metadata do serviço (público)
#   GET  /capabilities  → lista de capacidades da Kora
#   POST /chat          → chat com a assistente (autenticado)
#   POST /ask           → pergunta rápida (autenticado)
#   POST /memory/search → busca na memória/knowledge (autenticado)
#
# Segurança:
#   - /health e /status são públicos (para monitoring)
#   - demais endpoints exigem KORA_API_KEY via header X-API-Key
#   - KRYONIX_BRAIN_API_KEY é usada internamente, nunca exposta
# =============================================================================

from __future__ import annotations

import logging
import os
import time

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.security.api_key import APIKeyHeader

from .. import __version__
from ..core.config import (
    BRAIN_URL,
    KORA_API_KEY,
    KORA_HOST,
    KORA_PORT,
    NEO4J_URI,
    OLLAMA_URL,
    ensure_dirs,
)
from ..integrations import brain as brain_adapter
from ..llm import ollama as ollama_adapter
from .routes_chat import router as chat_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("kora.api.server")

# ── Auth ─────────────────────────────────────────────────────────

API_KEY_NAME = "X-API-Key"
api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)

_start_time = time.monotonic()


async def verify_api_key(api_key: str | None = Depends(api_key_header)) -> str:
    """Verify KORA_API_KEY for protected endpoints."""
    expected = KORA_API_KEY
    if not expected:
        # No key configured — allow access (dev mode / initial setup)
        return "no-key-configured"
    if not api_key:
        raise HTTPException(status_code=401, detail="API Key não fornecida")
    if api_key != expected:
        raise HTTPException(status_code=403, detail="API Key inválida")
    return api_key


# ── App ──────────────────────────────────────────────────────────

app = FastAPI(
    title="Kora — Kryonix Personal Assistant",
    version=__version__,
    description="Gateway/orchestrator da assistente pessoal local Kryonix.",
)

# Protected chat routes
app.include_router(
    chat_router,
    dependencies=[Depends(verify_api_key)],
)


# ── Public Endpoints ─────────────────────────────────────────────

@app.get("/health")
async def health():
    """
    Health check for all dependencies.
    Public endpoint — no API key required.
    Returns status of Kora, Ollama, Brain, and Neo4j.
    """
    ollama_status = await ollama_adapter.health()
    brain_status = await brain_adapter.health()

    # Neo4j health via Brain API (since Brain connects to Neo4j)
    # In future phases, Kora will have direct Neo4j connection
    neo4j_status = {"status": "unknown", "uri": NEO4J_URI, "note": "checked via Brain in Phase 1"}

    # Overall status: ok if all deps ok, warn if any warn, fail if critical fail
    statuses = [ollama_status["status"], brain_status["status"]]
    if "fail" in statuses:
        overall = "warn"  # Kora itself is up, deps are degraded
    elif "warn" in statuses:
        overall = "warn"
    else:
        overall = "ok"

    return {
        "service": "kora",
        "version": __version__,
        "status": overall,
        "dependencies": {
            "ollama": ollama_status,
            "brain": brain_status,
            "neo4j": neo4j_status,
        },
    }


@app.get("/status")
async def status():
    """
    Service metadata and runtime info.
    Public endpoint — no API key required.
    """
    uptime = round(time.monotonic() - _start_time, 1)
    return {
        "service": "kora",
        "version": __version__,
        "uptime_seconds": uptime,
        "host": KORA_HOST,
        "port": KORA_PORT,
        "ollama_url": OLLAMA_URL,
        "brain_url": BRAIN_URL,
        "neo4j_uri": NEO4J_URI,
        "auth_configured": bool(KORA_API_KEY),
    }


@app.get("/capabilities")
async def capabilities():
    """
    List current and planned capabilities of Kora.
    Public endpoint for client discovery.
    """
    return {
        "service": "kora",
        "version": __version__,
        "capabilities": {
            "active": [
                {"name": "chat", "endpoint": "POST /chat", "description": "Conversação com a assistente"},
                {"name": "ask", "endpoint": "POST /ask", "description": "Pergunta rápida"},
                {"name": "memory_search", "endpoint": "POST /memory/search", "description": "Busca no conhecimento"},
                {"name": "health", "endpoint": "GET /health", "description": "Status das dependências"},
                {"name": "status", "endpoint": "GET /status", "description": "Metadata do serviço"},
            ],
            "planned": [
                {"name": "routines", "phase": 3, "description": "Criação e gestão de rotinas"},
                {"name": "voice", "phase": 4, "description": "Wake-word, STT, TTS"},
                {"name": "home_assistant", "phase": 5, "description": "Automação residencial"},
                {"name": "vision", "phase": 6, "description": "Visão computacional sob demanda"},
                {"name": "web_ui", "phase": 7, "description": "Interface web"},
                {"name": "desktop", "phase": 7, "description": "App desktop Tauri"},
                {"name": "mobile", "phase": 7, "description": "PWA / app mobile"},
            ],
        },
    }


# ── Startup ──────────────────────────────────────────────────────

@app.on_event("startup")
async def on_startup():
    """Initialize runtime directories and log startup info."""
    ensure_dirs()
    logger.info(
        "Kora v%s starting on %s:%s (auth=%s)",
        __version__,
        KORA_HOST,
        KORA_PORT,
        "configured" if KORA_API_KEY else "disabled",
    )


# ── Entry point ──────────────────────────────────────────────────

def main():
    """Run the Kora API server."""
    import uvicorn

    host = KORA_HOST
    port = KORA_PORT
    logger.info("Starting Kora API on %s:%s", host, port)
    uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    main()

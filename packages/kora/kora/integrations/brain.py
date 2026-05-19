# =============================================================================
# Kora — Brain API Adapter
#
# Adapter interno para o Kryonix Brain (backend de conhecimento/RAG/CAG/GraphRAG).
# A Kora consome o Brain como backend, não como identidade.
#
# Usa KRYONIX_BRAIN_API_KEY internamente.
# Nunca expõe esta chave aos clientes da Kora.
# =============================================================================

from __future__ import annotations

import logging
from typing import Any

import httpx

from ..core.config import BRAIN_API_KEY, BRAIN_TIMEOUT, BRAIN_URL

logger = logging.getLogger("kora.integrations.brain")


def _headers() -> dict[str, str]:
    """Build auth headers for Brain API. Key is internal-only."""
    h: dict[str, str] = {}
    if BRAIN_API_KEY:
        h["X-API-Key"] = BRAIN_API_KEY
    return h


async def health() -> dict[str, Any]:
    """Check Brain API availability. Returns status dict, never raises."""
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(f"{BRAIN_URL}/health")
            if resp.status_code == 200:
                data = resp.json()
                return {
                    "status": "ok",
                    "url": BRAIN_URL,
                    "storage": data.get("storage", "unknown"),
                }
            return {
                "status": "warn",
                "url": BRAIN_URL,
                "error": f"HTTP {resp.status_code}",
            }
    except httpx.ConnectError:
        return {"status": "fail", "url": BRAIN_URL, "error": "connection refused"}
    except httpx.TimeoutException:
        return {"status": "fail", "url": BRAIN_URL, "error": "timeout"}
    except Exception as e:
        return {"status": "fail", "url": BRAIN_URL, "error": str(e)}


async def search(
    query: str,
    mode: str = "hybrid",
    intent: str = "ask",
    lang: str = "pt-BR",
) -> dict[str, Any]:
    """
    Search the Brain knowledge base via RAG/GraphRAG.

    Tries GraphTraversal (hybrid/global mode) first, falling back to VectorSearch (naive) if score is low.
    """
    # 1. Tentar GraphTraversal (modo híbrido/grafo por padrão)
    graph_mode = mode if mode in ["hybrid", "global", "local"] else "hybrid"
    payload = {
        "query": query,
        "mode": graph_mode,
        "intent": intent,
        "lang": lang,
    }

    try:
        async with httpx.AsyncClient(timeout=BRAIN_TIMEOUT) as client:
            logger.info("Tentando GraphTraversal (mode=%s)...", graph_mode)
            resp = await client.post(
                f"{BRAIN_URL}/search",
                json=payload,
                headers=_headers(),
            )
            resp.raise_for_status()
            res = resp.json()

            # Verificar se a pontuação é baixa (retrieval_score < 0.5)
            retrieval_score = res.get("retrieval_score") or res.get("grounding", {}).get("retrieval_score", 0.0)
            grounding_label = res.get("grounding", {}).get("grounding_label", "")

            if retrieval_score < 0.5 or grounding_label == "Baixa" or res.get("status") == "no_grounding":
                logger.info(
                    "GraphTraversal pontuação baixa (score=%.3f, label=%s). Seguindo para VectorSearch (naive)...",
                    retrieval_score,
                    grounding_label,
                )
                # 2. Seguir para VectorSearch (naive mode)
                payload["mode"] = "naive"
                try:
                    resp_fallback = await client.post(
                        f"{BRAIN_URL}/search",
                        json=payload,
                        headers=_headers(),
                    )
                    if resp_fallback.status_code == 200:
                        fallback_res = resp_fallback.json()
                        fallback_score = fallback_res.get("retrieval_score") or fallback_res.get("grounding", {}).get("retrieval_score", 0.0)
                        if fallback_score > retrieval_score:
                            logger.info("VectorSearch (naive) retornou pontuação melhor (score=%.3f). Usando fallback.", fallback_score)
                            return fallback_res
                except Exception as fe:
                    logger.warning("Erro ao tentar fallback de VectorSearch: %s", fe)

            return res
    except httpx.ConnectError:
        logger.warning("Brain API offline — search unavailable")
        return {
            "status": "error",
            "answer": "",
            "error": "brain_offline",
            "message": "Brain API não está acessível.",
        }
    except httpx.TimeoutException:
        logger.warning("Brain API timeout on search")
        return {
            "status": "error",
            "answer": "",
            "error": "brain_timeout",
            "message": "Brain API não respondeu a tempo.",
        }
    except Exception as e:
        logger.error("Brain search error: %s", e)
        return {
            "status": "error",
            "answer": "",
            "error": str(e),
        }


async def stats() -> dict[str, Any]:
    """Get Brain knowledge stats."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                f"{BRAIN_URL}/stats",
                headers=_headers(),
            )
            resp.raise_for_status()
            return resp.json()
    except Exception as e:
        logger.warning("Brain stats unavailable: %s", e)
        return {"status": "error", "error": str(e)}


async def propose_ingest(content: str, source: str, reason: str = "") -> dict[str, Any]:
    """Propose content for ingestion into the Brain."""
    payload = {
        "content": content,
        "source": source,
        "reason": reason
    }
    try:
        async with httpx.AsyncClient(timeout=BRAIN_TIMEOUT) as client:
            resp = await client.post(
                f"{BRAIN_URL}/ingest/propose",
                json=payload,
                headers=_headers(),
            )
            resp.raise_for_status()
            return resp.json()
    except Exception as e:
        logger.error("Brain propose_ingest error: %s", e)
        return {"status": "error", "error": str(e)}

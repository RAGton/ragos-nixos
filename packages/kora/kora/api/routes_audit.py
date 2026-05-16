import time
import asyncio
import logging
from typing import Dict, Any, List
from fastapi import APIRouter, HTTPException, Depends
from ..core.orchestrator import process_message
from ..core.benchmark import KoraBenchmark, DEFAULT_QUERIES

logger = logging.getLogger("kora.api.routes_audit")
router = APIRouter(prefix="/audit", tags=["Audit"])

@router.get("/benchmark")
async def run_benchmark(iterations: int = 1, user: str = "rocha"):
    """
    Executa uma bateria de testes de performance (Benchmark).
    """
    bench = KoraBenchmark()
    # Executa de forma assíncrona mas retorna o resultado final
    await bench.run_suite(DEFAULT_QUERIES, iterations=iterations, user=user)
    return {
        "status": "success",
        "iterations": iterations,
        "results": bench.results
    }

@router.get("/grounding")
async def audit_grounding():
    """
    Auditoria de Grounding e Anti-Alucinação.
    Verifica se a Kora recusa comandos falsos.
    """
    test_queries = [
        "rode kryonix create-memory", # Comando falso
        "qual o status do kryonix",   # Comando real
    ]

    audit_results = []
    for q in test_queries:
        resp = await process_message(q, user="rocha", mode="auto")
        audit_results.append({
            "query": q,
            "answer": resp.get("answer"),
            "action": resp.get("action"),
            "model": resp.get("model")
        })

    return audit_results

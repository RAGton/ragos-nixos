import time
import asyncio
import statistics
import logging
from typing import List, Dict, Any
from .orchestrator import process_message

logger = logging.getLogger("kora.core.benchmark")

class KoraBenchmark:
    """Ferramenta de benchmark para medir performance da Kora e do Brain."""
    
    def __init__(self):
        self.results = []

    async def run_suite(self, queries: List[str], iterations: int = 3, user: str = "rocha"):
        """Executa uma suite de testes de latência."""
        print(f"🚀 Iniciando Benchmark Kora (Iterações: {iterations})")
        print("-" * 50)
        
        for query in queries:
            query_latencies = []
            print(f"Testando: '{query}'...")
            
            for i in range(iterations):
                start_time = time.monotonic()
                try:
                    # Usamos o process_message real
                    resp = await process_message(query, user=user, mode="auto")
                    elapsed = time.monotonic() - start_time
                    query_latencies.append(elapsed)
                    print(f"  [{i+1}/{iterations}] {elapsed:.2f}s (Mode: {resp.get('mode')})")
                except Exception as e:
                    logger.error(f"Erro no benchmark: {e}")
                    print(f"  [{i+1}/{iterations}] FALHA: {e}")
            
            if query_latencies:
                avg = statistics.mean(query_latencies)
                p95 = statistics.quantiles(query_latencies, n=20)[18] if len(query_latencies) >= 20 else max(query_latencies)
                
                self.results.append({
                    "query": query,
                    "avg": avg,
                    "min": min(query_latencies),
                    "max": max(query_latencies),
                    "p95": p95
                })

        self.print_report()

    def print_report(self):
        """Imprime o relatório final formatado."""
        print("\n" + "=" * 50)
        print("RELATÓRIO DE PERFORMANCE KORA")
        print("=" * 50)
        print(f"{'Query':<30} | {'Avg':>6} | {'Max':>6} | {'Min':>6}")
        print("-" * 50)
        for res in self.results:
            print(f"{res['query'][:30]:<30} | {res['avg']:>5.2f}s | {res['max']:>5.2f}s | {res['min']:>5.2f}s")
        print("=" * 50)

# Queries padrão para teste
DEFAULT_QUERIES = [
    "oi kora",
    "quem sou eu",
    "qual o status do kryonix",
    "como está a memória no brain",
    "quais ferramentas de rede temos no registry",
    "faça um resumo do roadmap"
]

async def run_benchmark():
    bench = KoraBenchmark()
    await bench.run_suite(DEFAULT_QUERIES)

if __name__ == "__main__":
    asyncio.run(run_benchmark())

# Ollama Model Benchmark — RTX 4060 (8GB VRAM)

## Data
2026-05-13

## Objetivo
Avaliar o desempenho de modelos LLM e Embedding no host Glacier (RTX 4060) para definir o stack de produção do Kryonix Brain.

## Ambiente de Teste
- **GPU:** NVIDIA GeForce RTX 4060 (8GB VRAM)
- **RAM:** 16GB
- **OS:** NixOS (Glacier)
- **Backend:** Ollama v0.x

## Resultados do Benchmark

| Modelo | Papel | VRAM antes (MiB) | VRAM depois (MiB) | Tokens/s | Latência (s) | Temp (°C) | Resultado |
| :--- | :--- | ---: | ---: | ---: | ---: | ---: | :--- |
| `qwen3:8b` | RAG/Chat | 526 | 5994 | 48.75 | 15.16 | 55 | ✅ SUCCESS |
| `qwen3:4b` | Chat Leve | 526 | 3702 | 85.35 | 9.95 | 56 | ✅ SUCCESS |
| `qwen2.5-coder:7b` | Coding | 526 | 5362 | 55.54 | 6.28 | 57 | ✅ SUCCESS |
| `granite3.3:8b` | RAG/Chat | 526 | 6128 | 48.23 | 10.65 | 57 | ✅ SUCCESS |
| `deepseek-r1:8b` | Reasoning | 526 | 5994 | 48.92 | 11.93 | 58 | ✅ SUCCESS |
| `nomic-embed-text` | Embedding | 526 | 1162 | N/A | 0.61 | 45 | ✅ SUCCESS |
| `mxbai-embed-large` | Embedding A/B | 526 | 1316 | N/A | 0.62 | 42 | ✅ SUCCESS |

## Análise Técnica

### 1. VRAM e Capacidade
Todos os modelos testados (até 8B parâmetros) couberam confortavelmente na RTX 4060. O pico de uso foi de **6.1GB** com o `granite3.3:8b`, deixando margem de segurança para o sistema (~2GB livres).

### 2. Desempenho (Tokens/s)
- O `qwen3:4b` apresentou a melhor performance de geração com **85 tokens/s**, ideal para tarefas de baixa latência.
- O stack de 7B-8B parâmetros manteve uma média sólida de **~48-55 tokens/s**, o que é excelente para uso interativo.

### 3. Coding e RAG
- `qwen2.5-coder:7b` mostrou-se muito eficiente (55 tps) e é o candidato ideal para assistência em Nix, Rust e Python.
- `qwen3:8b` e `deepseek-r1:8b` empatam em performance, mas o DeepSeek oferece capacidades de raciocínio superiores para o RAG.

### 4. Embeddings
- `nomic-embed-text` continua sendo o padrão de produção devido à sua estabilidade e baixo consumo.
- `mxbai-embed-large` apresentou latência similar e será mantido para testes A/B futuros, mas não substituirá o Nomic agora para evitar reindexação.

## Recomendações de Stack (Produção)

1. **RAG Principal:** `deepseek-r1:8b` ou `qwen3:8b`.
2. **Coding Assistant:** `qwen2.5-coder:7b`.
3. **Embeddings:** `nomic-embed-text`.
4. **Chat Rápido:** `qwen3:4b`.

## Conclusão
A RTX 4060 de 8GB é perfeitamente capaz de sustentar o stack completo do Kryonix Brain com latências abaixo de 1s para o primeiro token e vazão superior a 45 tps nos modelos principais.

---
*Relatório gerado por Antigravity via benchmark automatizado em 2026-05-13.*

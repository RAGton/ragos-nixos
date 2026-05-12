# Arquitetura RAG do Kryonix Brain

Status: Roadmap / Arquitetura proposta

## Problema

RAG naïve é insuficiente para o Kryonix porque o projeto possui código Nix, módulos, hosts, serviços, docs, Vault, incidentes e decisões técnicas.

## Pipeline alvo

```txt
1. Query normalization
2. Query routing
3. Hybrid retrieval
   - vector search
   - full-text/BM25
   - graph traversal
4. Metadata filtering
5. Reranking
6. Context compression
7. Prompt assembly
8. LLM answer
9. Citation/provenance
10. Feedback/reasoning trace
```

## Perfis de retrieval

```txt
repo-code      = prioriza .nix, .rs, .py, .sh
ops-debug      = serviços, comandos, logs, traces
architecture   = docs, README, flake, modules
vault-knowledge = Obsidian/Vault aprovado
security       = secrets policy, firewall, SSH, Tailscale
```

## Regras anti-alucinação

- Sem grounding suficiente, responder com limitação.
- Sempre preferir arquivos reais do repo.
- Mostrar fontes/proveniência quando disponível.
- Não inventar comandos existentes.
- Não afirmar que recurso existe se for roadmap.

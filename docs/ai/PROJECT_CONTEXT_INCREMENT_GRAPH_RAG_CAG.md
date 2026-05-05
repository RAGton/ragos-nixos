# Kryonix Brain — Contexto Incremental para IA

Status: Contexto canônico incremental

## Decisão central

Continuar usando Obsidian/Vault como fonte humana. Usar Neo4j local no Glacier apenas como grafo derivado, reconstruível e consultável por IA.

## Direção técnica

```txt
Obsidian/Vault -> documentos humanos
Repo Kryonix    -> verdade operacional
LightRAG        -> recuperação textual/semântica
Neo4j           -> entidades/relações/traces
GraphRAG        -> vetor + grafo + Cypher
CAG             -> cache de contexto estável
Ollama          -> LLM local
NixOS           -> serviços declarativos
```

## Prioridades

1. Organizar `/var/lib/kryonix`.
2. Documentar Obsidian vs Neo4j para evitar duplicidade.
3. Endurecer RAG/CAG/GraphRAG.
4. Criar ingestão incremental do repo inteiro.
5. Incluir `.nix` com chunking estrutural.
6. Preparar Neo4j local com segurança.
7. Mover documentação solta para `docs/` sem quebrar referências.
8. Registrar reasoning traces para auditoria.

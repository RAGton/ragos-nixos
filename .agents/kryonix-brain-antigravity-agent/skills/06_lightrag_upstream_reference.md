# Skill 06 — Referência HKUDS/LightRAG

Use o repo oficial como referência de arquitetura, não copie cegamente.

## Ideias a absorver

- reranker opcional;
- modo `mix` quando reranker estiver disponível;
- delete document com regeneração do KG;
- retorno de contexts/sources;
- avaliação estilo RAGAS;
- tracing estilo Langfuse;
- suporte futuro a multimodal via RAG-Anything;
- separação clara dos quatro storages:
  - KV;
  - Vector;
  - Graph;
  - Doc status.

## Adaptação para Kryonix

- Local-first.
- Ollama.
- RTX 4060 8GB.
- NixOS declarativo.
- MCP remoto.
- Vault Obsidian.
- CAG para contexto canônico.
- API segura por padrão.

## Não fazer agora

- Não migrar para OpenSearch/Postgres/Neo4j sem necessidade.
- Não ativar multimodal pesado sem benchmark.
- Não exigir modelo 30B/32B local na RTX 4060.
- Não quebrar storage existente.

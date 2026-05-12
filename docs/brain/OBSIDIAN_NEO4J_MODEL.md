# Obsidian e Neo4j no Kryonix Brain

Status: Roadmap / Arquitetura canônica proposta

## Resumo

Obsidian e Neo4j não têm o mesmo papel.

```txt
Obsidian/Vault = fonte humana de verdade
Repo Kryonix    = fonte operacional/declarativa
Neo4j           = grafo derivado/reconstruível para IA
LightRAG        = recuperação textual/semântica
CAG/cache       = contexto estável pré-computado
```

O Neo4j não deve virar um segundo vault manual. Ele deve ser alimentado por ingestão automática, com proveniência, a partir do repo, docs e Vault aprovado.

## Por que não é duplicidade ruim?

No Obsidian você escreve:

```md
# Ollama no Glacier
O Ollama roda no host Glacier e escuta na porta 11434.
O Kryonix Brain depende dele.
```

No Neo4j isso vira grafo derivado:

```txt
(:Host {name:"glacier"})-[:RUNS]->(:Service {name:"ollama"})
(:Service {name:"ollama"})-[:LISTENS_ON]->(:Port {number:11434})
(:Service {name:"kryonix-brain"})-[:DEPENDS_ON]->(:Service {name:"ollama"})
```

O Markdown continua sendo a fonte humana. O grafo serve para consultas multi-hop, relações e raciocínio.

## Regras

- Não editar conhecimento primário diretamente no Neo4j.
- Neo4j deve ser reconstruível.
- Todo nó derivado precisa de `source_path` e `source_hash`.
- Se Neo4j divergir do repo/Vault, reindexar.
- Text2Cypher deve ser read-only por padrão.

## Proveniência mínima

```txt
Document.source_path
Document.source_type
Document.sha256
Document.repo_commit
Document.indexed_at
Chunk.index
Chunk.text_hash
Chunk.embedding_model
Entity.name
Entity.type
Entity.confidence
Relationship.extractor
```

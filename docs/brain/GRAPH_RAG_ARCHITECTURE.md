# GraphRAG do Kryonix Brain

Status: Parcial

## Objetivo

Combinar busca vetorial com grafo para responder perguntas sobre relações, dependências, causalidade e histórico do Kryonix.

## Modelo inicial

```txt
(Document)-[:HAS_CHUNK]->(Chunk)
(Chunk)-[:MENTIONS]->(Entity)
(File)-[:IMPORTS]->(File)
(File)-[:DECLARES]->(Service)
(File)-[:DEFINES_OPTION]->(NixOption)
(Host)-[:IMPORTS]->(NixModule)
(Host)-[:RUNS]->(Service)
(Service)-[:LISTENS_ON]->(Port)
(Service)-[:DEPENDS_ON]->(Service)
(Command)-[:VALIDATES]->(Service)
(Issue)-[:AFFECTS]->(Service)
(ReasoningTrace)-[:HAS_STEP]->(ReasoningStep)
(ReasoningStep)-[:USED_TOOL]->(ToolCall)
```

## Exemplo de pergunta

```txt
Por que o Brain não conecta no Ollama?
```

Recuperação esperada:

```txt
Service: kryonix-brain
Service: ollama
Host: glacier
Port: 11434
File: modules/nixos/services/brain.nix
Command: systemctl status ollama
Trace: diagnóstico anterior semelhante
```

## Segurança

Text2Cypher deve usar schema limitado, usuário read-only, LIMIT obrigatório, timeout e bloqueio de escrita.

## Fase 4 (controlada)

Comandos expostos via CLI/API:

```bash
kryonix graph status
kryonix graph schema
kryonix graph ingest --dry-run
kryonix graph ingest --apply <manifest_id>
kryonix graph query "MATCH (s:Service) RETURN s.name LIMIT 5"
kryonix graph doctor
```

Regras ativas:

- `--dry-run` gera manifesto e não escreve no Neo4j.
- `--apply` só aplica manifesto salvo.
- Text2Cypher/consulta bloqueia escrita (`CREATE`, `MERGE`, `DELETE`, `SET`, `REMOVE`, `CALL dbms.*`, `CALL apoc.*`, `LOAD CSV`).
- `LIMIT` obrigatório.
- Timeout padrão aplicado.
- Auditoria de consulta em `graph_audit.jsonl`.

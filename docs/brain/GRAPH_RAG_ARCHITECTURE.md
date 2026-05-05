# GraphRAG do Kryonix Brain

Status: Roadmap / Arquitetura proposta

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

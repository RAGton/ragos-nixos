# Índice de Fontes Sincronizadas

Status: Índice documental
Atualizado em: 2026-05-16

## Objetivo

Registrar quais fontes externas ou materiais de conversa foram consolidados dentro da documentação do Kryonix, qual o uso correto de cada uma e quais limites devem ser respeitados.

Este índice evita que o Brain, agentes ou humanos misturem:

- documentação operacional real;
- material conceitual;
- roadmap;
- prompts para agentes;
- memória de conversa;
- estado runtime validado.

## Regra de precedência

A precedência do projeto permanece:

```txt
código real do repo
  > docs canônicas atuais
  > docs/ai e contexto compacto
  > vault/Obsidian
  > Neo4j/LightRAG como índice derivado
  > memória de conversa
```

Se uma fonte conceitual divergir do código real, o código vence.

## Fontes consolidadas nesta rodada

| Fonte | Arquivo destino | Tipo | Uso correto |
| --- | --- | --- | --- |
| Comandos operacionais de IA | `docs/ai/COMANDOS_OPERACIONAIS_IA.md` | Referência operacional de prompts | Padronizar pedidos para Adpta, Antigravity, Kora e outros agentes. |
| Framework Leda | `docs/ai/AGENT_AUTOMATION_FRAMEWORK_LEDA.md` | Conhecimento conceitual | Inspirar arquitetura de agentes, workflows, bancos e prompts estruturados. |
| Embeddings vs Grafos | `docs/brain/EMBEDDINGS_VS_GRAPH.md` | Referência arquitetural Brain | Explicar por que o Kryonix deve combinar busca vetorial com Neo4j/GraphRAG. |

## Fontes já existentes no repositório relacionadas

| Arquivo | Papel |
| --- | --- |
| `AGENTS.md` | Contrato canônico para agentes humanos e IA. |
| `docs/brain/GRAPH_RAG_ARCHITECTURE.md` | Arquitetura parcial do GraphRAG do Kryonix Brain. |
| `docs/brain/NEO4J_SCHEMA.md` | Ontologia e schema Neo4j do Kryonix Brain. |
| `docs/README.md` | Índice canônico da documentação. |
| `docs/TESTING.md` | Regras de validação e evidência. |
| `docs/SECURITY.md` | Segurança, secrets e exposição de rede. |

## O que cada fonte não deve fazer

### `COMANDOS_OPERACIONAIS_IA.md`

Não implementa comandos no CLI.

Serve para estruturar prompts e orientar agentes.

### `AGENT_AUTOMATION_FRAMEWORK_LEDA.md`

Não declara runtime implementado no Glacier.

Serve como fonte conceitual para agentes, orquestração e automações.

### `EMBEDDINGS_VS_GRAPH.md`

Não substitui `GRAPH_RAG_ARCHITECTURE.md` nem `NEO4J_SCHEMA.md`.

Serve como explicação didática e arquitetural para a decisão de combinar embeddings + grafo.

## Critérios de ingestão no Brain/Vault

Antes de indexar essas fontes no Kryonix Brain:

1. manter caminho de origem;
2. registrar hash/commit;
3. marcar status como fonte conceitual ou operacional;
4. evitar que material conceitual vire claim de implementação;
5. preservar links para arquivos canônicos;
6. validar que o Brain diferencia `roadmap`, `parcial` e `implementado`.

## Próximos candidatos de sincronização

- contrato Ask vs Search;
- síntese comparativa grounded;
- Home Brain content-aware organizer;
- memória portátil Kryonix;
- roadmap atualizado do Glacier e Kora.

Esses itens devem ser sincronizados em PRs pequenos e separados se envolverem comportamento ou claims de implementação.

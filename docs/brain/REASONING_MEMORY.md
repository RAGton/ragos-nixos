# Reasoning Memory do Kryonix Brain

Status: Roadmap / Arquitetura proposta

## Objetivo

Registrar decisões do agente como grafo auditável.

## Modelo

```txt
(Message)-[:TRIGGERED]->(ReasoningTrace)
(ReasoningTrace)-[:HAS_STEP]->(ReasoningStep)
(ReasoningStep)-[:USED_TOOL]->(ToolCall)
(ToolCall)-[:RETURNED]->(ToolResult)
(Decision)-[:BASED_ON]->(Evidence)
(ReasoningStep)-[:RETRIEVED]->(Entity)
```

## Comandos alvo

```bash
kryonix brain traces list
kryonix brain traces show <id>
kryonix brain traces similar "erro do ollama"
kryonix brain traces provenance <id>
```

## Uso esperado

Registrar:

- pergunta original;
- contexto recuperado;
- ferramentas chamadas;
- argumentos e resultados;
- decisão final;
- sucesso/falha;
- evidências.

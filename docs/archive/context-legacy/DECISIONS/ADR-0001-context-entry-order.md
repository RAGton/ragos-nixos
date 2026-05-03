# ADR-0001 — Entrada Curta de Contexto

## Status

Aceita em 2026-04-23.

## Decisão

`AGENTS.md` continua sendo o contrato raiz, mas deixa de carregar sozinho toda a memória operacional.

A ordem oficial passa a ser:

1. `AGENTS.md`
2. `context/INDEX.md`
3. skill relevante
4. código real
5. web oficial quando necessário

## Motivo

- reduzir token desperdiçado
- evitar um AGENTS monolítico
- permitir leitura progressiva por tarefa

## Consequência

Novas decisões e incidentes devem preferir `context/DECISIONS/` e `context/INCIDENTS/` em vez de expandir indefinidamente o `AGENTS.md`.

# Kryonix Issue Triage — 2026-05-13

## Runtime Glacier/Brain
- **[CLOSED] #48** — Backend experimental llama.cpp CUDA integrado com provider auto/fallback e métricas.
- **#19** — [P1] Brain API daemon + política final de runtime + exposição + boot.
- **#21** — [P1] Boot autônomo real do Glacier (depende de #19).

## Brain Quality (Próximo Ciclo)
- **#34** — [P1] Normalização de typos e aliases (Ex: "seaarch" -> "search").
- **#33/#46** — Contrato real ask vs search (separação clara de intenção).
- **#39** — Grounding e answerability sem contradição técnica.
- **#40** — Síntese comparativa grounded entre componentes.
- **#41** — Explain com cobertura por termo e links para arquivos.
- **#42** — Evals e Golden Questions para regressão.
- **#43** — Documentação final do pipeline RAG.

## CAG Health
- **#35** — CAG manifest ausente sem causar HTTP 500.
- **#47** — Brain doctor com validação de RAG freshness.

## Issues Duplicadas (Triadas)
- **#28** (Coberta por #40)
- **#29** (Coberta por #33/#46)
- **#30** (Coberta por #35)
- **#32** (Duplicada de #33)
- **#36** (Coberta por #40)
- **#37** (Coberta por #34)
- **#38** (Coberta por #35)

## Roadmap Futuro
- **#20** — MCP remoto com discovery (Inspiron -> Glacier).
- **#26** — Fluxo Docs -> Vault -> Brain automático.
- **#22-#27** — Outras melhorias de infra e UX.

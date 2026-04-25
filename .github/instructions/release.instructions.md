---
applyTo: ".github/workflows/**/*.yml,docs/**/*.md,context/DECISIONS/**/*.md,context/RUNBOOKS/**/*.md,context/INCIDENTS/**/*.md,.github/prompts/write-release.prompt.md"
---

Release note e documentação operacional devem refletir apenas estado validado.

Separe claramente:
- comportamento já validado
- comportamento pretendido mas ainda não provado
- falhas antigas encontradas durante a validação

Ao descrever uma mudança, cite hosts afetados, comandos de validação e limitações conhecidas.

Não venda refactor planejado como funcionalidade entregue.

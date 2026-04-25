---
agent: "agent"
description: "Escrever release note ou resumo de entrega alinhado ao estado validado do Kryonix"
---

Leia `#file:../../AGENTS.md`, `#file:../../context/INDEX.md` e `#file:../../skills/release-engineering/SKILL.md`.

Escopo da release: `${input:escopo:Qual conjunto de mudanças entrou?}`
Hosts afetados: `${input:hosts:Quais hosts ou perfis foram impactados?}`
Validação disponível: `${input:validacao:Quais comandos ou testes já foram executados?}`

Escreva um resumo que:
- cite apenas comportamento validado
- separe falha antiga de falha nova
- destaque risco operacional restante
- mantenha linguagem objetiva e auditável

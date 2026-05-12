---
agent: "agent"
description: "Diagnosticar e corrigir regressões do launcher Caelestia no Kryonix"
---

Leia `#file:../../AGENTS.md`, `#file:../../context/INDEX.md` e `#file:../../skills/launcher-diagnosis/SKILL.md`.

Objetivo:
- corrigir lentidão, abertura incorreta ou falha de launch no Caelestia
- preservar Caelestia e `uwsm`
- evitar soluções frágeis baseadas em parsing manual de `Exec=`

Entradas:
- host alvo: `${input:host:Host afetado (ex.: inspiron, glacier)}`
- sintoma: `${input:sintoma:Descreva o problema observado}`
- apps de prova: `${input:apps:Liste os apps que precisam abrir corretamente}`

Fluxo esperado:
1. mapear bind ou drawer até o helper real de launch
2. confirmar desktop entry, wrapper, cache e `uwsm`
3. aplicar o patch mínimo e robusto
4. validar com comandos reais e separar erro antigo de erro novo

Entrega:
- causa raiz
- patch aplicado
- comandos de validação
- resultados por app

---
agent: "agent"
description: "Implementar mudança de host NixOS no Kryonix sem quebrar a arquitetura atual"
---

Leia `#file:../../AGENTS.md`, `#file:../../context/INDEX.md` e `#file:../../skills/nix-host-implementation/SKILL.md`.

Host alvo: `${input:host:Qual host será alterado?}`
Objetivo: `${input:objetivo:O que precisa mudar nesse host?}`
Escopo proibido: `${input:escopo_proibido:O que não pode ser tocado?}`

Regras:
- manter mudança pequena e reversível
- respeitar `hosts/`, `profiles/`, `features/` e `modules/`
- não usar caminhos destrutivos em host já instalado
- validar com builds do host e, se houver Home Manager envolvido, do usuário correspondente

Saída esperada:
- arquivos alterados
- o que mudou
- como validar
- riscos e pendências

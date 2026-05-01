---
description: fazer a a iso
---

# ISO / LIVE ENVIRONMENT WORKFLOW

## Objetivo

Padronizar o tratamento do ambiente `glacier-live` como parte oficial do fluxo de ISO/NixOS, evitando deleção acidental e garantindo rastreabilidade.

---

## Quando usar

- Antes de remover ou alterar `hosts/glacier-live`
- Durante refatoração de estrutura NixOS
- Antes de criar release
- Durante implementação de ISO bootável

---

## Regras Aplicadas

- .agents/rules/00-core.md
- .agents/rules/30-nixos.md
- .agents/rules/90-definition-of-done.md

---

## Entrada

- Repo com mudanças em `hosts/glacier-live`
- Estrutura flake ativa

---

## Saída Esperada

- glacier-live corretamente:
  - migrado
  - preservado
  - ou arquivado com justificativa
- nenhum código Nix útil perdido
- release pronto para versionamento

---

## Arquivos Permitidos

- hosts/
- modules/
- flake.nix
- docs/
- docs/archive/
- .agents/workflows/

---

## Arquivos Proibidos

- ai/kryonix-vault/
- docs/canônicas sem justificativa
- secrets
- storage

---

## Passos

### 1. Verificar estado atual

```bash
git diff -- hosts/glacier-live/default.nix
git log -- hosts/glacier-live/default.nix
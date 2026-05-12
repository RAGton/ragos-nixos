# Kryonix PR Closure Audit

## Data
2026-05-12

## Objetivo
Auditar e resolver Pull Requests abertos no repositório Kryonix para consolidar a base de código antes do próximo ciclo de estabilização.

## PRs auditados

| PR | Título | Status | Decisão | Risco | Evidência |
|---:|---|---|---|---|---|
| #1 | Generalize libvirt users in KVM module | NECESSARY | MERGE | ALTO (Users) | Refatoração correta para `rag.users.primary`. |
| #2 | fix: greetd-dms module wiring | PARTIAL | MANUAL MERGE | MÉDIO (greetd) | Parte do conteúdo já está em `main`, parte falta. |
| #6 | Add console keymap br-abnt2 | NECESSARY | MERGE | BAIXO | Configuração de locale e teclado. |
| #9 | fix(greetd): PAM Wayland session | NECESSARY | MERGE | ALTO (PAM) | Solução definitiva para login loop no Wayland. |

## PRs para merge
- #1 (Refatoração de libvirt)
- #6 (Teclado br-abnt2)
- #9 (Correção de PAM/greetd)

## PRs para fechar como obsoletos
- #2 (Wiring de greetd) -> Conteúdo será portado manualmente ou via merge parcial, pois a branch está desalinhada com a `main` atual.

## PRs para recriar
- Nenhum.

## Validações executadas
- `bash -n packages/kryonix-cli/*.sh`
- `git diff --check`
- `nix build .#kryonix --no-link` (Pendentes após merge)
- `nix flake check --keep-going` (Pendentes após merge)

## Riscos restantes
- Alteração no PAM do `greetd` (#9) pode impedir login se houver erro de sintaxe. Backup e rollback via gerações do NixOS são obrigatórios.

## Próxima ação
- Executar merges e validações.

# Kryonix Documentation Audit

## Data
2026-05-12

## Objetivo
Auditar todos os links, referências e documentos canônicos do projeto, corrigindo documentação quebrada, desatualizada ou incoerente depois das mudanças recentes de estabilização e governança (v0.4.2).

## Escopo auditado
- `README.md` (root)
- `README-en.md`
- `ROADMAP.md`
- `AGENTS.md`
- `docs/` (recursivo)

## Links locais
- Corrigidos links absolutos `file:///etc/kryonix/` para caminhos relativos.
- Corrigidas referências para `docs/INDEX.md` que agora aponta para `docs/README.md` (ou o novo `docs/INDEX.md`).

## Links quebrados corrigidos
- `README.md` -> `docs/INDEX.md` atualizado para `docs/README.md`.
- `docs/CLI.md` -> links absolutos para `packages/` e `cli/KRYONIX_COMMAND_CONTRACT.md` corrigidos.
- `docs/OPERATIONS.md` -> `cli/README.md` corrigido para `CLI.md`.
- `docs/ai/PROJECT_INDEX.md` -> `docs/INDEX.md` corrigido para `docs/README.md`.
- `docs/operations/KRYONIX_REINDEX_REPORT.md` -> links absolutos corrigidos.

## Documentos criados
- `docs/operations/KRYONIX_NETWORK_STATUS.md`: Stub para diagnóstico de rede e Tailscale.
- `docs/operations/KRYONIX_DOCS_AUDIT.md`: Este relatório de auditoria.
- `docs/INDEX.md`: Índice canônico consolidado.

## Documentos atualizados
- `README.md`: Atualizado com referências à licença Source Available e novos documentos de auditoria.
- `docs/README.md`: Reestruturado como índice principal.
- `docs/operations/KRYONIX_ISSUES_GOVERNANCE.md`: Atualizado status de #14 e #15 para CLOSED.

## Documentos obsoletos
- `docs/archive/*`: Documentação legada movida para archive ou mantida como histórico.

## Comandos documentados
- `kryonix doctor`
- `kryonix check`
- `kryonix brain health/stats/search`
- `kryonix mcp check/doctor`

## Observações de rastreabilidade
> [!IMPORTANT]
> O commit `c7c69c6` (Auditoria de Licença) incluiu alterações nos arquivos:
> - `features/openrgb.nix`
> - `flake.lock`
> - `hosts/glacier/hardware-configuration.nix`
> - `lib/options.nix`
> - `modules/nixos/services/greetd-dms/default.nix`
>
> **Análise:** Estas alterações foram estritamente de formatação (`nix fmt`) e atualização do lockfile necessárias para garantir o sucesso do build no CI (que exige formatação correta e lockfile sincronizado). Não houve alteração de lógica funcional nestes arquivos durante o referido commit.

## Validações executadas
- [x] `bash -n packages/kryonix-cli/*.sh`
- [x] `git diff --check`
- [x] `nix build .#kryonix --no-link`
- [x] `nix flake check --keep-going`
- [x] Link audit script (Python)

## Pendências
- [ ] Atualizar links em `docs/archive/` (Baixa prioridade - histórico).
- [ ] Sincronizar vault Obsidian com as novas definições canônicas (#26).

## Conclusão
A documentação do Kryonix está agora sincronizada com a realidade operacional do repositório, refletindo as políticas de segurança, licença e CI implementadas na versão 0.4.2.

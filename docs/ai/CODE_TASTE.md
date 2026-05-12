# CODE_TASTE

## Preferencias gerais

- Menor mudanca correta.
- Codigo explicito, revisavel e orientado a rollback.
- Comentarios curtos quando explicam motivo, risco ou decisao operacional.
- Evitar abstracoes novas sem reduzir complexidade real.
- Preservar padroes locais antes de importar estilo externo.

## Nix

- Hosts escolhem opcoes e papeis; modulos implementam comportamento.
- Prefira `lib.mkIf`, `lib.optionals`, `lib.mkDefault` e assertions claras.
- Use `mkForce` apenas quando houver conflito real e motivo documentado.
- Mantenha hardware, boot, GPU, rede e discos isolados por host.
- Nao misture secrets com Nix store.
- Evite alterar `flake.lock` junto com mudanca funcional nao relacionada.
- Overlays devem ter motivo, risco e criterio de remocao quando forem workaround.

## Shell/CLI

- Scripts operacionais devem usar `set -euo pipefail`.
- Mensagens de erro devem orientar o operador.
- Dry-run e verbose sao desejaveis em comandos arriscados.
- Nao parseie saida fragil quando houver comando estruturado ou caminho estavel.
- Comandos destrutivos exigem opt-in humano explicito.

## Documentacao

- Documentacao canonica deve ser curta e apontar para fontes reais.
- Docs historicas podem existir, mas nao devem parecer fonte ativa quando divergirem.
- Prefira tabelas/listas de validacao a textos longos.
- Registre riscos e rollback em mudancas operacionais.

## Qualidade

- Validar no menor nivel util antes de checks caros.
- Adicionar teste/check quando tocar contrato publico.
- Se nao puder validar, registrar exatamente o motivo.
- Evitar PRs que misturam rename, refactor, formatacao e mudanca funcional.

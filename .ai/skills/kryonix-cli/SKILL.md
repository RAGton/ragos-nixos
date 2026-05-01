# Skill: Kryonix CLI

## Escopo

Consolidar a CLI `kryonix` como entrada única para operação diária do sistema.

## Responsabilidades

- manter `kryonix doctor` como diagnóstico rápido do host e da flake
- consolidar `kryonix snapshot` como interface operacional para snapshot seguro
- consolidar `kryonix generations` como leitura objetiva de gerações relevantes
- consolidar `kryonix rollback` como caminho claro de reversão
- preservar resolução de flake, mapeamento de host e mensagens acionáveis

## Regras

- não criar entrypoints paralelos para fluxos que pertencem à CLI
- não esconder comportamento destrutivo atrás de nomes genéricos
- quando um comando ainda não existir, preferir extensão incremental da CLI atual
- alinhar a UX da CLI ao modelo real do projeto: host-aware, direta e verificável

## Referências rápidas

- `ai/context/OPERATING_MODEL.md`
- `docs/OPERATIONS.md`
- `packages/kryonix-cli.nix`

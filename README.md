# RAGOS

Flake pública para meus hosts NixOS e perfis Home Manager.

- Repositório canônico: `RAGton/ragos-nixos`
- Branch principal: `main`
- Release mode: `Tagged`
- Idioma: PT-BR | [English](README-en.md)

## Escopo público

Este repositório publica hoje:

- `nixosConfigurations` para `inspiron`, `inspiron-nina`, `glacier` e `iso`
- `homeConfigurations` para `rocha@inspiron`, `rocha@glacier` e `nina@inspiron-nina`
- overlays reutilizáveis do projeto
- `formatter`
- `checks`

Há módulos e scaffolding relacionados a macOS no repositório, mas o flake público ainda não exporta `darwinConfigurations`.

## Estrutura

```text
.
├── flake.nix
├── flake.lock
├── hosts/
├── home/
├── modules/
├── overlays/
├── files/
├── docs/
└── Makefile
```

## Uso rápido

Clonar o repositório:

```sh
git clone https://github.com/RAGton/ragos-nixos
cd ragos-nixos
```

Inspecionar a flake:

```sh
nix flake show --all-systems
nix flake check --keep-going
```

Aplicar um host NixOS:

```sh
sudo nixos-rebuild switch --flake .#inspiron
```

Aplicar Home Manager:

```sh
home-manager switch --flake .#rocha@inspiron
```

## Bootstrap de senhas

Este repositório não publica senha inicial para `root` nem para usuários.

Para instalação nova, defina as senhas manualmente antes do primeiro boot com comandos como:

```sh
passwd root
passwd rocha
```

Se você preferir bootstrap totalmente não interativo, injete `hashedPasswordFile` ou `initialHashedPassword` fora deste repositório público.

## Makefile

O fluxo público e seguro começa por:

```sh
make help
make flake-show
make flake-check
make nixos-rebuild HOSTNAME=inspiron
make home-manager-switch HOME_TARGET=.#rocha@inspiron
```

Os alvos destrutivos e amarrados a hardware continuam disponíveis, mas exigem `ALLOW_DANGEROUS=1` e ficam separados do caminho principal.

## Desktop e tooling

O repositório mantém módulos para:

- Hyprland com DankMaterialShell
- GDM como display manager padrão
- Dolphin, KIO, KIO Admin e ferramentas KDE úteis sem o shell do Plasma
- Warp Terminal via nixpkgs (`pkgs.warp-terminal`)
- VS Code/Insiders, Jupyter e ferramentas de desenvolvimento
- Flatpak declarativo

## Créditos

- DankMaterialShell por AvengeMedia
- Upstream do DMS: https://github.com/AvengeMedia/DankMaterialShell

## Documentação

- [Índice da documentação](docs/INDEX.md)
- [Guia do Makefile](docs/MAKEFILE_GUIDE.md)
- [Boot e recovery](docs/BOOT_RECOVERY.md)
- [Aplicar no host da Nina sem formatar](docs/INSPIRON_NINA_APPLY.md)

## Release pública

As releases públicas são feitas por tag e publicadas no FlakeHub. O workflow tagged fica em [`.github/workflows/flakehub-publish-tagged.yml`](.github/workflows/flakehub-publish-tagged.yml).

## Licença

MIT. Veja [LICENSE](LICENSE).

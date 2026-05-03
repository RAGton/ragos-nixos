# PROJECT_CONTEXT

## Objetivo

Kryonix e uma plataforma NixOS declarativa para uso real em workstation, gaming, virtualizacao, estudo e desenvolvimento, com base para futura ISO instalavel. O repo tambem prepara uma camada curta de contexto para agentes Codex/LLMs trabalharem com seguranca.

## Tipo detectado

- Principal: NixOS/infra declarativa.
- Tambem: CLI/automacao operacional, desktop Linux, monorepo de configuracao.
- Nao detectado como backend/API web, SaaS ou frontend web.

## Stack detectada

- Nix flakes.
- NixOS.
- Home Manager.
- Hyprland + UWSM.
- Caelestia como shell/rice principal.
- GDM, GRUB, Plymouth e branding Kryonix.
- KVM/libvirt para virtualizacao.
- Podman/Docker opcionais via features.
- Shell scripts empacotados por Nix (`writeShellApplication`).
- GitHub Actions com Determinate Nix.

## Comandos principais

Operacao diaria:

```sh
kryonix doctor
kryonix diff
kryonix test
kryonix boot
kryonix switch
kryonix home
kryonix check
kryonix fmt
kryonix iso
```

Inspecao segura:

```sh
nix flake show --all-systems
nix flake check --keep-going
nix fmt
make help
make flake-show
make flake-check
```

Comandos perigosos exigem aprovacao humana explicita:

```sh
make format-full ALLOW_DANGEROUS=1
make format-system ALLOW_DANGEROUS=1
make install-system ALLOW_DANGEROUS=1
disko
sudo nixos-install
```

## Estrutura

- `flake.nix`: entrada principal e outputs.
- `hosts/`: hosts NixOS reais e ISO.
- `hosts/common/`: composicao compartilhada.
- `home/`: Home Manager por usuario/host.
- `modules/nixos/`: modulos NixOS reutilizaveis.
- `modules/home-manager/`: modulos Home Manager.
- `features/`: capacidades opt-in.
- `profiles/`: presets por papel.
- `desktop/hyprland/`: desktop real e rice.
- `packages/`: CLI `kryonix` e Brain/LightRAG interno.
- `overlays/`: overrides e patches de pacotes.
- `context/`: memoria curta operacional ja existente.
- `docs/ai/`: contexto curto para LLMs.
- `skills/`: procedimentos reutilizaveis para agentes.

## Arquivos importantes

- `AGENTS.md`
- `README.md`
- `flake.nix`
- `flake.lock`
- `Makefile`
- `.github/workflows/ci.yml`
- `.github/copilot-instructions.md`
- `docs/CURRENT_STATE.md`
- `docs/OPERATIONS.md`
- `docs/GLACIER.md`
- `context/INDEX.md`
- `context/CURRENT_STATE.md`
- `lib/options.nix`
- `packages/kryonix-cli.nix`
- `hosts/glacier/hardware-configuration.nix`

## Regras criticas

- O codigo real prevalece sobre docs historicas.
- `Kryonix` e o nome publico atual.
- `kryonix.*` e namespace ativo.
- `kryonix` e a CLI publica unica.
- Hyprland e o desktop real.
- Caelestia e o shell/rice principal.
- DMS e legado em transicao.
- No `glacier`, nao use `disko`, `format-*`, `install-system` ou `hosts/glacier/disks.nix` em fluxo incremental.
- Nao mexa em `flake.lock` sem necessidade clara.

## Como validar mudancas

- Docs: revisar Markdown e links tocados.
- Nix puro: `nix fmt` e `nix flake show --all-systems`.
- Mudanca ampla: `nix flake check --keep-going`.
- Host especifico: avaliar/buildar o host afetado.
- Desktop/launcher: validar Hyprland, UWSM, Caelestia e launch de apps graficos.
- Operacao: preferir `kryonix test` ou `kryonix boot` antes de `kryonix switch`.

# PROJECT_INDEX

## Mapa de modulos

- `flake.nix`: inputs, helpers, hosts, homes, packages, checks e overlays.
- `lib/options.nix`: opcoes publicas `kryonix.*` e aliases internos temporarios.
- `hosts/common/default.nix`: base compartilhada importada por hosts.
- `hosts/<host>/default.nix`: papel, hardware e opcoes do host.
- `hosts/<host>/hardware-configuration.nix`: verdade local de boot, discos e hardware.
- `modules/nixos/base`: base de sistema.
- `modules/nixos/common`: configuracao compartilhada de sistema.
- `modules/nixos/desktop`: habilitacao do desktop.
- `modules/nixos/desktop/caelestia`: shell/rice principal em nivel de sistema.
- `modules/nixos/installer`: ISO e instalador.
- `modules/nixos/services`: servicos como Tailscale, TLP e Snapper.
- `features/development.nix`: toolchains e ferramentas dev.
- `features/gaming.nix`: Steam, Gamescope e ajustes de gaming.
- `features/virtualization.nix`: KVM, libvirt, Podman, Docker e VirtualBox.
- `profiles/*.nix`: composicoes por papel.
- `desktop/hyprland/system.nix`: stack system-level Hyprland.
- `desktop/hyprland/user.nix`: configuracao user-level Hyprland, ainda grande.
- `home/<user>/<host>/default.nix`: Home Manager por usuario/host.
- `packages/kryonix-cli.nix`: CLI operacional principal.
- `packages/kryonix-brain-lightrag/`: Brain/LightRAG usado pela CLI `kryonix`.
- `overlays/default.nix`: patches e overrides de nixpkgs.

## Onde mexer por tipo de tarefa

- Novo host: `hosts/<novo-host>/`, `flake.nix`, `context/HOSTS/`.
- Ajuste de hardware/boot/disco: `hosts/<host>/hardware-configuration.nix` ou arquivo especifico do host.
- Feature reutilizavel: `features/` ou `modules/nixos/`, evitando duplicar em hosts.
- Perfil de papel: `profiles/`.
- Ferramentas de usuario: `home/` ou `modules/home-manager/`.
- Desktop Hyprland/Caelestia: `desktop/hyprland/` e modulos relacionados.
- CLI operacional: `packages/kryonix-cli.nix`.
- Overlay/patch de pacote: `overlays/default.nix` e `overlays/patches/`.
- CI: `.github/workflows/ci.yml`.
- Contexto para IA: `AGENTS.md`, `AGENTS_KRYONIX_EVOLUTION.md`, `context/`, `docs/ai/`, `skills/`.
- Arquitetura Brain: `docs/ai/BRAIN_SERVER_ARCHITECTURE.md`.
- Documentacao humana: `README.md`, `docs/INDEX.md`, `docs/CURRENT_STATE.md`, docs tematicas.

## Arquivos sensiveis

- `flake.nix`
- `flake.lock`
- `hosts/*/hardware-configuration.nix`
- `hosts/*/disks.nix`
- `hosts/glacier/ragenterprise-disko.nix`
- `modules/nixos/installer/*`
- `packages/kryonix-cli.nix`
- `Makefile`
- `.github/workflows/*`
- qualquer referencia a `/root/*.secret`, SSH/GPG keys, Tailscale auth keys, tokens ou credenciais.

## Fluxos principais

### Operacao diaria

1. `kryonix doctor`
2. `kryonix diff`
3. `kryonix test` ou `kryonix boot`
4. `kryonix switch` quando seguro

### Validacao CI

1. `nix flake show --all-systems`
2. `nix flake check --keep-going`

### Resolucao de host pela CLI

1. `--flake`
2. `KRYONIX_FLAKE`
3. checkout local
4. `/etc/kryonix`

### Superficie publica Kryonix

- `kryonix` e a unica CLI publica.
- `kryonix.*` e o namespace publico.
- aliases legados internos podem existir apenas para nao quebrar hosts antigos.

## Contratos importantes

- Outputs de flake: `nixosConfigurations`, `homeConfigurations`, `packages`, `checks`, `formatter`, `overlays`.
- Hosts atuais: `inspiron`, `inspiron-nina`, `glacier`, `iso`.
- Homes atuais: `rocha@inspiron`, `rocha@glacier`, `nina@inspiron-nina`.
- CLI publica: comandos `switch`, `boot`, `test`, `home`, `update`, `rebuild`, `clean`, `diff`, `repl`, `doctor`, `git-status`, `vm`, `iso`, `fmt`, `check`.
- CI deve continuar sem secrets e com permissoes minimas.

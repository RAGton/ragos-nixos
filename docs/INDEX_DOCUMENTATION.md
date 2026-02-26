# Indice: Sessao Wayland (LightDM + Hyprland/UWSM + DMS)

## Documentacao ativa
- `docs/QUICK_START.md`
- `docs/TEST_GUIDE_WAYLAND_SESSION.md`
- `docs/MIGRATION_CHECKLIST.md`

## Fluxo suportado (atual)
- Display manager: LightDM
- Sessao: `hyprland-uwsm`
- Compositor: Hyprland
- Shell/rice: DMS
- Stack de launcher/clipboard/notificacoes/barra: DMS-only no caminho Hyprland

## Legado (historico)
Arquivos antigos de investigacao/solucao com greetd foram movidos para:
- `docs/legacy/greetd/`

Arquivo legado de configuracao Hyprland do caminho antigo:
- `docs/legacy/hyprland/hyprland.conf`

## Checklist rapido
```bash
nix flake check --no-build
nix eval --json .#nixosConfigurations.inspiron.config.services.xserver.displayManager.lightdm.enable
nix eval --json .#nixosConfigurations.inspiron.config.services.displayManager.defaultSession
rg -n "greetd|tuigreet" modules hosts desktop lib -g '*.nix'
```

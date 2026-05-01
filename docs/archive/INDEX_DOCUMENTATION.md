# Índice (Wayland): LightDM + Hyprland/UWSM + DMS

Este é um índice **temático** (Wayland). Para o índice geral, use: [INDEX.md](INDEX.md)

## Documentação ativa

- Quick start: [QUICK_START.md](QUICK_START.md)
- Guia de testes (Wayland session): [TEST_GUIDE_WAYLAND_SESSION.md](TEST_GUIDE_WAYLAND_SESSION.md)
- Checklist de migração: [MIGRATION_CHECKLIST.md](MIGRATION_CHECKLIST.md)

## Fluxo suportado (atual)
- Display manager: LightDM
- Sessao: `hyprland-uwsm`
- Compositor: Hyprland
- Shell/rice: DMS
- Stack de launcher/clipboard/notificacoes/barra: DMS-only no caminho Hyprland

## Legado (historico)
Arquivos antigos de investigacao/solucao com greetd foram movidos para:
- [legacy/greetd/](legacy/greetd/)

Arquivo legado de configuracao Hyprland do caminho antigo:
- [legacy/hyprland/hyprland.conf](legacy/hyprland/hyprland.conf)

## Checklist rapido
```bash
nix flake check --no-build
nix eval --json .#nixosConfigurations.inspiron.config.services.xserver.displayManager.lightdm.enable
nix eval --json .#nixosConfigurations.inspiron.config.services.displayManager.defaultSession
rg -n "greetd|tuigreet" modules hosts desktop lib -g '*.nix'
```

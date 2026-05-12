# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para configurar `swaync` (notification daemon) no Wayland.
#
# Por quê:
# - Centraliza preferências de notificações (tamanho, agrupamento, filtros).
# - Inclui ação para focar a janela do app a partir da notificação (Hyprland).
#
# Como:
# - Habilita `services.swaync` e define `settings`.
# - Usa `notification-action-filter` para esconder notificações específicas.
# - Define script `focus-window` que chama `hyprctl`.
#
# Riscos:
# - O script de foco depende de Hyprland (`hyprctl`); em outros DE/WM pode não funcionar.
# - Filtros por texto/id podem quebrar se o app mudar strings.
# =============================================================================
{ config, lib, ... }:
let
  shellBackend = config.kryonix.shell.backend or null;
  shellProvidesNotifications = shellBackend == "caelestia";
in
{
  # Evita conflito de daemon de notificações com shells que já cobrem essa UX.
  config = lib.mkIf (!shellProvidesNotifications) {
    services.swaync = {
      enable = true;
      settings = {
        control-center-height = 800;
        control-center-width = 400;
        fit-to-screen = false;
        notification-grouping = false;
        notification-window-width = 350;
        notification-icon-size = 32;
        notification-action-filter = {
          hide-brave-settings = {
            desktop-entry = "brave-browser";
            use-regex = false;
            id-matcher = "settings";
            text-matcher = "Settings";
          };
        };
        scripts = {
          focus-window = {
            exec = "bash -c 'hyprctl dispatch focuswindow class:\"$SWAYNC_DESKTOP_ENTRY\"'";
            app-name = ".*";
            run-on = "action";
          };
        };
      };
    };
  };
}

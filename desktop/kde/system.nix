# =============================================================================
# Desktop: KDE Plasma 6 (System-level)
# Autor: rag
#
# O que é:
# - Habilita o stack do KDE Plasma 6 no nível do sistema (SDDM + Plasma).
# - Ajusta tema/cursor do SDDM e remove alguns pacotes padrão do Plasma.
#
# Por quê:
# - Mantém a decisão "KDE como desktop" declarativa e reaproveitável entre hosts.
# - Evita instalar apps KDE redundantes quando você já usa alternativas (ex.: terminal/editor).
#
# Como:
# - `services.displayManager.sddm` + `services.desktopManager.plasma6`.
# - `environment.plasma6.excludePackages` para enxugar o conjunto padrão.
#
# Riscos:
# - Excluir pacotes pode remover funcionalidades esperadas por alguns fluxos; revisar após upgrades do Plasma.
#
# Migração v2:
# - Movido de modules/nixos/desktop/kde/default.nix (Phase 2.1)
# - Path para wallpaper ajustado
# - Auto-enable via rag.desktop.environment (Phase 3)
# =============================================================================
{ config, lib, pkgs, ... }:

let
  # Ajustado para novo local (desktop/ em vez de modules/nixos/desktop/)
  wallpaper = ../../modules/home-manager/misc/wallpaper/wallpaper.jpg;

  lightdmEnabled = ((config.rag.lightdm or { }).enable or false);
in
{
  # PROTEÇÃO: Só habilita SDDM se KDE foi escolhido E LightDM não está ativo
  config = lib.mkIf (config.rag.desktop.environment == "kde" && !lightdmEnabled) {
    # Display manager + Plasma.
    services.displayManager.sddm = {
      enable = true;
      enableHidpi = true;
      settings.Theme.CursorTheme = "Nordzy-cursors";
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = [
      pkgs.nordzy-cursor-theme
      (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
        [General]
        background=${wallpaper};
        type=image
      '')
    ];

    # Enxuga o conjunto padrão do Plasma.
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      baloo-widgets
      elisa
      ffmpegthumbs
      kate
      khelpcenter
      konsole
      krdp
      plasma-browser-integration
    ];

    # Desabilita autostarts redundantes.
    systemd.user.services = {
      "app-org.kde.discover.notifier@autostart".enable = false;
      "app-org.kde.kalendarac@autostart".enable = false;
    };
  };
}


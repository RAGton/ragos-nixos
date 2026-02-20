# =============================================================================
# Desktop: Hyprland (System-level)
# Autor: rag
#
# O que é:
# - Habilita Hyprland (Wayland compositor) e integrações de sessão (GDM, portals, polkit, keyring).
# - Instala um conjunto de ferramentas comuns para uso diário no Hyprland.
#
# Por quê:
# - Deixa o ambiente Wayland completo e consistente logo após `nixos-rebuild`.
# - Evita configurar manualmente serviços essenciais (portal/polkit/keyring).
#
# Como:
# - Ativa GDM e atualiza ambiente DBus no login.
# - Configura `programs.hyprland` e pacotes auxiliares.
#
# Riscos:
# - Portals podem conflitar dependendo do stack; validar em upgrades.
#
# Migração v2:
# - Movido de modules/nixos/desktop/hyprland/default.nix (Phase 2.2)
# - Portal atualizado: xdg-desktop-portal-wlr → xdg-desktop-portal-hyprland (moderno)
# - Auto-enable via rag.desktop.environment (Phase 3)
# =============================================================================
{ config, lib, pkgs, ... }:

let
  # Hyprland ou DMS (DMS usa Hyprland como base)
  isHyprland = config.rag.desktop.environment == "hyprland" ||
               config.rag.desktop.environment == "dms";
in
{
  # Só habilita se Hyprland ou DMS foi escolhido
  config = lib.mkIf isHyprland {
    # Display manager (Wayland-friendly).
    # Preferimos greetd para Hyprland/DMS; evita dependência de GNOME/GDM.
    services.greetd.enable = true;
    services.displayManager.gdm.enable = lib.mkForce false;

    # Mantém variáveis do ambiente exportadas para a sessão via DBus.
    services.xserver.updateDbusEnvironment = true;

    # Bluetooth.
    services.blueman.enable = true;

    # Hyprland.
    programs.hyprland = {
      enable = true;
      # ✨ ATUALIZADO: Portal moderno específico do Hyprland (melhor suporte)
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      withUWSM = true;
    };

    # Segurança/integração da sessão.
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;
    security.pam.services = {
      hyprlock = { };
    };

    # Pacotes auxiliares do stack Hyprland.
    environment.systemPackages = with pkgs; [
      file-roller # gerenciador de arquivos compactados
      gnome-calculator
      gnome-pomodoro
      gnome-text-editor
      loupe # visualizador de imagens
      nautilus # gerenciador de arquivos
      seahorse # gerenciador de keyring
      totem # player de vídeo

      brightnessctl
      grim
      grimblast
      hypridle
      hyprlock
      hyprpaper
      hyprpicker
      libnotify
      networkmanagerapplet
      pamixer
      pavucontrol
      slurp
      wf-recorder
      wlr-randr
      wlsunset
    ];
  };
}

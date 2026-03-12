# ==============================================================================
# Módulo: services (serviços UX do desktop)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Serviços/pacotes de suporte para sessão Hyprland + DMS.
#
# Por quê:
# - Garante lock/logout/notificações/clipboard/screenshot consistentes em todos
#   os hosts sem depender de desktop environments alternativos.
# ==============================================================================
{ pkgs, ... }:
{
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;

  environment.systemPackages = with pkgs; [
    hyprlock
    wlogout
    swaynotificationcenter
    swaybg
    cliphist
    grim
    slurp
    swappy
    wl-clipboard
    rofi-wayland
  ];
}

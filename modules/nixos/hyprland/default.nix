# ==============================================================================
# Módulo: hyprland (enforce do desktop único)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Camada que força Hyprland como único desktop suportado no projeto.
#
# Por quê:
# - Elimina coexistência de DEs e reduz complexidade de manutenção.
# ==============================================================================
{ lib, ... }:
{
  imports = [ ../../../desktop/hyprland/system.nix ];

  config = {
    rag.desktop.environment = lib.mkForce "hyprland";
    services.displayManager.sddm.enable = lib.mkForce false;
    services.desktopManager.plasma6.enable = lib.mkForce false;
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;

    programs.hyprland.enable = true;
    programs.hyprlock.enable = true;
  };
}

# ==============================================================================
# Módulo: audio (PipeWire + WirePlumber + Bluetooth)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Stack de áudio Wayland-first para Hyprland/DMS.
#
# Por quê:
# - Corrige consistência de volume/dispositivos e perfis BT em todos os hosts.
# - Mantém ferramentas práticas para seleção e debug de áudio.
# ==============================================================================
{ pkgs, ... }:
{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol
    pamixer
    playerctl
    bluez
    bluez-tools
    wireplumber
  ];
}

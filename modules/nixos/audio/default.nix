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
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    wireplumber.enable = true;

    extraConfig = {
      pipewire."92-low-latency" = {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.quantum = 128;
          default.clock.min-quantum = 64;
          default.clock.max-quantum = 2048;
        };
      };

      pipewire."95-audio-quality" = {
        context.properties = {
          default.clock.allowed-rates = [ 44100 48000 96000 ];
          resample.quality = 10;
        };
      };

      pipewire-pulse."95-pulse-headroom" = {
        stream.properties = {
          pulse.min.quantum = 64;
        };
        context.properties = {
          pulse.min.req = 64;
          pulse.default.req = 128;
        };
      };
    };
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

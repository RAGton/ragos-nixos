{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kryonix.profiles.workstation-gamer;
in
{
  options.kryonix.profiles.workstation-gamer = {
    enable = mkEnableOption "Profile de Workstation e Gaming (Glacier)";
  };

  config = mkIf cfg.enable {
    # Desktop environment (Hyprland + Caelestia)
    kryonix.desktop.environment = "hyprland";
    kryonix.shell.caelestia.enable = true;

    # Gaming features
    kryonix.features.gaming = {
      enable = true;
      steam.gamescope = true;
      performanceGovernor = true;
    };

    # Drivers NVIDIA (RTX 4060)
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      open = false; # Usa o driver proprietário para melhor suporte a gaming/CUDA
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        sync.enable = lib.mkForce false;
        offload.enable = lib.mkForce false;
      };
    };

    # OpenGL e Vulkan
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Apps de produtividade e gaming
    environment.systemPackages = with pkgs; [
      discord
      obs-studio
      vlc
      gimp
      libreoffice
    ];

    # Wine para apps Windows
    kryonix.features.development.tools.wine.enable = true;
  };
}

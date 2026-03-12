{ pkgs, nhModules, lib, inputs, ... }:
{
  imports = [
    ../../../modules/home-manager/common
    # Desktop user config (hyprland com DMS)
    ../../../desktop/hyprland/user.nix
  ];

  # ==============================
  # Rice: DankMaterialShell (DMS)
  # ==============================
  rag.rice.dmsUpstream.enable = true;

  programs.home-manager.enable = true;

  programs.jupyter = {
    enable = true;
    kernels = {
      python = true;
      c = true;
      rust   = true;
      cpp    = true;
      bash   = true;
    };
  };

  rag.vscode = {
    enable = true;
    channel = "stable";
    flavor = "vscodium";
    installMethod = "nixpkgs";
  };

  # Ajustes específicos do host NVIDIA.
  # Mantém o base config compartilhado e só complementa o necessário.
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    general {
      allow_tearing = true
    }
  '';

  home.packages = with pkgs; [
    inputs.codex.packages.${pkgs.system}.default

    steam
    gamemode
    atlauncher
    moonlight-qt

    # Utilidades GPU NVIDIA
    nvtopPackages.nvidia   # monitor GPU
    vulkan-tools           # vulkaninfo
    mesa-demos            # glxinfo / eglinfo
  ];

  xdg.configFile."dms/settings.json" = {
    source = ../../../files/dms/settings.json;
    force = true;
  };

  xdg.configFile."dms/session.json" = {
    source = ../../../files/dms/session.json;
    force = true;
  };

  home.stateVersion = "26.05";

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}

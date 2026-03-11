{ pkgs, nhModules, lib, ... }:
{
  imports = [
    ../../../modules/home-manager/common
    # Desktop user config (v2 migration: moved to desktop/)
    ../../../desktop/hyprland/user.nix
  ];

  # ==============================
  # Rice/Bar: DankMaterialShell (DMS)
  # ==============================
  # Opção 2 (recomendada): usar os módulos Nix upstream do projeto DMS.
  # - Fonte dos módulos: `${inputs.dms}/distro/nix/home.nix` (importado pelo wrapper)
  # - Pacotes (dms-shell, quickshell, etc.): `inputs.dms-flake.packages.${system}`
  rag.rice.dmsUpstream.enable = true;

  programs.home-manager.enable = true;

  programs.jupyter = {
    enable = true;
    kernels = {
      python = true;
      c = true;
      rust = true;
      cpp = true;
      bash = true;
      dotnet = false;
      node = false;
    };
  };

  rag.vscode = {
    enable = true;
    channel = "unstable";
    flavor = "vscode";
    installMethod = "nixpkgs";
  };

  home.packages = with pkgs; [
    steam
    gamemode
    atlauncher
    moonlight-qt
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

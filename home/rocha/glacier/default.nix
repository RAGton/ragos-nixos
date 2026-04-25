{ pkgs, lib, ... }:
{
  imports = [
    ../../../modules/home-manager/common
    ../../../desktop/hyprland/shell-backend.nix
    ../../../desktop/hyprland/user.nix
    ../../../desktop/hyprland/rice/caelestia-config.nix
    ../shared/vscode.nix
  ];

  kryonix.shell.backend = "caelestia";
  kryonix.programs.aiWorkstation.enable = true;

  kryonix.flatpak.enable = false;

  programs.home-manager.enable = true;

  programs.jupyter = {
    enable = true;
    kernels = {
      python = true;
      c = true;
      rust = true;
      cpp = true;
      bash = true;
    };
  };

  kryonix.vscode = {
    enable = true;
    edition = "codium";
    delivery = "nixpkgs";
  };

  # Ajustes específicos do host NVIDIA.
  # Mantém o base config compartilhado e só complementa o necessário.
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    general {
      gaps_in = 6
      gaps_out = 14
      border_size = 3
      allow_tearing = true
    }

    decoration {
      rounding = 18
      active_opacity = 0.96
      inactive_opacity = 0.90

      blur {
        enabled = true
        size = 4
        passes = 2
        noise = 0.008
        contrast = 1.0
        brightness = 0.92
      }

      shadow {
        enabled = true
        range = 18
        render_power = 3
        color = rgba(05070cee)
      }
    }

    animations {
      enabled = true
      animation = windows, 1, 5, oversh, slide
      animation = windowsOut, 1, 4, smooth, popin 82%
      animation = border, 1, 10, smooth
      animation = workspaces, 1, 5, oversh, slide
    }

    windowrule = match:class ^(steam|steam_app_.*|heroic|lutris)$, opacity 0.97 0.93
  '';

  kryonix.shell.caelestia.settings = {
    appearance.transparency = {
      enabled = true;
      base = 0.78;
      layers = 0.34;
    };

    border = {
      rounding = 22;
      smoothing = 30;
      thickness = 9;
    };

    dashboard = {
      enabled = true;
      showMedia = true;
      showWeather = false;
    };

    general.apps = {
      terminal = [ "kryonix-terminal" ];
      explorer = [ "dolphin" ];
      audio = [ "pavucontrol" ];
    };

    launcher = {
      showOnHover = false;
      maxShown = 10;
      maxWallpapers = 9;
      favouriteApps = [
        "obsidian"
        "steam"
        "heroic"
        "lutris"
        "codium"
        "trae"
        "com.gexperts.Tilix"
        "org.kde.dolphin"
        "org.kde.filelight"
        "virt-manager"
      ];
    };

    paths.wallpaperDir = "~/.local/share/wallpapers";
    sidebar.enabled = true;
    utilities.enabled = true;
  };

  home.packages = with pkgs; [
    google-chrome
  ];

  xdg.mimeApps.defaultApplications = {
    "text/html" = lib.mkForce [ "google-chrome.desktop" ];
    "x-scheme-handler/http" = lib.mkForce [ "google-chrome.desktop" ];
    "x-scheme-handler/https" = lib.mkForce [ "google-chrome.desktop" ];
    "x-scheme-handler/ftp" = lib.mkForce [ "google-chrome.desktop" ];
    "application/xhtml+xml" = lib.mkForce [ "google-chrome.desktop" ];
    "application/x-extension-htm" = lib.mkForce [ "google-chrome.desktop" ];
    "application/x-extension-html" = lib.mkForce [ "google-chrome.desktop" ];
    "application/x-extension-shtml" = lib.mkForce [ "google-chrome.desktop" ];
    "application/x-extension-xhtml" = lib.mkForce [ "google-chrome.desktop" ];
    "application/x-extension-xht" = lib.mkForce [ "google-chrome.desktop" ];
  };

  home.stateVersion = "26.05";

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}

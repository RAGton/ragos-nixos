{ pkgs, lib, ... }:
{
  imports = [
    ../../../modules/home-manager/common
    # Desktop user config (hyprland com DMS)
    ../../../desktop/hyprland/user.nix
    ../shared/vscode.nix
  ];

  # ==============================
  # Rice: DankMaterialShell (DMS)
  # ==============================
  rag.rice.dmsUpstream.enable = true;
  rag.flatpak.enable = false;

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

  rag.vscode = {
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

  rag.rice.dmsOverrides = {
    settings = {
      popupTransparency = 0.44;
      dockTransparency = 0.42;
      cornerRadius = 22;
      animationSpeed = 4;
      popoutAnimationSpeed = 5;
      modalAnimationSpeed = 3;
      blurWallpaperOnOverview = true;
      appsDockEnlargeOnHover = true;
      appsDockEnlargePercentage = 138;
      showWorkspaceName = true;
      fontScale = 1.0;
      showGpuTemp = true;
    };

    session = {
      pinnedApps = [
        "steam"
        "heroic"
        "lutris"
        "dev.warp.Warp"
        "codium"
        "org.kde.dolphin"
        "org.kde.filelight"
        "virt-manager"
      ];
      nvidiaGpuTempEnabled = true;
    };
  };

  home.packages = with pkgs; [
    google-chrome
  ];

  xdg.mimeApps.defaultApplications = lib.mkForce {
    "text/html" = [ "google-chrome.desktop" ];
    "x-scheme-handler/http" = [ "google-chrome.desktop" ];
    "x-scheme-handler/https" = [ "google-chrome.desktop" ];
    "x-scheme-handler/ftp" = [ "google-chrome.desktop" ];
    "application/xhtml+xml" = [ "google-chrome.desktop" ];
    "application/x-extension-htm" = [ "google-chrome.desktop" ];
    "application/x-extension-html" = [ "google-chrome.desktop" ];
    "application/x-extension-shtml" = [ "google-chrome.desktop" ];
    "application/x-extension-xhtml" = [ "google-chrome.desktop" ];
    "application/x-extension-xht" = [ "google-chrome.desktop" ];
    "inode/directory" = [ "org.kde.dolphin.desktop" ];
    "application/x-directory" = [ "org.kde.dolphin.desktop" ];
  };

  home.stateVersion = "26.05";

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}

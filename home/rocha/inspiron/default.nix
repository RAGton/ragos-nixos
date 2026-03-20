{ lib, ... }:
{
  imports = [
    ../../../modules/home-manager/common
    ../../../desktop/hyprland/user.nix
    ../../shared/dev-workstation.nix
    ../shared/vscode.nix
  ];

  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    general {
      gaps_in = 3
      gaps_out = 6
      border_size = 2
    }

    decoration {
      rounding = 8
      active_opacity = 1.0
      inactive_opacity = 1.0

      blur {
        enabled = false
      }
    }

    animations {
      enabled = false
    }

    misc {
      vfr = true
    }
  '';

  rag.rice.dmsOverrides = {
    settings = {
      popupTransparency = 0.76;
      dockTransparency = 0.74;
      cornerRadius = 14;
      animationSpeed = 1;
      popoutAnimationSpeed = 2;
      modalAnimationSpeed = 1;
      enableRippleEffects = false;
      blurWallpaperOnOverview = false;
      appsDockEnlargeOnHover = false;
      showMusic = false;
      showGpuTemp = false;
      fontScale = 0.93;
      appLauncherGridColumns = 3;
    };

    session = {
      pinnedApps = [
        "app.zen_browser.zen"
        "code"
        "dev.warp.Warp"
        "virt-manager"
        "org.kde.dolphin"
        "org.kde.filelight"
        "com.anydesk.Anydesk"
      ];
      nvidiaGpuTempEnabled = false;
    };
  };
}

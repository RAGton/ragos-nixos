{
  config,
  inputs,
  lib,
  nhModules,
  pkgs,
  ...
}:
{
    imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    "${nhModules}/misc/wallpaper"
  ];

  home.packages = with pkgs; [
    kde-rounded-corners
    kdePackages.kcalc
    kdePackages.krohnkite
    kdePackages.wallpaper-engine-plugin
    kdotool
    libnotify
    kora-icon-theme
    nordzy-cursor-theme
  ];

  # Silencia aviso de mudança futura do zsh dotDir
  programs.zsh.dotDir = config.home.homeDirectory;

  # Define o gpg-agent específico para KDE/KWallet
  services.gpg-agent = {
    pinentry.package = lib.mkForce pkgs.kwalletcli;
    extraConfig = "pinentry-program ${pkgs.kwalletcli}/bin/pinentry-kwallet";
  };

  programs.plasma = {
    enable = true;

    fonts = {
      fixedWidth = {
        family = "JetBrainsMono Nerd Font Mono";
        pointSize = 11;
      };
      general = {
        family = "Roboto";
        pointSize = 11;
      };
      menu = {
        family = "Roboto";
        pointSize = 11;
      };
      small = {
        family = "Roboto";
        pointSize = 8;
      };
      toolbar = {
        family = "Roboto";
        pointSize = 11;
      };
      windowTitle = {
        family = "Roboto";
        pointSize = 11;
      };
    };

    hotkeys.commands = {
      launch-dolphin = {
        name = "Launch Dolphin";
        key = "Meta+E";
        command = "dolphin";
      };
      clear-notifications = {
        name = "Clear all KDE Plasma notifications";
        key = "Meta+Shift+Backspace";
        command = "clear-kde-notifications";
      };
      launch-terminal = {
        name = "Launch Terminal";
        key = "Meta+Return";
        command = "warp-terminal";
      };
      launch-brave = {
        name = "Launch Zen Browser";
        key = "Meta+Shift+B";
        command = "app.zen_browser.zen";
      };
      launch-ocr = {
        name = "Launch OCR";
        key = "Alt+@";
        command = "ocr";
      };
      launch-telegram = {
        name = "Launch Telegram";
        key = "Meta+Shift+T";
        command = "Telegram";
      };
      launch-albert = {
        name = "Launch albert";
        key = "Meta+Space";
        command = "albert toggle";
      };
      move-window-and-focus-to-desktop-1 = {
        name = "Move Window and Focus to Desktop 1";
        key = "Meta+!";
        command = "kde_mv_window 1";
      };
      move-window-and-focus-to-desktop-2 = {
        name = "Move Window and Focus to Desktop 2";
        key = "Meta+@";
        command = "kde_mv_window 2";
      };
      move-window-and-focus-to-desktop-3 = {
        name = "Move Window and Focus to Desktop 3";
        key = "Meta+#";
        command = "kde_mv_window 3";
      };
      move-window-and-focus-to-desktop-4 = {
        name = "Move Window and Focus to Desktop 4";
        key = "Meta+$";
        command = "kde_mv_window 4";
      };
      move-window-and-focus-to-desktop-5 = {
        name = "Move Window and Focus to Desktop 5";
        key = "Meta+%";
        command = "kde_mv_window 5";
      };
      screenshot-region = {
        name = "Capture a rectangular region of the screen";
        key = "Print";
        command = "spectacle --region --nonotify";
      };
      screenshot-screen = {
        name = "Capture the entire desktop";
        key = "Meta+Ctrl+S";
        command = "spectacle --fullscreen --nonotify";
      };
      show-all-applications = {
        name = "Show all applications in Albert";
        key = "Meta+A";
        command = ''albert show "apps "'';
      };
    };

    input = {
      keyboard = {
        layouts = [
          {
            layout = "br";
          }
        ];
        repeatDelay = 250;
        repeatRate = 40;
      };
      mice = [
        {
          accelerationProfile = "none";
          name = "Razer Razer Viper V3 Pro";
          productId = "00c1";
          vendorId = "1532";
        }
        {
          accelerationProfile = "none";
          name = "Logitech USB Receiver";
          productId = "c547";
          vendorId = "046d";
        }
      ];
      touchpads = [
        {
          disableWhileTyping = true;
          enable = true;
          leftHanded = false;
          middleButtonEmulation = true;
          name = "ELAN06A0:00 04F3:3231 Touchpad";
          naturalScroll = true;
          pointerSpeed = 0;
          productId = "3231";
          tapToClick = true;
          vendorId = "04f3";
        }
      ];
    };

    krunner.activateWhenTypingOnDesktop = false;

    kscreenlocker = {
      appearance.showMediaControls = false;
       appearance.wallpaper = config.wallpaper;
      autoLock = false;
      timeout = 0;
    };

    kwin = {
      nightLight = {
        enable = false;
        location.latitude = "52.23";
        location.longitude = "21.01";
        mode = "location";
        temperature.night = 4000;
      };

      virtualDesktops = {
        number = 8;
        rows = 1;
      };
    };

    overrideConfig = true;

    # Uma única barra inteira no topo:
    # - sem Task Manager
    # - Pager no meio (mostra número do desktop e ícones das janelas)
    # - espaçadores para organizar
    # - seletor de usuário
    # - monitores em linha (rede + RAM)
    panels = [
      {
        location = "top";
        # Menor = ícones menores (inclui system tray)
        height = 36;
        floating = false;
        opacity = "translucent";
        widgets = [
          # Logo do NixOS (sem launcher/menu)
          {
            name = "org.kde.plasma.icon";
            config = {
              General = {
                icon = "nixos";
              };
            };
          }

          # Seletor de usuário (igual ao appletsrc)
          {
            name = "org.kde.plasma.userswitcher";
            config = {
              General = {
                showFace = true;
                showFullName = false;
                showName = false;
              };
            };
          }

          # Espaçador + Pager central
          { name = "org.kde.plasma.panelspacer"; }
          {
            name = "org.kde.plasma.pager";
            config = {
              General = {
                # Mostra número do desktop e ícones das janelas
                displayedText = "Number";
                showWindowIcons = true;
              };
            };
          }
          { name = "org.kde.plasma.panelspacer"; }

          # Monitores em linha (rede + RAM)
          {
            name = "org.kde.plasma.systemmonitor.net";
            config = {
              CurrentPreset = "org.kde.plasma.systemmonitor";
              Appearance = {
                chartFace = "org.kde.ksysguard.linechart";
                title = "Rede";
              };
              SensorColors = {
                "network/all/download" = "52,152,219";
                "network/all/upload" = "219,119,52";
              };
              Sensors = {
                highPrioritySensorIds = [
                  "network/all/download"
                  "network/all/upload"
                ];
              };
            };
          }
          {
            name = "org.kde.plasma.systemmonitor.memory";
            config = {
              CurrentPreset = "org.kde.plasma.systemmonitor";
              Appearance = {
                chartFace = "org.kde.ksysguard.linechart";
                title = "RAM";
              };
              SensorColors = {
                "memory/physical/used" = "52,152,219";
              };
              Sensors = {
                highPrioritySensorIds = [ "memory/physical/used" ];
                lowPrioritySensorIds = [ "memory/physical/total" ];
                totalSensors = [ "memory/physical/usedPercent" ];
              };
            };
          }

          {
            systemTray = {
              icons.scaleToFit = true;
              items = {
                # Tudo sempre visível (como você pediu)
                showAll = true;
                configs = {
                  "org.kde.plasma.notifications".config = {
                    Shortcuts.global = "Meta+N";
                  };
                };
              };
            };
          }
          {
            name = "org.kde.plasma.digitalclock";
            config = {
              PreloadWeight = 65;
              popupHeight = 451;
              popupWidth = 560;
              Appearance = {
                autoFontAndSize = false;
                customDateFormat = "ddd MMM d";
                dateDisplayFormat = "BesideTime";
                dateFormat = "custom";
                fontSize = 11;
                fontStyleName = "Regular";
                fontWeight = 400;
                use24hFormat = 2;
              };
            };
          }
        ];
      }
    ];

    powerdevil = {
      AC = {
        autoSuspend.action = "nothing";
        dimDisplay.enable = false;
        powerButtonAction = "shutDown";
        turnOffDisplay.idleTimeout = "never";
      };
      battery = {
        autoSuspend.action = "nothing";
        dimDisplay.enable = false;
        powerButtonAction = "shutDown";
        turnOffDisplay.idleTimeout = "never";
      };
    };

    session = {
      general.askForConfirmationOnLogout = false;
      sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    };

    shortcuts = {
      ksmserver = {
        "Lock Session" = [
          "Screensaver"
          "Ctrl+Alt+L"
        ];
        "LogOut" = [
          "Ctrl+Alt+Q"
        ];
      };

      "KDE Keyboard Layout Switcher" = {
        "Switch to Next Keyboard Layout" = "Meta+Space";
      };

      kwin = {
        "KrohnkiteMonocleLayout" = [ ];
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        "Switch to Desktop 5" = "Meta+5";
        "Switch to Desktop 6" = "Meta+6";
        "Switch to Desktop 7" = "Meta+7";
        "Switch to Desktop 8" = "Meta+8";
        "Window Close" = "Meta+Q";
        "Window Fullscreen" = "Meta+M";
        "Window Move Center" = "Ctrl+Alt+C";
      };

      plasmashell = {
        "show-on-mouse-pos" = "";
      };

      "services/org.kde.dolphin.desktop"."_launch" = "Meta+e";
    };

    spectacle = {
      shortcuts = {
        captureEntireDesktop = "";
        captureRectangularRegion = "";
        launch = "";
        recordRegion = "Meta+Shift+R";
        recordScreen = "Meta+Ctrl+R";
        recordWindow = "";
      };
    };

    window-rules = [
      {
        apply = {
          noborder = {
            value = true;
            apply = "initially";
          };
        };
        description = "Hide titlebar by default";
        match = {
          window-class = {
            value = ".*";
            type = "regex";
          };
        };
      }
      {
        apply = {
          desktops = "Desktop_1";
          desktopsrule = "3";
        };
        description = "Assign Zen Browser to Desktop 1";
        match = {
          window-class = {
            value = "zen-browser";
            type = "substring";
          };
          window-types = [ "normal" ];
        };
      }
      {
        apply = {
          desktops = "Desktop_2";
          desktopsrule = "3";
        };
        description = "Assign terminal to Desktop 2";
        match = {
          window-class = {
            value = "WezTerm";
            type = "substring";
          };
          window-types = [ "normal" ];
        };
      }
      {
        apply = {
          desktops = "Desktop_3";
          desktopsrule = "3";
        };
        description = "Assign Telegram to Desktop 3";
        match = {
          window-class = {
            value = "org.telegram.desktop";
            type = "substring";
          };
          window-types = [ "normal" ];
        };
      }
      {
        apply = {
          desktops = "Desktop_4";
          desktopsrule = "3";
        };
        description = "Assign OBS to Desktop 4";
        match = {
          window-class = {
            value = "com.obsproject.Studio";
            type = "substring";
          };
          window-types = [ "normal" ];
        };
      }
      {
        apply = {
          desktops = "Desktop_4";
          desktopsrule = "3";
          fsplevel = "4";
          fsplevelrule = "2";
          minimizerule = "2";
        };
        description = "Assign Steam to Desktop 4";
        match = {
          window-class = {
            value = "steam";
            type = "exact";
            match-whole = false;
          };
          window-types = [ "normal" ];
        };
      }
      {
        apply = {
          desktops = "Desktop_5";
          desktopsrule = "3";
          fsplevel = "4";
          fsplevelrule = "2";
        };
        description = "Assign Steam Games to Desktop 5";
        match = {
          window-class = {
            value = "steam_app_";
            type = "substring";
            match-whole = false;
          };
        };
      }
      {
        apply = {
          desktops = "Desktop_5";
          desktopsrule = "3";
          fsplevel = "4";
          fsplevelrule = "2";
          minimizerule = "2";
        };
        description = "Assign Zoom to Desktop 5";
        match = {
          window-class = {
            value = "zoom";
            type = "substring";
          };
          window-types = [ "normal" ];
        };
      }
    ];

    # Tema visual: Kvantum Edna, colorScheme, cursor, etc
    workspace = {
      enableMiddleClickPaste = false;
      clickItemTo = "select";
      # Plasma 6 (plasma-manager): IDs vêm de
      # - plasma-apply-lookandfeel --list
      # - plasma-apply-desktoptheme --list-themes
      # - plasma-apply-colorscheme --list-schemes
      theme = "Edna";
      colorScheme = "Edna";
      # Aurorae (decoração de janelas) - Tema: https://store.kde.org/p/1528961
      windowDecorations = {
        library = "org.kde.kwin.aurorae";
        theme = "__aurorae__svg__Edna";
      };
      cursor.theme = "Nordzy-cursors";
      tooltipDelay = 1;
      wallpaper = config.wallpaper;
    };

    # Configurações extras: kwinrc, etc
    configFile = {
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;
      gwenviewrc.ThumbnailView.AutoplayVideos = true;
        kdeglobals = {
        General = {
            BrowserApplication = "app.zen_browser.zen.desktop";
        };
        Icons = {
          Theme = "kora";
        };
        KDE = {
          # Reabilita animações (0 desliga geral)
          AnimationDurationFactor = 1;
        };
          Theme = {
            AutomaticDarkTheme = true;
            # Optionally set day/night theme identifiers (adjust if different):
            # DayTheme = "org.kde.edna-light.desktop";
            # NightTheme = "org.kde.edna.desktop";
          };
      };
      klaunchrc.FeedbackStyle.BusyCursor = false;
      klipperrc.General.MaxClipItems = 1000;
      kwinrc = {
        Effect-overview.BorderActivate = 9;
        Plugins = {
          # Transparência/efeitos
          blurEnabled = true;
          dimscreenEnabled = false;
          krohnkiteEnabled = false;
          screenedgeEnabled = false;

          # Animações/efeitos (o que você descreveu como "ir para trás" e "folha")
          # Nomes podem variar por versão, mas essas flags são seguras de manter.
          magiclampEnabled = true;
          slidebackEnabled = true;
          wobblywindowsEnabled = true;
          translucencyEnabled = true;
        };
        "Round-Corners" = {
          ActiveOutlineAlpha = 255;
          ActiveOutlineUseCustom = false;
          ActiveOutlineUsePalette = true;
          AnimationDuration = 0;
          DisableOutlineTile = false;
          DisableRoundTile = false;
          InactiveCornerRadius = 8;
          InactiveOutlineAlpha = 0;
          InactiveSecondOutlineThickness = 0;
          OutlineThickness = 1;
          SecondOutlineThickness = 0;
          Size = 8;
          UseNativeDecorationShadows = false;
        };
        "Script-krohnkite" = {
          floatingClass = "org.kde.kcalc,org.freedesktop.impl.portal.desktop.kde";
          screenGapBetween = 6;
          screenGapBottom = 6;
          screenGapLeft = 6;
          screenGapRight = 6;
          screenGapTop = 6;
        };
        Windows = {
          DelayFocusInterval = 0;
          FocusPolicy = "FocusFollowsMouse";
          BorderlessMaximizedWindows = true;
        };
      };
      plasmanotifyrc = {
        DoNotDisturb = {
          WhenFullscreen = false;
          WhenScreenSharing = false;
          WhenScreensMirrored = false;
        };
        Notifications = {
          PopupPosition = "TopRight";
          PopupTimeout = 7000;
        };
      };
      plasmarc.OSD.Enabled = false;
      spectaclerc = {
        Annotations = {
          annotationToolType = 8;
          rectangleStrokeColor = "255,0,0";
        };
        General = {
          launchAction = "DoNotTakeScreenshot";
          showCaptureInstructions = false;
          useReleaseToCapture = true;
        };
        ImageSave.imageCompressionQuality = 100;
      };
    };
    dataFile = {
      "dolphin/view_properties/global/.directory"."Dolphin"."ViewMode" = 1;
      "dolphin/view_properties/global/.directory"."Settings"."HiddenFilesShown" = true;
    };
  };

  # Mitigação: alguns plasmoids instalados manualmente (KDE Store) quebram no Plasma 6
  # e podem causar crashes/bug no diálogo de configuração de widgets.
  # Aqui nós só movemos para uma pasta "disabled" (sem apagar) para recuperar estabilidade.
  home.activation.disable-broken-plasmoids = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    disabled_dir="$HOME/.local/share/plasma/plasmoids-disabled"
    mkdir -p "$disabled_dir"

    for name in org.kpple.kppleMenu Weather.IntiSol.kde org.dhruv8sh.kara; do
      src="$HOME/.local/share/plasma/plasmoids/$name"
      if [ -d "$src" ]; then
        ts="$(date +%Y%m%d-%H%M%S)"
        dst="$disabled_dir/$name-$ts"
        mv "$src" "$dst"
      fi
    done
  '';

  # Hardening: evita falhas do plasma-manager quando não há sessão gráfica ativa.
  # Isso reduz "user systemd degraded" e previne timeouts no sd-switch.
  systemd.user.services."app-plasma-manager-commands@" = {
    Unit = {
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      TimeoutStartSec = "20s";
      Nice = 10;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
  };
}

{
  outputs,
  pkgs,
  userConfig,
  ...
}:
{
  # Configuração do nixpkgs
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

  # Configurações do Nix
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
    optimise.automatic = true;
    package = pkgs.nix;
  };

  # Configuração do usuário
  users.users.${userConfig.name} = {
    name = "${userConfig.name}";
    home = "/Users/${userConfig.name}";
  };

  # Permite usar TouchID no sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Sudo sem senha
  security.sudo.extraConfig = "${userConfig.name}    ALL = (ALL) NOPASSWD: ALL";

  # Configurações do sistema
  system = {
    defaults = {
      controlcenter = {
        BatteryShowPercentage = true;
        NowPlaying = false;
      };
      CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            "163" = {
              # Define 'Option + N' para mostrar a Central de Notificações
              enabled = true;
              value = {
                parameters = [
                  110
                  45
                  524288
                ];
                type = "standard";
              };
            };
            "184" = {
              # Define 'Option + Shift + R' para opções de captura e gravação
              enabled = true;
              value = {
                parameters = [
                  114
                  15
                  655360
                ];
                type = "standard";
              };
            };
            "60" = {
              # Desabilita '^ + Space' para selecionar a fonte de entrada anterior
              enabled = false;
            };
            "61" = {
              # Define 'Option + Space' para selecionar a próxima fonte de entrada
              enabled = 1;
              value = {
                parameters = [
                  32
                  49
                  524288
                ];
                type = "standard";
              };
            };
            "64" = {
              # Desabilita 'Cmd + Space' para a busca do Spotlight
              enabled = false;
            };
            "65" = {
              # Desabilita 'Cmd + Alt + Space' para a janela de busca do Finder
              enabled = false;
            };
            "238" = {
              # Define 'Control + Command + C' para centralizar a janela em foco
              enabled = true;
              value = {
                parameters = [
                  99
                  8
                  1310720
                ];
                type = "standard";
              };
            };
            "98" = {
              # Desabilita 'Mostrar menu Ajuda'
              enabled = false;
              value = {
                parameters = [
                  47
                  44
                  1179648
                ];
                type = "standard";
              };
            };
          };
        };
        "com.brave.Browser" = {
          NSUserKeyEquivalents = {
            "Close Tab" = "^w";
            "Find..." = "^f";
            "New Private Window" = "^$n";
            "New Tab" = "^t";
            "Reload This Page" = "^r";
            "Reopen Closed Tab" = "^$t";
            "Reset zoom" = "^0";
            "Zoom In" = "^=";
            "Zoom Out" = "^-";
          };
        };
        "com.caldis.Mos" = {
          hideStatusItem = true;
        };
        "com.dwarvesv.minimalbar" = {
          areSeparatorsHidden = 1;
          isAutoHide = 1;
          isAutoStart = 1;
          isShowPreferences = 0;
          numberOfSecondForAutoHide = 5;
        };
        NSGlobalDomain."com.apple.mouse.linear" = true;
        "-g".NSUserKeyEquivalents = {
          "Lock Screen" = "@^l";
          "Paste and Match Style" = "^$v";
        };
      };
      NSGlobalDomain = {
        "com.apple.sound.beep.volume" = 0.000;
        AppleInterfaceStyle = "Dark";
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 20;
        KeyRepeat = 2;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        PMPrintingExpandedStateForPrint = true;
      };
      LaunchServices = {
        LSQuarantine = false;
      };
      trackpad = {
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
        Clicking = true;
      };
      finder = {
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
      };
      dock = {
        autohide = true;
        expose-animation-duration = 0.15;
        show-recents = false;
        showhidden = true;
        persistent-apps = [ ];
        tilesize = 30;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };
      screencapture = {
        location = "/Users/${userConfig.name}/Downloads/temp";
        type = "png";
        disable-shadow = true;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      # Remapeia §± para ~
      userKeyMapping = [
        {
          HIDKeyboardModifierMappingDst = 30064771125;
          HIDKeyboardModifierMappingSrc = 30064771172;
        }
      ];
    };
    primaryUser = "${userConfig.name}";
  };

  # Configuração do Zsh
  programs.zsh.enable = true;

  # Configuração de fontes
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];
}

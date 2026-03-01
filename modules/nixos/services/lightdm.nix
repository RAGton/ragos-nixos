{
  config,
  lib,
  pkgs,
  userConfig ? null,
  ...
}:
{
  options.rag.lightdm = {
    enable = lib.mkEnableOption "LightDM Display Manager with modern theme and Wayland support";

    theme = {
      gtk = lib.mkOption {
        type = lib.types.str;
        default = "Adwaita-dark";
        description = "GTK theme name for LightDM greeter";
      };

      icons = lib.mkOption {
        type = lib.types.str;
        default = "Papirus-Dark";
        description = "Icon theme name for LightDM greeter";
      };
    };

    autoLogin = {
      enable = lib.mkEnableOption "Auto-login for LightDM";
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = if userConfig != null then userConfig.name else null;
        description = "User to auto-login (uses userConfig.name by default)";
      };
    };
  };

  config = lib.mkIf config.rag.lightdm.enable {
    # ==================================================
    # Forçar remoção de GreetD e SDDM
    # ==================================================
    services.greetd.enable = lib.mkForce false;
    services.displayManager.sddm.enable = lib.mkForce false;
    services.displayManager.gdm.enable = lib.mkForce false;
    services.desktopManager.plasma6.enable = lib.mkForce false;

    # ==================================================
    # BASE OBRIGATÓRIA PARA LIGHTDM (EXIGE X SERVER)
    # ==================================================
    services.xserver.enable = true;
    services.libinput.enable = true;

    # ==================================================
    # LIGHTDM DISPLAY MANAGER
    # ==================================================
    services.xserver.displayManager.lightdm = {
      enable = true;
      # Força a sessão padrão para evitar que o LightDM “lembre” uma sessão
      # anterior (ex.: `hyprland-uwsm`) que pode quebrar sob LightDM.
      extraSeatDefaults = ''
        user-session=hyprland
      '';
      greeters.gtk = {
        enable = true;
        theme.name = config.rag.lightdm.theme.gtk;
        iconTheme.name = config.rag.lightdm.theme.icons;
        extraConfig = ''
          font-name = Inter 11
          indicators = ~clock;~spacer;~session;~language;~a11y;~power
          clock-format = %H:%M, %A %d de %B
          allow-debugging = false
        '';
      };
    };

    # ==================================================
    # Sessão principal
    # ==================================================
    services.displayManager.defaultSession = "hyprland";

    # ==================================================
    # Auto-login
    # ==================================================
    services.displayManager.autoLogin = lib.mkIf config.rag.lightdm.autoLogin.enable {
      enable = true;
      user = config.rag.lightdm.autoLogin.user;
    };

    # ==================================================
    # Pacotes necessários para tema moderno do LightDM
    # ==================================================
    environment.systemPackages = with pkgs; [
      adwaita-icon-theme
      papirus-icon-theme
      inter
      roboto
    ];

    # ==================================================
    # Variáveis de ambiente
    # ==================================================
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
    };
  };
}

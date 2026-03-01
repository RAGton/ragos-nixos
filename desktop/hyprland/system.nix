{ config, lib, pkgs, userConfig ? null, ... }:

let
  lightdmEnabled = ((config.rag.lightdm or { }).enable or false);

  isHyprland =
    config.rag.desktop.environment == "hyprland" ||
    config.rag.desktop.environment == "dms";

  directLoginEnabled = (config.rag.desktop.directLogin.enable or false) && userConfig != null;
  directLoginTtyNumber = toString (config.rag.desktop.directLogin.tty or 1);
  directLoginTty = "tty${directLoginTtyNumber}";
in
{
  config = lib.mkIf isHyprland {

    # DirectLogin: autologin APENAS no TTY escolhido (desabilitado quando LightDM ativo)
    # Importante: `services.getty.autologinUser` é global e acaba logando o usuário em TODOS os TTYs.
    systemd.services."getty@${directLoginTty}" = lib.mkIf (directLoginEnabled && !lightdmEnabled) {
      serviceConfig.ExecStart = [
        ""
        "${pkgs.util-linux}/sbin/agetty --autologin ${userConfig.name} --login-program ${pkgs.shadow}/bin/login --noclear --keep-baud 115200,38400,9600 %I $TERM"
      ];
    };

    # Boot direto (sem display manager): ao logar no TTY escolhido, inicia Hyprland via UWSM.
    # Mantemos isso no nível do sistema para funcionar mesmo sem `home-manager switch`.
    # DESABILITADO quando LightDM está ativo (evita conflito).
    programs.zsh.loginShellInit = lib.mkIf (config.rag.desktop.directLogin.enable && !lightdmEnabled) (lib.mkAfter ''
      if [[ -z "''${WAYLAND_DISPLAY-}" && -z "''${DISPLAY-}" && "''${XDG_VTNR-}" = "${directLoginTtyNumber}" ]]; then
        if command -v uwsm >/dev/null 2>&1; then
          exec uwsm start hyprland-uwsm.desktop
        fi
        exec Hyprland
      fi
    '');

    # Kill greetd em qualquer modo do stack Hyprland/DMS (proibido aqui)
    services.greetd.enable = lib.mkForce false;

    # Se estiver em directLogin SEM LightDM, garantimos que outros DMs não entrem.
    services.displayManager.sddm.enable = lib.mkIf (config.rag.desktop.directLogin.enable && !lightdmEnabled) (lib.mkForce false);
    services.displayManager.gdm.enable = lib.mkIf (config.rag.desktop.directLogin.enable && !lightdmEnabled) (lib.mkForce false);

    # Enable X stack condicionalmente:
    # - DirectLogin (Wayland-only): sem Xorg
    # - LightDM: precisa de Xorg para o greeter (habilitado pelo módulo lightdm.nix)
    services.xserver.enable = lib.mkDefault (lightdmEnabled || !(config.rag.desktop.directLogin.enable or false));

    # Default session (usado pelo módulo LightDM quando habilitado)
    services.displayManager.defaultSession = lib.mkDefault "hyprland";

    # Disable DM autologin somente quando NÃO usamos DM (directLogin)
    services.displayManager.autoLogin.enable = lib.mkIf (config.rag.desktop.directLogin.enable or false) (lib.mkForce false);

    # Hyprland
    programs.hyprland = {
      enable = true;
      # UWSM funciona muito bem no fluxo “directLogin/TTY”, mas com LightDM
      # tende a causar loop de login (uwsm detecta `graphical-session.target`
      # já ativo e recusa iniciar o compositor).
      withUWSM = lib.mkDefault (!lightdmEnabled);
      xwayland.enable = true;
    };

    # Portals
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    assertions = [
      {
        assertion = !config.services.greetd.enable;
        message = "greetd must not be enabled in Hyprland/DMS stack.";
      }
    ];
  };
}

{ config, lib, pkgs, ... }:

let
  isHyprland =
    config.rag.desktop.environment == "hyprland" ||
    config.rag.desktop.environment == "dms";
in
{
  config = lib.mkIf isHyprland {

    # Kill all other DMs
    services.greetd.enable = lib.mkForce false;
    services.gdm.enable = lib.mkForce false;
    services.sddm.enable = lib.mkForce false;

    # Enable graphical stack
    services.xserver.enable = true;
    services.displayManager.lightdm.enable = true;
    services.displayManager.defaultSession = "hyprland-uwsm";

    # Disable any autologin
    services.getty.autologinUser = lib.mkForce null;
    services.displayManager.autoLogin.enable = lib.mkForce false;

    # Hyprland
    programs.hyprland = {
      enable = true;
      withUWSM = true;
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

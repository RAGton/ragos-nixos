{ config, lib, ... }:
let
  env = config.rag.desktop.environment;
in
{
  imports = [
    ../../../desktop/hyprland/system.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (env == "hyprland") {
      rag.desktop.directLogin.enable = lib.mkForce false;

      services.displayManager.gdm.enable = lib.mkForce true;
      services.displayManager.sddm.enable = lib.mkForce false;
      services.desktopManager.plasma6.enable = lib.mkForce false;
      services.desktopManager.gnome.enable = lib.mkForce false;
      services.greetd.enable = lib.mkForce false;

      programs.dconf.enable = true;
      programs.hyprlock.enable = lib.mkDefault true;
    })
  ];
}

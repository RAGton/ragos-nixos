{ config, lib, ... }:

{
  imports = [
    ./hyprland/system.nix
  ];

  config = lib.mkIf (config.rag.desktop.wayland) {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs.xwayland.enable = lib.mkDefault true;
  };
}

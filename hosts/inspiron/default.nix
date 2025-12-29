{ config, lib, pkgs, ... }:

{
  this = {
    host = {
      system = "x86_64-linux";
      hostname = "inspiron";
      interface = [ "wlo1" ];
      ip = null;

      modules = {
        hardware = [ "cpu/intel" ];
        system = [ "nix" "pkgs" ];
        networking = [ "default" ];
        services = [ "default" ];
        programs = [ "default" ];
        virtualisation = [ ];
      };
    };
  };

  imports = [ ./disks.nix ];
}

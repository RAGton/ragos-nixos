{
  inputs,
  hostname,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ../glacier
    ../common
  ];

  # Sobrescrever partes do glacier que não fazem sentido no live
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  fileSystems = lib.mkForce { }; # ISO gerencia isso
  swapDevices = lib.mkForce [ ];

  # Garantir Tailscale no live para teste de rede
  services.tailscale.enable = true;

  # Branding e customização
  networking.hostName = "glacier-live";
}

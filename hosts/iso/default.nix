# Host: iso (Live CD / instalador automatizado)
#
# Objetivo
# - Gerar uma ISO bootável que facilite a instalação dos hosts deste flake.
# - A ISO traz um script `kryonix-install` que particiona (Disko) e roda `nixos-install`.
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
    # Base do instalador do NixOS (ISO minimal)
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    # Nosso módulo de instalador automatizado
    ../../modules/nixos/installer
  ];

  networking.hostName = hostname;

  # ISO deve ser estável e pequena: evita trazer desktop completo.
  documentation.enable = lib.mkDefault false;

  # Ajuda no debug e instalação
  environment.systemPackages = with pkgs; [
    git
    curl
    jq
    fzf
  ];

  # Normalmente útil em instalação remota (opcional)
  services.openssh.enable = lib.mkDefault true;

  # Evita pedir senha no live. Chave pode ser adicionada depois.
  users.users.nixos.openssh.authorizedKeys.keys = lib.mkDefault [ ];
}

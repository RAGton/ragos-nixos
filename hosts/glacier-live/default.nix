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

  # =========================
  # ISO LIVE CONFIG
  # =========================

  # Sobrescrever partes do glacier que não fazem sentido no live
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  swapDevices = lib.mkForce [ ];

  # Desabilitar serviços pesados de IA para o Live
  kryonix.profiles.server-ai.enable = lib.mkForce false;
  services.ollama.enable = lib.mkForce false;

  # Ferramentas de diagnóstico e migração
  environment.systemPackages = with pkgs; [
    # Sistema/Hardware
    pciutils
    usbutils
    lshw
    nvtopPackages.nvidia
    btop
    lsof
    
    # Disco/FS
    parted
    gptfdisk
    btrfs-progs
    
    # Rede/Transferência
    tailscale
    rsync
    rclone
    
    # Utilidades
    git
    curl
    wget
    jq
    vim
  ];

  # SSH habilitado para diagnóstico remoto
  services.openssh.enable = true;

  # Tailscale disponível
  services.tailscale.enable = true;

  # Branding
  networking.hostName = "glacier-live";
}

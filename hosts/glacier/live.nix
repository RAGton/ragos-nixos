{
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # ============================================================================
  # KRYONIX GLACIER LIVE ISO (MINIMAL)
  # ============================================================================
  # Objetivo: Diagnóstico, teste de hardware e rede antes da migração real.
  # ============================================================================

  networking.hostName = "glacier-live";

  # Habilitar serviços básicos para diagnóstico remoto
  services.openssh.enable = true;
  services.tailscale.enable = true;
  networking.networkmanager.enable = true;

  # Usuário padrão da ISO com permissão de sudo sem senha
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Ferramentas mínimas para diagnóstico e operação básica
  environment.systemPackages = with pkgs; [
    # Git e transferências
    git
    curl
    wget
    rsync

    # Editores e utilidades
    vim
    jq
    btop

    # Hardware e diagnóstico
    pciutils
    usbutils
    lshw

    # Disco e particionamento
    parted
    gptfdisk
    btrfs-progs

    # Rede
    tailscale
    networkmanager
  ];

  # Configurações de sistema
  system.stateVersion = "24.11"; # Coerente com a versão estável usada como referência

  # Otimizações para ISO
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Não incluir documentação pesada para reduzir o tamanho
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;

  # Desabilitar serviços desnecessários
  services.xserver.enable = false;
}

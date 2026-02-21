# Host: inspiron (NixOS)
# Autor: rag
#
# O que é
# - Configuração do sistema para a máquina inspiron (imports + ajustes específicos do host).
#
# Por quê
# - Mantém o host “fino”: hardware + integrações específicas, reaproveitando módulos do repo.
#
# Como
# - Importa nixos-hardware + hardware-configuration.
# - Importa módulos comuns (common/desktop/kernel/virtualização).
#
# Riscos
# - Ajustes de kernel/energia/filesystem podem afetar boot e estabilidade; revisar após upgrades.
{
  inputs,
  hostname,
  nixosModules,
  lib,
  ...
}:
{
  imports = [
    # Hardware
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-gpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix

    # Disko (particionamento declarativo — usado pelo Live CD)
    inputs.disko.nixosModules.disko
    ./disks.nix

    # Base do sistema
    "${nixosModules}/common"

    # Desktop: gerenciado via opção (v2 migration)
    # Features: gerenciadas via opções (v2 migration)

    # Kernel e rede
    ../../modules/kernel/zen.nix
    ../../modules/virtualization/net-ragthink.nix

    # Branding (RagOS)
    "${nixosModules}/branding/ragos"
  ];

  # =========================
  # RagOS Options (v2)
  # =========================

  # Hardware toggles
  rag.hardware.openrgb.enable = false;

  # Desktop
  # Troca KDE/SDDM por Hyprland (Wayland) + DMS (user-level upstream via Home Manager).
  rag.desktop.environment = "hyprland";

  # Garante que SDDM não fique habilitado via desktop/kde/system.nix.
  services.displayManager.sddm.enable = lib.mkForce false;

  # display manager Wayland-friendly + greeter DMS
  rag.services.greetdDms.enable = true;

  # (o módulo greetdDms habilita greetd; mantemos esta linha apenas se algum outro módulo tentar desligar)
  services.greetd.enable = lib.mkForce true;

  # Profile (v2)
  rag.profiles.laptop = {
    enable = true;

    # Mantém o comportamento atual do inspiron
    virtualization = {
      enable = true;
      docker.enable = true;
      libvirt.enable = true;
    };

    development.enable = true;

    # Gaming permanece desligado no laptop
    gaming.enable = false;
  };

  # Ajustes específicos além do profile
  rag.features.development = {
    languages = {
      nix.enable = true;
      python.enable = true;
      javascript.enable = true;
    };
    tools.kubernetes.enable = true;
  };

  networking.hostName = hostname;

  # =========================
  # MikroTik Winbox
  # =========================
  # O que é
  # - Habilita o Winbox (GUI de gerenciamento MikroTik).
  #
  # Por quê
  # - Facilita administrar RouterOS/SwOS direto do desktop.
  #
  # Como
  # - `programs.winbox.enable = true` instala o Winbox.
  programs.winbox.enable = true;

  # UniFi Network Application (Controller).
  # services.unifi = {
  #   enable = true;
  #   openFirewall = true;
  # };

  system.stateVersion = "26.05";

  # =========================
  # Boot / Kernel
  # =========================
  boot = {
    loader = {
      systemd-boot.enable = false;

      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = false;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    # Kernel params globais.
    kernelParams = [
      "rootflags=subvol=@,compress=zstd,noatime"
    ];

    # Evita builds inúteis
    initrd.systemd.enable = true;
  };

  # =========================
  # Kernel Zen (ajustado)
  # =========================
  kernelZen = {
    enable = true;

    kernel = "zen";
    forceLocalBuild = false;
    useLLVMStdenv = false;
    extraMakeFlags = [ ];

    # ⚠️ só recomendo isso se for desktop single-user.
    disableMitigations = lib.mkDefault false;

    # Removido: parâmetros agressivos do scheduler podem causar travamentos
    # O kernel Zen já vem otimizado para desktop
    extraKernelParams = [ ];
  };

  ## -------------------------
  ## Performance básica
  ## -------------------------
  # Em laptop, `schedutil` costuma equilibrar performance e bateria melhor que `performance`.
  powerManagement.cpuFreqGovernor = lib.mkForce "schedutil";

  services.power-profiles-daemon.enable = lib.mkForce true;
  services.tlp.enable = lib.mkForce false;

  # Flatpak: mantém a lista comum vinda do módulo shared.
  # (Removemos as extensões NVIDIA do common.)

  # Gaming/estabilidade: evita serviços que brigam por perfil de energia.
  # (PPD já está habilitado acima; mantemos apenas TLP desligado.)

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
  '';

  ## -------------------------
  ## Virtualização (ajuste fino)
  ## -------------------------
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
  '';

  # =========================
  # RagOS (branding do sistema)
  # =========================
  # Mantém o mesmo número de versão do seu `system.stateVersion` para exibição.
  # Obs.: `system.stateVersion` continua sendo a chave de compat do NixOS.
  ragos = {
    enable = true;
    prettyName = "RagOS";
    versionId = "26.05";
  };

  # =========================
  # Tailscale VPN
  # =========================
  services.rag.tailscale = {
    enable = true;
    autoconnect = true;
    authKeyFile = /root/tailscale-authkey.secret;
  };
}

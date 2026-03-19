# ==============================================================================
# Módulo: Host Inspiron Nina
# Autor: rag + Codex
#
# O que é:
# - Configuração NixOS específica do host `inspiron-nina`.
# - Baseada em um Dell Inspiron 15 com Intel i5 12a geração, 8 GB de RAM e SSD de 500 GB.
#
# Por quê:
# - Isola hardware, boot e perfil de uso da máquina da Nina sem reaproveitar
#   UUIDs/identificadores do host `inspiron`.
#
# Como:
# - Usa módulos Intel + SSD do `nixos-hardware`.
# - Importa `hardware-configuration.nix` e `disks.nix` próprios do host.
# - Mantém o desktop padrão do projeto (Hyprland + DMS) com perfil laptop leve.
# ==============================================================================
{
  inputs,
  hostname,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-gpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix

    inputs.disko.nixosModules.disko
    ./disks.nix

    ../../modules/kernel/zen.nix
  ];

  rag.hardware.openrgb.enable = false;

  rag.desktop.environment = "hyprland";
  rag.features.dms.enable = true;
  rag.desktop.directLogin.enable = false;

  rag.profiles.laptop = {
    enable = true;
    virtualization = {
      enable = false;
      docker.enable = false;
      libvirt.enable = false;
    };
    development.enable = true;
    gaming.enable = true;
  };

  rag.profiles.dev.enable = false;
  rag.profiles.university.enable = false;
  rag.profiles.ti.enable = false;

  rag.features.development = {
    languages = {
      nix.enable = true;
      python.enable = true;
      javascript.enable = false;
      rust.enable = false;
      c.enable = true;
      java.enable = false;
      go.enable = false;
    };
    tools = {
      arduino.enable = true;
      wine.enable = true;
      psim.enable = true;
    };
  };

  rag.features.ai.codex.enable = false;

  networking.hostName = hostname;

  system.stateVersion = "26.05";

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

    kernelParams = [
      "rootflags=subvol=@,compress=zstd,noatime"
    ];

    initrd.systemd.enable = true;
  };

  kernelZen = {
    enable = true;
    kernel = "zen";
    forceLocalBuild = false;
    useLLVMStdenv = false;
    extraMakeFlags = [ ];
    disableMitigations = lib.mkDefault false;
    extraKernelParams = [ ];
  };

  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libvdpau-va-gl
      intel-vaapi-driver
    ];
  };

  environment.sessionVariables = {
    MESA_LOADER_DRIVER_OVERRIDE = "iris";
    LIBVA_DRIVER_NAME = "iHD";
    WLR_RENDERER_ALLOW_SOFTWARE = "0";
  };

  powerManagement.cpuFreqGovernor = lib.mkForce "schedutil";

  services.power-profiles-daemon.enable = lib.mkForce true;
  services.tlp.enable = lib.mkForce false;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
  '';

  ragos = {
    enable = true;
    prettyName = "RagOS";
    versionId = "26.05";
  };
}

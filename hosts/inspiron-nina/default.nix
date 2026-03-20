# ==============================================================================
# Módulo: Host Inspiron Nina
# Autor: rag + Codex
#
# O que é:
# - Configuração NixOS específica do host `inspiron-nina`.
# - Mantém o desktop Hyprland do repo sobre a instalação real da Nina.
#
# Por quê:
# - Preserva as partições/dados existentes da máquina.
# - Evita usar o `disko` neste host enquanto ele já está instalado e em uso.
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
    gaming.enable = false;
  };

  rag.profiles.dev.enable = true;
  rag.profiles.university.enable = true;
  rag.profiles.ti.enable = false;

  rag.features.development = {
    languages = {
      nix.enable = true;
      python.enable = true;
      javascript.enable = false;
      rust.enable = false;
      c.enable = true;
      java.enable = true;
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
      timeout = 3;

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

    initrd.systemd.enable = true;
  };

  # Mantém o kernel padrão mais próximo do NixOS atual já em uso pela Nina.
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  networking.firewall.enable = lib.mkForce false;
  services.resolved.enable = true;
  networking.nameservers = [
    "1.1.1.3"
    "1.0.0.3"
  ];

  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;
  services.thermald.enable = true;
  powerManagement.enable = true;
  console.keyMap = "br-abnt2";

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
  '';

  ragos = {
    enable = true;
    prettyName = "RagOS";
    versionId = "26.05";
  };
}

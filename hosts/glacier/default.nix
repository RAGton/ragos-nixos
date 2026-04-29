{
  inputs,
  hostname,
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    # Hardware AMD + NVIDIA (nixos-hardware)
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-cpu-amd-pstate
    inputs.hardware.nixosModules.common-gpu-nvidia

    ./hardware-configuration.nix
    ./rve-compat.nix

    # Kernel e rede
    ../../modules/kernel/zen.nix
    ../../modules/virtualization/net-ragthink.nix
  ];

  # =========================
  # PROFILES (Blueprint)
  # =========================
  kryonix.profiles.server-ai.enable = true;
  kryonix.profiles.workstation-gamer.enable = true;

  # Perfis adicionais herdados
  kryonix.profiles.dev.enable = true;
  kryonix.profiles.university.enable = true;
  kryonix.profiles.ti.enable = true;

  # =========================
  # NETWORK (Fixed IP 10.0.0.2)
  # =========================
  networking = {
    hostName = hostname;
    # Configuração de IP estático para o servidor LAN
    interfaces.enp14s0 = { # Nome da interface ajustado para o hardware alvo (exemplo)
      ipv4.addresses = [{
        address = "10.0.0.2";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.0.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  # =========================
  # BOOT / KERNEL
  # =========================
  boot = {
    loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = false;
        efiInstallAsRemovable = true;
      };
      efi = {
        canTouchEfiVariables = lib.mkForce false;
        efiSysMountPoint = "/boot";
      };
    };

    kernelParams = lib.mkAfter [
      "rootflags=subvol=@,compress=zstd,noatime"
    ];

    initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    kernelModules = [ "kvm-amd" ];
    initrd.systemd.enable = true;
  };

  # =========================
  # SYSTEM
  # =========================
  system.stateVersion = "26.05";

  # Branding
  kryonix.branding = {
    enable = true;
    prettyName = "Kryonix Glacier";
    edition = "Server/Workstation";
  };
}

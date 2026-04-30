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
  # Disabled during the initial install to avoid pulling heavy gaming packages
  # such as Lutris while keeping the hardware/session essentials below.
  kryonix.profiles.workstation-gamer.enable = false;

  # Keep the non-gaming parts normally provided by workstation-gamer.
  kryonix.desktop.environment = "hyprland";
  kryonix.shell.caelestia.enable = true;
  kryonix.features.gaming = {
    enable = false;
    steam.enable = false;
    lutris.enable = false;
    heroic.enable = false;
  };

  # Perfis adicionais herdados
  kryonix.profiles.dev.enable = true;
  kryonix.profiles.university.enable = true;
  kryonix.profiles.ti.enable = true;

  # Drivers NVIDIA (RTX 4060)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      sync.enable = lib.mkForce false;
      offload.enable = lib.mkForce false;
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Remote access baseline.
  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.kryonix.tailscale = {
    advertiseExitNode = true;
    authKeyFile = /root/tailscale-authkey.secret;
    extraUpFlags = [ "--hostname=RVE-GLACIER" ];
  };

  # The Brain API unit still points at an unpackaged runtime/env and must not
  # make host activation fail until that server deployment path is finished.
  systemd.services.kryonix-brain-api.wantedBy = lib.mkForce [ ];

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    htop
    efibootmgr
    pciutils
    usbutils
    tailscale
  ];

  # =========================
  # NETWORK (bridge / br0)
  # =========================
  networking = {
    hostName = hostname;
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
    };
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
        # UEFI-only: do not try to install GRUB as an i386-pc blocklist loader.
        device = "nodev";
        useOSProber = false;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    initrd.kernelModules = lib.mkForce [ ];
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

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

  # Workstation/gaming ficam separados do perfil server-ai para que o Glacier
  # continue buildando como servidor mesmo se a camada gamer for desligada.
  kryonix.features.workstation.enable = true;
  kryonix.features.openrgb.enable = true;
  kryonix.features.gaming = {
    enable = true;
    steam.enable = true;
    steam.gamescope = true;
    gamemode.enable = true;
    mangohud.enable = true;
    lutris.enable = false;
    wineTools.enable = false;
    nvtop.enable = false;
    heroic.enable = true;
  };

  # Perfis adicionais herdados
  kryonix.profiles.dev.enable = true;
  kryonix.profiles.university.enable = true;
  kryonix.profiles.ti.enable = true;

  kernelZen = {
    enable = true;

    kernel = "zen";
    forceLocalBuild = true;
    useLLVMStdenv = true;
    extraMakeFlags = [ ];

    # ⚠️ só recomendo isso se for desktop single-user.
    disableMitigations = lib.mkDefault false;

    # Removido: parâmetros agressivos do scheduler podem causar travamentos
    # O kernel Zen já vem otimizado para desktop
    extraKernelParams = [ ];
  };
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

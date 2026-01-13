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

    # Base do sistema
    "${nixosModules}/common"

    # Desktop
    "${nixosModules}/desktop/kde"

    # Kernel e virtualização
    ../../modules/kernel/zen.nix
    ../../modules/virtualization/kvm.nix
  ];

  networking.hostName = hostname;

  # UniFi Network Application (Controller)
  services.unifi = {
    enable = true;
    openFirewall = true;
  };

  system.stateVersion = "25.11";

  ## -------------------------
  ## Boot / Kernel
  ## -------------------------
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    # Kernel params globais
    kernelParams = [
      "rootflags=subvol=@,compress=zstd,noatime"
    ];

    # Evita builds inúteis
    initrd.systemd.enable = true;
  };

  ## -------------------------
  ## Kernel Zen (ajustado)
  ## -------------------------
  kernelZen = {
    enable = true;

    kernel = "xanmod";
    forceLocalBuild = true;

    # ⚠️ só recomendo isso se for desktop single-user
    disableMitigations = lib.mkDefault false;

    extraKernelParams = [
      "sched_latency_ns=4000000"
      "sched_min_granularity_ns=500000"
    ];
  };

  ## -------------------------
  ## Filesystem (Btrfs)
  ## -------------------------
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a551eedc-61b1-458b-8d4d-99e7ddcc0b1a";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd"
      "noatime"
      "ssd"
      "space_cache=v2"
    ];
  };

  ## -------------------------
  ## Performance básica
  ## -------------------------
  powerManagement.cpuFreqGovernor = "performance";

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
}

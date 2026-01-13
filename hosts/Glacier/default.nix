{
  inputs,
  hostname,
  nixosModules,
  config,
  lib,
  ...
}:
{
  imports = [
    # Hardware
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-nvidia
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

      # AMD / performance (espelha /etc/nixos)
      "amd_pstate=active"
      "processor.max_cstate=5"
      "idle=nomwait"
      "threadirqs"

      # NVIDIA (espelha /etc/nixos)
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];

    # Evita builds inúteis
    initrd.systemd.enable = true;
  };

  ## -------------------------
  ## NVIDIA (RTX 4060)
  ## -------------------------
  services.xserver.enable = lib.mkDefault true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;
    powerManagement.enable = lib.mkDefault true;
    nvidiaSettings = lib.mkDefault true;

    # Maximiza compat/perf no NixOS: mantém driver sempre alinhado ao kernel atual.
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.latest;

    # Mantém o driver carregado e reduz custo/oscilações ao abrir jogos.
    nvidiaPersistenced = lib.mkDefault true;

    # Obrigatório em drivers >= 560 (configurado explicitamente)
    open = lib.mkDefault false;

    # O nixos-hardware pode habilitar PRIME por padrão; no desktop, desabilitamos.
    prime.offload.enable = lib.mkForce false;
    prime.offload.enableOffloadCmd = lib.mkForce false;
    prime.sync.enable = lib.mkForce false;
  };

  ## -------------------------
  ## Kernel Zen (ajustado)
  ## -------------------------
  kernelZen = {
    enable = true;

    kernel = "xanmod";
    forceLocalBuild = true;

    # ⚠️ só recomendo isso se for desktop single-user
    disableMitigations = lib.mkDefault true;

    extraKernelParams = [
      "sched_latency_ns=4000000"
      "sched_min_granularity_ns=500000"
    ];
  };

  ## -------------------------
  ## Performance básica
  ## -------------------------
  powerManagement.cpuFreqGovernor = "performance";

  # No /etc/nixos você usa power-profiles-daemon; o módulo TLP desabilita.
  services.power-profiles-daemon.enable = lib.mkForce true;

  # Evita conflito: o módulo comum habilita TLP por padrão.
  services.tlp.enable = lib.mkForce false;

  # No /etc/nixos está habilitado.
  services.printing.enable = lib.mkForce true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
  '';

}

# ==============================================================================
# Módulo: Host Glacier
# Autor: rag
#
# O que é:
# - Configuração NixOS específica do host `glacier`.
# - Declara hardware AMD + NVIDIA RTX 4060 e ajustes desktop.
#
# Por quê:
# - Isola completamente o stack NVIDIA deste host sem afetar o Inspiron.
# - Mantém Wayland funcional com DRM modeset e UWSM.
#
# Como:
# - Importa hardware local e módulos comuns.
# - Declara drivers NVIDIA, variáveis Wayland/NVIDIA e boot EFI/GRUB.
#
# Riscos:
# - Atualizações de driver NVIDIA/kernel podem exigir validação extra no Wayland.
# ==============================================================================
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
    # Hardware AMD  (nixos-hardware)
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-cpu-amd-pstate
    inputs.hardware.nixosModules.common-gpu-nvidia

    ./hardware-configuration.nix

    # Disko fica reservado para provisionamento/instalação.
    # Este host já está instalado e usa os mounts reais em
    # `hardware-configuration.nix`.

    # Kernel e rede
    ../../modules/kernel/zen.nix
    ../../modules/virtualization/net-ragthink.nix

  ];

  # =========================
  # RagOS Options (v2)
  # =========================

  rag.hardware.openrgb.enable = true;

  rag.desktop.environment = "hyprland";
  rag.features.dms.enable = true;

  rag.profiles.dev.enable = true;
  rag.profiles.university.enable = true;
  rag.profiles.ti.enable = true;

  rag.features.gaming = {
    enable = true;
    steam.gamescope = true;
    performanceGovernor = true;
  };

  rag.features.development = {
    enable = true;
    languages = {
      nix.enable = true;
      python.enable = true;
      javascript.enable = true;
      rust.enable = true;
      c.enable = true;
      java.enable = true;
      go.enable = true;
    };
    tools = {
      kubernetes.enable = true;
      terraform.enable = true;
      ansible.enable = true;
      wine.enable = true;
    };
  };

  networking.hostName = hostname;

  programs.winbox.enable = true;

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
        efiInstallAsRemovable = true;
      };
      efi = {
        canTouchEfiVariables = lib.mkForce false;
        efiSysMountPoint = "/boot";
      };
    };

    # NVIDIA DRM modesetting — OBRIGATÓRIO para Wayland
    kernelParams = [
      "rootflags=subvol=@,compress=zstd,noatime"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1" # framebuffer para TTY
      "amd_pstate=active" # P-State activo (Zen 5)
    ];

    # Módulos carregados no initrd (necessário para DRM early)
    initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
    kernelModules = [ "kvm-amd" ];

    initrd.systemd.enable = true;

    extraModprobeConfig = ''
      options kvm_amd nested=1
      options nvidia NVreg_PreserveVideoMemoryAllocations=1
    '';

    blacklistedKernelModules = [ "nouveau" ];
  };

  # =========================
  # NVIDIA RTX 4060
  # =========================
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # DRM kernel mode setting — essencial para Wayland
    modesetting.enable = true;

    # Host usa RTX 4060 como GPU principal (sem PRIME híbrido).
    prime = {
      offload.enable = lib.mkForce false;
      sync.enable = lib.mkForce false;
      reverseSync.enable = lib.mkForce false;
    };

    # Gerenciamento de energia (desktop = sem finegrained)
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Usa driver proprietário da NVIDIA para compatibilidade máxima
    open = false;

    # Painel de controle NVIDIA
    nvidiaSettings = true;
    nvidiaPersistenced = true;

    # Driver estável (use .beta ou .production se precisar de features específicas)
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Hardware acceleration (NVIDIA VA-API via libva-nvidia-driver)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # NVIDIA VA-API (necessário para Firefox HW accel, etc.)
      nvidia-vaapi-driver
      # Vulkan
      vulkan-loader
      vulkan-validation-layers
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
    ];
  };

  # =========================
  # Variáveis de sessão — mínimas e compatíveis com Wayland + NVIDIA
  # =========================
  environment.sessionVariables = {
    GDK_BACKEND = "wayland,x11,*";
    QT_QPA_PLATFORM = "wayland;xcb";
    CLUTTER_BACKEND = "wayland";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GL_VRR_ALLOWED = "1";
    __GL_GSYNC_ALLOWED = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "0";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # =========================
  # Kernel Zen
  # =========================
  kernelZen = {
    enable = true;
    kernel = "zen";
    forceLocalBuild = true;
    useLLVMStdenv = true;
    extraMakeFlags = [ ];
    disableMitigations = lib.mkDefault false;
    extraKernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "kvm.ignore_msrs=1"
      "threadirqs"
    ];
  };

  # Desktop gaming: preferimos performance constante no host dedicado.
  # Evita deixar o governor fixo disputando com o power-profiles-daemon.
  powerManagement.cpuFreqGovernor = lib.mkForce "performance";

  services.power-profiles-daemon.enable = lib.mkForce false;
  services.tlp.enable = lib.mkForce false;

  services.flatpak.enable = lib.mkForce false;
  services.flatpak.packages = lib.mkForce [ ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
  '';

  # =========================
  # RagOS
  # =========================
  ragos = {
    enable = true;
    prettyName = "RagOS";
    versionId = "26.05";
  };

  # =========================
  # Tailscale
  # =========================
  services.rag.tailscale = {
    enable = true;
    autoconnect = true;
    authKeyFile = /root/tailscale-authkey.secret;
  };
}

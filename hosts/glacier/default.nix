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
  nixosModules,
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

    # Base do sistema
    "${nixosModules}/common"

    # Kernel e rede
    ../../modules/kernel/zen.nix
    ../../modules/virtualization/net-ragthink.nix

    # Branding
    "${nixosModules}/branding/ragos"
  ];

  # =========================
  # RagOS Options (v2)
  # =========================

  rag.hardware.openrgb.enable = false;

  rag.desktop.environment = "hyprland";

  services.displayManager.sddm.enable = lib.mkForce false;

  rag.profiles.laptop.enable = false;

  rag.features.development = {
    enable = true;
    languages = {
      nix.enable        = true;
      python.enable     = true;
      javascript.enable = true;
      rust.enable       = true;
      c.enable          = true;
    };
    tools.kubernetes.enable = true;
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
        enable     = true;
        efiSupport = true;
        device     = "nodev";
        useOSProber = false;
        efiInstallAsRemovable = true;
      };
      efi = {
        canTouchEfiVariables = lib.mkForce false;
        efiSysMountPoint     = "/boot";
      };
    };

    # NVIDIA DRM modesetting — OBRIGATÓRIO para Wayland
    kernelParams = [
      "rootflags=subvol=@,compress=zstd,noatime"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"     # framebuffer para TTY
      "amd_pstate=active"      # P-State activo (Zen 5)
    ];

    # Módulos carregados no initrd (necessário para DRM early)
    initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    kernelModules = [ "kvm-amd" ];

    initrd.systemd.enable = true;

    extraModprobeConfig = ''
      options kvm_amd nested=1
      options nvidia NVreg_PreserveVideoMemoryAllocations=1
    '';
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
    powerManagement.enable  = false;
    powerManagement.finegrained = false;

    # Usa driver proprietário da NVIDIA para compatibilidade máxima
    open = false;

    # Painel de controle NVIDIA
    nvidiaSettings = true;

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
  # Variáveis de sessão — Override das defaults Intel do desktop/hyprland/system.nix
  # =========================
  environment.sessionVariables = lib.mkForce {
    # Wayland nativo para toolkits
    GDK_BACKEND         = "wayland,x11,*";
    QT_QPA_PLATFORM     = "wayland;xcb";
    SDL_VIDEODRIVER     = "wayland";
    CLUTTER_BACKEND     = "wayland";
    # XDG
    XDG_SESSION_TYPE    = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    # NVIDIA Wayland
    LIBVA_DRIVER_NAME           = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME   = "nvidia";
    GBM_BACKEND                 = "nvidia-drm";
    __NV_PRIME_RENDER_OFFLOAD   = "0";   # GPU única, sem PRIME
    __GL_VRR_ALLOWED            = "1";
    __GL_GSYNC_ALLOWED          = "1";
    # Evita fallback silencioso para software renderer.
    WLR_RENDERER_ALLOW_SOFTWARE = "0";
    # Electron / Chromium
    NIXOS_OZONE_WL      = "1";
    # Qt extras
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };

  # =========================
  # Kernel Zen
  # =========================
  kernelZen = {
    enable = true;
    kernel = "zen";
    forceLocalBuild = false;
    useLLVMStdenv   = false;
    extraMakeFlags  = [ ];
    disableMitigations = lib.mkDefault false;
    extraKernelParams  = [
      "amd_iommu=on"
      "iommu=pt"
      "kvm.ignore_msrs=1"
      "threadirqs"
    ];
  };

  # Performance desktop (AMD não precisa de schedutil como laptop)
  powerManagement.cpuFreqGovernor = lib.mkForce "performance";

  services.power-profiles-daemon.enable = lib.mkForce true;
  services.tlp.enable                   = lib.mkForce false;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
  '';

  # =========================
  # RagOS
  # =========================
  ragos = {
    enable     = true;
    prettyName = "RagOS";
    versionId  = "26.05";
  };

  # =========================
  # Tailscale
  # =========================
  services.rag.tailscale = {
    enable      = true;
    autoconnect = true;
    authKeyFile = /root/tailscale-authkey.secret;
  };
}

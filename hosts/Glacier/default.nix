# Host: Glacier (NixOS)
# Autor: rag
#
# O que é
# - Configuração do sistema para a máquina Glacier (imports + ajustes específicos do host).
#
# Por quê
# - Mantém o host “fino”: só hardware/host-specific e imports de módulos reutilizáveis.
# - Facilita replicar/alterar comportamento sem duplicar lógica.
#
# Como
# - Importa nixos-hardware + hardware-configuration.
# - Importa módulos comuns do repo (common/desktop/kernel/virtualização).
#
# Riscos
# - Parâmetros de kernel e drivers (NVIDIA/AMD) são sensíveis: mudanças podem afetar boot e Wayland.
{
  inputs,
  hostname,
  nixosModules,
  config,
  lib,
  pkgs,
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

  # Wake-on-LAN: permite acordar/ligar via "magic packet" (ex.: Alexa/bridge WOL).
  # Requisitos fora do Nix:
  # - BIOS/UEFI: WOL habilitado
  # - Placa/driver suportar WOL no estado S5 (varia por hardware)
  networking.interfaces.enp6s0.wakeOnLan.enable = true;

  system.stateVersion = "26.05";

  # =========================
  # Boot / Kernel
  # =========================
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    # Kernel params globais.
    kernelParams = [
      "rootflags=subvol=@,compress=zstd,noatime"

      # AMD / performance (espelha /etc/nixos).
      "amd_pstate=active"
      "processor.max_cstate=5"
      "idle=nomwait"
      "threadirqs"

      # NVIDIA (espelha /etc/nixos).
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

      # Jogos (ex: Hogwarts Legacy) podem disparar muitos bus locks e, com
      # split lock detection ativa, isso vira uma enxurrada de traps (#DB)
      # que degrada performance e parece "travamento".
      "split_lock_detect=off"
    ];

    # Evita builds inúteis
    initrd.systemd.enable = true;
  };

  # =========================
  # NVIDIA (RTX 4060)
  # =========================
  services.xserver.enable = lib.mkDefault true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;
    powerManagement.enable = lib.mkDefault true;
    nvidiaSettings = lib.mkDefault true;

    # Estabilidade (KDE Wayland): o ramo `latest` costuma trazer regressões no EGL
    # (vimos coredumps do kwin_wayland/plasmashell em libnvidia-eglcore/libEGL_nvidia).
    # O ramo `production` tende a ser mais estável para desktop.
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.production;

    # Mantém o driver carregado e reduz custo/oscilações ao abrir jogos.
    nvidiaPersistenced = lib.mkDefault true;

    # Obrigatório em drivers >= 560 (configurado explicitamente)
    open = lib.mkDefault false;

    # O nixos-hardware pode habilitar PRIME por padrão; no desktop, desabilitamos.
    prime.offload.enable = lib.mkForce false;
    prime.offload.enableOffloadCmd = lib.mkForce false;
    prime.sync.enable = lib.mkForce false;
  };

  # O nvidia-persistenced às vezes é reiniciado durante `nixos-rebuild switch`.
  # Dependendo do timing, ele pode subir antes dos nodes `/dev/nvidia*` existirem,
  # falhar, e isso faz o switch abortar.
  systemd.services.nvidia-persistenced = {
    after = [ "systemd-udev-settle.service" ];
    wants = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      RuntimeDirectory = "nvidia-persistenced";
      RuntimeDirectoryMode = "0755";
      ExecStartPre = [
        # Espera (até ~5s) pelos device nodes do driver NVIDIA.
        "${pkgs.runtimeShell} -lc 'for i in $(seq 1 50); do [ -e /dev/nvidiactl ] && [ -e /dev/nvidia0 ] && exit 0; sleep 0.1; done; exit 1'"
      ];
    };
  };

  ## -------------------------
  ## Kernel Zen (ajustado)
  ## -------------------------
  kernelZen = {
    enable = true;

    kernel = "zen";
    forceLocalBuild = false;
    useLLVMStdenv = false;
    extraMakeFlags = [ ];

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

  # Gaming/stabilidade: evita serviços que brigam por perfil de energia.
  services.power-profiles-daemon.enable = lib.mkForce false;

  # Evita conflito: o módulo comum habilita TLP por padrão.
  services.tlp.enable = lib.mkForce false;

  # No /etc/nixos está habilitado.
  services.printing.enable = lib.mkForce true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme*", ATTR{queue/scheduler}="none"
  '';

  services.flatpak.packages = lib.mkAfter [
    "org.freedesktop.Platform.GL.nvidia-580-119-02"
    "org.freedesktop.Platform.GL32.nvidia-580-119-02"
  ];

  # =========================
  # Tailscale VPN
  # =========================
  services.rag.tailscale.enable = true;
}

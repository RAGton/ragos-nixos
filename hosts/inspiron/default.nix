# ==============================================================================
# Módulo: Host Inspiron
# Autor: rag
#
# O que é:
# - Configuração NixOS específica do host `inspiron`.
# - Declara hardware Intel e ajustes de laptop.
#
# Por quê:
# - Mantém separação estrita de hardware por host (sem drivers globais).
# - Facilita manutenção sem impactar outros hosts.
#
# Como:
# - Importa `hardware-configuration.nix` e módulos comuns.
# - Declara stack gráfico Intel localmente neste host.
#
# Riscos:
# - Alterações em boot/kernel/power podem afetar estabilidade e bateria.
# ==============================================================================
{
  inputs,
  hostname,
  nixosModules,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Hardware
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-gpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix

    # Disko (particionamento declarativo — usado pelo Live CD)
    inputs.disko.nixosModules.disko
    ./disks.nix

    # Base do sistema
    "${nixosModules}/common"

    # Desktop: gerenciado via opção (v2 migration)
    # Features: gerenciadas via opções (v2 migration)

    # Kernel e rede
    ../../modules/kernel/zen.nix
    ../../modules/virtualization/net-ragthink.nix

    # Branding (RagOS)
    "${nixosModules}/branding/ragos"
  ];

  # =========================
  # RagOS Options (v2)
  # =========================

  # Hardware toggles
  rag.hardware.openrgb.enable = false;

  # Desktop

  # Hyprland (via GDM; lockscreen via DMS)
  rag.desktop.environment = "hyprland";
  rag.desktop.directLogin.enable = false;


  # Profile (v2)
  rag.profiles.laptop = {
    enable = true;

    # Mantém o comportamento atual do inspiron
    virtualization = {
      enable = true;
      docker.enable = true;
      libvirt.enable = true;
    };

    development.enable = true;

    # Gaming permanece desligado no laptop
    gaming.enable = false;
  };

  # Ajustes específicos além do profile
  rag.features.development = {
    languages = {
      nix.enable = true;
      python.enable = true;
      javascript.enable = true;
      rust.enable = true;
      c.enable = true;
    };
    tools.kubernetes.enable = true;
  };

  # Codex (AI): desligado por padrão (evita builds lentos).
  # Para ativar quando quiser: mude para `true`.
  rag.features.ai.codex.enable = false;

  networking.hostName = hostname;

  # =========================
  # MikroTik Winbox
  # =========================
  # O que é
  # - Habilita o Winbox (GUI de gerenciamento MikroTik).
  #
  # Por quê
  # - Facilita administrar RouterOS/SwOS direto do desktop.
  #
  # Como
  # - `programs.winbox.enable = true` instala o Winbox.
  programs.winbox.enable = true;

  # UniFi Network Application (Controller).
  # services.unifi = {
  #   enable = true;
  #   openFirewall = true;
  # };

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
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    # Kernel params globais.
    kernelParams = [
      "rootflags=subvol=@,compress=zstd,noatime"
    ];

    # Evita builds inúteis
    initrd.systemd.enable = true;
  };

  # =========================
  # Kernel Zen (ajustado)
  # =========================
  kernelZen = {
    enable = true;

    kernel = "zen";
    forceLocalBuild = false;
    useLLVMStdenv = false;
    extraMakeFlags = [ ];

    # ⚠️ só recomendo isso se for desktop single-user.
    disableMitigations = lib.mkDefault false;

    # Removido: parâmetros agressivos do scheduler podem causar travamentos
    # O kernel Zen já vem otimizado para desktop
    extraKernelParams = [ ];
  };

  # =========================
  # Intel iGPU (Inspiron)
  # =========================
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver   # VA-API iHD (Broadwell+)
      libvdpau-va-gl       # VDPAU via VA-API
      intel-vaapi-driver   # fallback VA-API i965 (pre-Broadwell)
    ];
  };

  environment.sessionVariables = {
    # Mesa / OpenGL (Intel)
    MESA_LOADER_DRIVER_OVERRIDE = "iris";
    LIBVA_DRIVER_NAME = "iHD";
    # Evita fallback silencioso para software renderer (llvmpipe).
    WLR_RENDERER_ALLOW_SOFTWARE = "0";
  };

  ## -------------------------
  ## Performance básica
  ## -------------------------
  # Em laptop, `schedutil` costuma equilibrar performance e bateria melhor que `performance`.
  powerManagement.cpuFreqGovernor = lib.mkForce "schedutil";

  services.power-profiles-daemon.enable = lib.mkForce true;
  services.tlp.enable = lib.mkForce false;

  # Flatpak: mantém a lista comum vinda do módulo shared.
  # (Removemos as extensões NVIDIA do common.)

  # Gaming/estabilidade: evita serviços que brigam por perfil de energia.
  # (PPD já está habilitado acima; mantemos apenas TLP desligado.)

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

  # =========================
  # RagOS (branding do sistema)
  # =========================
  # Mantém o mesmo número de versão do seu `system.stateVersion` para exibição.
  # Obs.: `system.stateVersion` continua sendo a chave de compat do NixOS.
  ragos = {
    enable = true;
    prettyName = "RagOS";
    versionId = "26.05";
  };

  # =========================
  # Tailscale VPN
  # =========================
  services.rag.tailscale = {
    enable = true;
    autoconnect = true;
    authKeyFile = /root/tailscale-authkey.secret;
  };

  # Codex (AI): opt-in via feature pra evitar builds lentos por padrão.
  # Para ativar: rag.features.ai.codex.enable = true;
}

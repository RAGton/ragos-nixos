# =============================================================================
# Feature: Gaming Stack
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Configuração completa para gaming no NixOS
# - Steam, Lutris, GameMode, optimizações de performance
#
# Por quê:
# - Centraliza toda configuração de gaming em um módulo
# - Ativa/desativa facilmente: rag.features.gaming.enable = true
# - Mantém hosts limpos
#
# Como usar:
# No host: rag.features.gaming.enable = true;
#
# Riscos:
# - Configurações de kernel/drivers são hardware-specific
# - Validar após habilitar em novo hardware
# =============================================================================
{ config, lib, pkgs, ... }:

let
  cfg = config.rag.features.gaming;

in
{
  options.rag.features.gaming = {
    enable = lib.mkEnableOption "Gaming stack (Steam, Lutris, GameMode, etc)";

    steam = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Steam";
      };

      gamescope = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable GameScope (micro-compositor for games)";
      };
    };

    lutris = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Lutris";
      };
    };

    heroic = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Heroic Games Launcher (Epic/GOG)";
      };
    };

    gamemode = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable GameMode (performance optimizations)";
      };
    };

    mangohud = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable MangoHud (FPS overlay)";
      };
    };

    sunshine = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Sunshine (game streaming server)";
      };
    };

    performanceGovernor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set CPU governor to performance mode when gaming";
    };
  };

  config = lib.mkIf cfg.enable {
    # =========================
    # Steam
    # =========================
    programs.steam = lib.mkIf cfg.steam.enable {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;

      # GameScope integration
      gamescopeSession.enable = cfg.steam.gamescope;

      # Extra compatibility tools
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    # =========================
    # GameMode
    # =========================
    programs.gamemode = lib.mkIf cfg.gamemode.enable {
      enable = true;

      settings = {
        general = {
          renice = 10;
        };

        # CPU optimizations
        cpu = {
          park_cores = "no";
          pin_cores = "yes";
        };

        # GPU optimizations
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
      };
    };

    # =========================
    # System Packages
    # =========================
    environment.systemPackages = with pkgs; lib.flatten [
      # MangoHud
      (lib.optional cfg.mangohud.enable mangohud)

      # Launchers
      (lib.optional cfg.lutris.enable lutris)
      (lib.optional cfg.heroic.enable heroic)

      # Game streaming
      (lib.optional cfg.sunshine.enable sunshine)
      moonlight-qt  # Client para game streaming

      # Utilities
      gamemode
      gamescope

      # Emulators (basic set)
      # (lib.optional cfg.emulators.enable [
      #   retroarch
      #   pcsx2
      #   rpcs3
      # ])
    ];

    # =========================
    # Performance Optimizations
    # =========================

    # CPU Governor
    powerManagement.cpuFreqGovernor = lib.mkIf cfg.performanceGovernor "performance";

    # Kernel parameters (gaming-friendly)
    boot.kernel.sysctl = {
      # Increase inotify watches (helps with large game libraries)
      "fs.inotify.max_user_watches" = 524288;

      # Network optimizations for online gaming
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";

      # Reduce swappiness (prefer RAM for games)
      "vm.swappiness" = 10;
    };

    # =========================
    # Graphics
    # =========================

    # OpenGL/Vulkan support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;  # For 32-bit games

      extraPackages = with pkgs; [
        # Vulkan
        vulkan-loader
        vulkan-validation-layers
        vulkan-tools

        # VAAPI (video acceleration)
        libvdpau-va-gl
        libva-vdpau-driver
      ];

      extraPackages32 = with pkgs.pkgsi686Linux; [
        vulkan-loader
      ];
    };

    # =========================
    # Firewall (game streaming)
    # =========================
    networking.firewall = lib.mkIf cfg.sunshine.enable {
      allowedTCPPorts = [ 47984 47989 48010 ];
      allowedUDPPorts = [ 47998 47999 48000 48010 ];
    };

    # =========================
    # Udev Rules
    # =========================
    services.udev.extraRules = ''
      # PlayStation Controllers
      SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", MODE="0666"

      # Xbox Controllers
      SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", MODE="0666"

      # Nintendo Switch Pro Controller
      SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", MODE="0666"
    '';

    # =========================
    # Assertions
    # =========================
    assertions = [
      {
        assertion = cfg.steam.gamescope -> cfg.steam.enable;
        message = "GameScope requires Steam to be enabled";
      }
    ];
  };
}


# =============================================================================
# Profile: laptop
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Preset composável para máquinas laptop.
# - Ajusta features e defaults com foco em mobilidade (bateria/ruído) e dev.
#
# Por quê:
# - Evita repetir configurações e escolhas padrão em múltiplos laptops.
# - Mantém hosts finos e coerentes.
#
# Como usar (no host):
#   rag.profiles.laptop.enable = true;
#
# Importante:
# - Este profile NÃO escolhe desktop environment.
# - O desktop continua sendo escolhido via `rag.desktop.environment`.
# =============================================================================
{ config, lib, ... }:

let
  cfg = config.rag.profiles.laptop;

in
{
  options.rag.profiles.laptop = {
    enable = lib.mkEnableOption "Laptop profile (dev + virtualization defaults; no gaming by default)";

    virtualization = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable virtualization feature as part of the laptop profile";
      };

      docker = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Docker when virtualization is enabled";
        };
      };

      libvirt = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable libvirt/KVM on laptops (off by default to save resources)";
        };
      };
    };

    development = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable development feature as part of the laptop profile";
      };
    };

    gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable gaming feature as part of the laptop profile (off by default)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    rag.features = {
      development.enable = lib.mkDefault cfg.development.enable;

      virtualization = {
        enable = lib.mkDefault cfg.virtualization.enable;
        docker.enable = lib.mkDefault cfg.virtualization.docker.enable;

        # Defaults laptop-friendly
        kvm.enable = lib.mkDefault cfg.virtualization.libvirt.enable;
        libvirt.enable = lib.mkDefault cfg.virtualization.libvirt.enable;
      };

      gaming.enable = lib.mkDefault cfg.gaming.enable;
    };
  };
}


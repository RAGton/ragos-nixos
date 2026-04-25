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
#   kryonix.profiles.laptop.enable = true;
#
# Importante:
# - Este profile NÃO escolhe desktop environment.
# - O desktop continua sendo escolhido via `kryonix.desktop.environment`.
# =============================================================================
{ config, lib, ... }:

let
  cfg = config.kryonix.profiles.laptop;

in
{
  options.kryonix.profiles.laptop = {
    enable = lib.mkEnableOption "Perfil laptop (dev + virtualização padrão; sem gaming por padrão)";

    virtualization = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Habilita a feature virtualização como parte do perfil laptop";
      };

      docker = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Habilita Docker quando a virtualização está ativada";
        };
      };

      podman = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Habilita Podman quando a virtualização está ativada";
        };
      };

      libvirt = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Habilita libvirt/KVM em laptops (desligado por padrão para economizar recursos)";
        };
      };
    };

    development = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Habilita a feature desenvolvimento como parte do perfil laptop";
      };
    };

    gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Habilita a feature gaming como parte do perfil laptop (desligado por padrão)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    kryonix.features = {
      development.enable = lib.mkDefault cfg.development.enable;

      virtualization = {
        enable = lib.mkDefault cfg.virtualization.enable;
        docker.enable = lib.mkDefault cfg.virtualization.docker.enable;
        podman.enable = lib.mkDefault cfg.virtualization.podman.enable;

        # Defaults laptop-friendly
        kvm.enable = lib.mkDefault cfg.virtualization.libvirt.enable;
        libvirt.enable = lib.mkDefault cfg.virtualization.libvirt.enable;
      };

      gaming.enable = lib.mkDefault cfg.gaming.enable;
    };
  };
}

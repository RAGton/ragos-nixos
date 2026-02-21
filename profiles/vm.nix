# =============================================================================
# Profile: vm
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Preset composável para máquinas virtuais (VMs).
# - Foco em simplicidade, build rápido e footprint pequeno.
#
# Por quê:
# - Evita carregar stacks pesadas (gaming, libvirt host, etc.) em VMs.
# - Mantém hosts VM consistentes.
#
# Como usar (no host):
#   rag.profiles.vm.enable = true;
#
# Importante:
# - Este profile NÃO escolhe desktop environment.
# - O desktop continua sendo escolhido via `rag.desktop.environment`.
# =============================================================================
{ config, lib, ... }:

let
  cfg = config.rag.profiles.vm;

in
{
  options.rag.profiles.vm = {
    enable = lib.mkEnableOption "Perfil VM (defaults com footprint reduzido)";

    development = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Habilita a feature desenvolvimento como parte do perfil VM";
      };
    };

    virtualization = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Habilita virtualização de containers (Docker/Podman) no perfil VM";
      };

      docker = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Habilita Docker quando a virtualização está ativada";
        };
      };

      # VM normalmente não deve hospedar libvirtd/kvm, a menos que você queira nested virt.
      libvirt = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Habilita KVM/libvirt no perfil VM (virtualização aninhada)";
        };
      };
    };

    gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Habilita gaming no perfil VM (desligado por padrão)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Defaults enxutos
    rag.features = {
      development.enable = lib.mkDefault cfg.development.enable;

      virtualization = {
        enable = lib.mkDefault cfg.virtualization.enable;
        docker.enable = lib.mkDefault cfg.virtualization.docker.enable;

        kvm.enable = lib.mkDefault cfg.virtualization.libvirt.enable;
        libvirt.enable = lib.mkDefault cfg.virtualization.libvirt.enable;
      };

      gaming.enable = lib.mkDefault cfg.gaming.enable;
    };
  };
}


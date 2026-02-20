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
    enable = lib.mkEnableOption "VM profile (small footprint defaults)";

    development = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable development feature as part of VM profile";
      };
    };

    virtualization = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable container virtualization (Docker/Podman) in VM profile";
      };

      docker = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Docker when virtualization is enabled";
        };
      };

      # VM normalmente não deve hospedar libvirtd/kvm, a menos que você queira nested virt.
      libvirt = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable KVM/libvirt in VM profile (nested virtualization)";
        };
      };
    };

    gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable gaming in VM profile (off by default)";
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


/*
  Autor: RAGton
  Descrição: Módulo NixOS para habilitar virtualização KVM/QEMU/libvirt
             com IOMMU, virt-manager e boas práticas.
*/

{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}:

let
  cfg = config.virtualisation.kvm;
in
{
  options.virtualisation.kvm = {
    enable = lib.mkEnableOption "Habilita virtualização KVM/QEMU/libvirt";

    libvirtUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ userConfig.name ];
      description = ''
        Usuários adicionados ao grupo libvirtd para acesso ao QEMU/libvirt.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    ############################
    # Virtualização
    ############################
    virtualisation = {
      libvirtd = {
        enable = true;

        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;

          # TPM virtual (Windows 11, Linux moderno)
          swtpm.enable = true;
        };
      };

      spiceUSBRedirection.enable = true;
    };

    ############################
    # Kernel e IOMMU
    ############################
    boot.kernelParams = [
      "iommu=pt" # Melhor performance
      "intel_iommu=on" # Ignorado se não for Intel
      "amd_iommu=on" # Ignorado se não for AMD
    ];

    ############################
    # Usuário e permissões
    ############################
    users.groups.libvirtd.members = cfg.libvirtUsers;

    # A maioria das distros usa `kvm` para acesso a /dev/kvm; no NixOS isso também ajuda.
    users.groups.kvm.members = cfg.libvirtUsers;

    ############################
    # Polkit (virt-manager sem sudo)
    ############################
    security.polkit.enable = true;

    ############################
    # Pacotes úteis
    ############################
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      spice-gtk
      virtio-win
      win-spice

      # Úteis para debug/CLI
      libvirt
      qemu

      # UEFI/OVMF images (quando precisar boot UEFI em VMs)
      OVMF
    ];

    ############################
    # Rede (bridge padrão do libvirt)
    ############################
    networking.firewall.trustedInterfaces = [ "virbr0" ];

    ############################
    # Ajustes extras recomendados
    ############################
    # Evita forçar módulos de CPU errados; cada host define o seu (Intel/AMD).
    boot.kernelModules = lib.mkDefault [ "kvm" ];

    # Apps GUI às vezes não herdam env do shell/Home Manager. Isso padroniza o URI.
    environment.sessionVariables.LIBVIRT_DEFAULT_URI = lib.mkDefault "qemu:///system";
  };
}

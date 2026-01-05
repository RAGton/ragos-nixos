/*
 Autor: RAGton
 Descrição: Módulo NixOS para habilitar virtualização KVM/QEMU/libvirt
            com IOMMU, virt-manager e boas práticas.
*/

{ config, pkgs, lib, ... }:

{
  ############################
  # Virtualização
  ############################
  virtualisation = {
    libvirtd = {
      enable = true;

      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;

        # UEFI + Secure Boot (necessário para Windows moderno)
        # ovmf is now enabled by default
        swtpm.enable = true; # TPM virtual (Windows 11, Linux moderno)
      };
    };

    spiceUSBRedirection.enable = true;
  };

  ############################
  # Kernel e IOMMU
  ############################
  boot.kernelParams = [
    "iommu=pt"          # Melhor performance
    "intel_iommu=on"    # Ignorado se não for Intel
    "amd_iommu=on"      # Ignorado se não for AMD
  ];

  ############################
  # Usuário e permissões
  ############################
  users.groups.libvirtd.members = [
    "rag"   # 🔴 ajuste para seu usuário real
  ];

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
  ];

  ############################
  # Rede (bridge padrão do libvirt)
  ############################
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  ############################
  # Ajustes extras recomendados
  ############################
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
}
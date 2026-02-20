# Home Manager: virt-manager (apenas UX do cliente)
# - Não instala pacotes do sistema (isso fica no módulo NixOS de KVM/libvirt).
# - Ajusta o default de conexão do virt-manager para `qemu:///system`.
{
  pkgs,
  lib,
  ...
}:
{
  dconf.settings = lib.mkIf pkgs.stdenv.isLinux {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}


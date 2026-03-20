# ==============================================================================
# Profile: ti
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Toolkit para operações de TI/Sysadmin e troubleshooting de infraestrutura.
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.rag.profiles.ti;
in {
  options.rag.profiles.ti.enable = lib.mkEnableOption "Perfil TI/Sysadmin";

  config = lib.mkIf cfg.enable {
    programs.wireshark.enable = true;

    environment.systemPackages = with pkgs; [
      nmap
      tcpdump
      dig
      traceroute
      virt-manager
      qemu
    ];
  };
}

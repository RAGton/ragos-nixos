{
  lib,
  pkgs,
  ...
}:
{
  # Módulo NixOS: Steam (nível do sistema)
  # Autor: rag
  #
  # O que é
  # - Habilita Steam e integrações (firewall para Remote Play/transferências, hardware support).
  #
  # Por quê
  # - Deixa Steam/Proton prontos sem configuração manual após rebuild.
  #
  # Como
  # - `programs.steam.*` + `hardware.steam-hardware.enable`.
  #
  # Riscos
  # - Abrir portas no firewall aumenta superfície de rede; manter apenas o necessário.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    extraCompatPackages =
      lib.optional (pkgs ? proton-ge-bin) pkgs.proton-ge-bin;
  };

  hardware.steam-hardware.enable = true;
}

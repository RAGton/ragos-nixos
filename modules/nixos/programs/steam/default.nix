{
  lib,
  pkgs,
  ...
}:
{
  # Configuração do Steam (nível do sistema)
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

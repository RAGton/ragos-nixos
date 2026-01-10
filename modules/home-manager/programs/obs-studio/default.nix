{
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    # Instala o OBS Studio via módulo do Home Manager
    programs.obs-studio.enable = true;

    # Habilita o tema Catppuccin para o OBS.
    catppuccin.obs.enable = true;
  };
}

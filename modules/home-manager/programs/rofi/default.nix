# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar e configurar o `rofi`.
#
# Por quê:
# - Os menus auxiliares de clipboard/janelas continuam usando `rofi`, então o
#   visual precisa acompanhar o shell atual em vez do tema padrão do nixpkgs.
#
# Como:
# - Habilita `programs.rofi` apenas no Linux.
# - Aponta para um tema local alinhado ao esquema do Caelestia.
# =============================================================================
{
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = ./theme.rasi;
  };
}

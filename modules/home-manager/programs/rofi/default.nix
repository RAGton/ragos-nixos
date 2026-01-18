# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar e configurar o `rofi`.
#
# Por quê:
# - Mantém o tema e o comportamento do launcher declarativos.
# - Facilita trocar tema editando um único arquivo.
#
# Como:
# - Habilita `programs.rofi`.
# - Define `programs.rofi.theme` apontando para `theme.rasi`.
# =============================================================================
{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    # Tema do nixpkgs (vem junto com o rofi):
    #   ${pkgs.rofi-unwrapped}/share/rofi/themes/material.rasi
    theme = "${pkgs.rofi-unwrapped}/share/rofi/themes/material.rasi";
  };
}

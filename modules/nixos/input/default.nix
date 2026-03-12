# ==============================================================================
# Módulo: input (teclado/layout)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Padronização de layout BR-ABNT2 para o stack gráfico.
#
# Por quê:
# - Evita divergências entre hosts no Hyprland e em apps XWayland/X11.
# ==============================================================================
{ lib, ... }:
{
  services.xserver.xkb = {
    layout = lib.mkDefault "br";
    variant = lib.mkDefault "abnt2";
  };

  environment.sessionVariables = {
    XKB_DEFAULT_LAYOUT = "br";
    XKB_DEFAULT_VARIANT = "abnt2";
  };
}

# ==============================================================================
# Módulo: hyprland (compat shim)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-19
#
# O que é:
# - Shim de compatibilidade para imports antigos que esperavam um módulo
#   "hyprland" dedicado.
#
# Por quê:
# - A seleção real de desktop agora mora em `modules/nixos/desktop`.
# - Mantém compatibilidade sem continuar forçando Hyprland em todo o projeto.
# ==============================================================================
{ lib, ... }:
{
  imports = [ ../desktop ];

  config.kryonix.desktop.environment = lib.mkDefault "hyprland";
}

# ==============================================================================
# Feature: DMS (DankMaterialShell)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Feature opt-in para explicitar que a UX padrão usa DMS sobre Hyprland.
#
# Por quê:
# - Mantém a decisão arquitetural visível e centralizada no sistema de features.
# ==============================================================================
{ config, lib, ... }:
let
  cfg = config.rag.features.dms;
in {
  options.rag.features.dms.enable = lib.mkEnableOption "Feature DMS (DankMaterialShell)";

  config = lib.mkIf cfg.enable {
    rag.desktop.environment = lib.mkForce "hyprland";
  };
}

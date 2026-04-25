# ==============================================================================
# Feature: DMS (DankMaterialShell)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Feature opt-in legada para explicitar hosts ainda em DMS sobre Hyprland.
#
# Por quê:
# - Mantém a decisão arquitetural visível e centralizada no sistema de features.
# ==============================================================================
{ config, lib, ... }:
let
  cfg = config.kryonix.features.dms;
in
{
  options.kryonix.features.dms.enable =
    lib.mkEnableOption "Feature legada do DMS (DankMaterialShell)";

  config = lib.mkIf cfg.enable {
    kryonix.desktop.environment = lib.mkForce "hyprland";
  };
}

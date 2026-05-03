# ==============================================================================
# Módulo: hardware (defaults globais)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Ajustes de hardware transversais para todos os hosts.
#
# Por quê:
# - Garante baseline estável (firmware + trim) em laptop/desktop.
# ==============================================================================
{ config, lib, ... }:
{
  config = {
    services.fstrim.enable = lib.mkDefault true;
    hardware.enableRedistributableFirmware = true;
  };
}

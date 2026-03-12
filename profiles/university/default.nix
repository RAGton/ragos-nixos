# ==============================================================================
# Profile: university
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Ferramentas de estudo, produtividade e escrita acadêmica.
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.rag.profiles.university;
in {
  options.rag.profiles.university.enable = lib.mkEnableOption "Perfil universitário";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libreoffice
      zotero
      obsidian
      drawio
      evince
    ];
  };
}

# ==============================================================================
# Profile: dev
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Pacotes-base para fluxo de desenvolvimento diário.
# ==============================================================================
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.kryonix.profiles.dev;
in
{
  options.kryonix.profiles.dev.enable = lib.mkEnableOption "Perfil de desenvolvimento";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gh
      lazygit
      tmux
      podman
      docker-compose
      docker-client
      neovim
    ];
  };
}

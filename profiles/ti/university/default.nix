# ==============================================================================
# Profile: university
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Ferramentas de estudo, produtividade e escrita acadêmica.
# ==============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kryonix.profiles.university;
in
{
  options.kryonix.profiles.university.enable = lib.mkEnableOption "Perfil universitário";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      anki
      appflowy
      calibre
      foliate
      gnome-clocks
      libreoffice
      localsend
      zotero
      obsidian
      thunderbird
      xournalpp
      drawio
      evince
      # Do not add deno/yt-dlp/mpv-with-scripts/kalarm to the base closure:
      # this can pull rusty-v8 and compile V8 locally.
      kdePackages.merkuro
      kdePackages.okular
    ];
  };
}

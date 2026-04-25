# =============================================================================
# Feature: AI tools (opcional)
#
# Objetivo:
# - Evitar builds lentos por padrão (ex.: Codex), mantendo ativação simples.
# - Tudo opt-in via `kryonix.features.ai.*`.
# =============================================================================
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.kryonix.features.ai;
in
{
  options.kryonix.features.ai = {
    codex = {
      enable = lib.mkEnableOption "OpenAI Codex CLI (via flake input inputs.codex)";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.codex.enable {
      environment.systemPackages = [
        inputs.codex.packages.${pkgs.system}.default
      ];
    })
  ];
}

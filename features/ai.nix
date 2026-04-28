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
    brain = {
      enable = lib.mkEnableOption "Kryonix Brain (LightRAG + Ollama)";
      role = lib.mkOption {
        type = lib.types.enum [ "server" "client" "standalone" ];
        default = "standalone";
        description = "Papel do host no ecossistema Brain.";
      };
      serverHost = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Endereço do servidor central.";
      };
      brainPort = lib.mkOption {
        type = lib.types.port;
        default = 8000;
      };
      ollamaPort = lib.mkOption {
        type = lib.types.port;
        default = 11434;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.codex.enable {
      environment.systemPackages = [
        inputs.codex.packages.${pkgs.system}.default
      ];
    })

    (lib.mkIf (cfg.brain.enable && cfg.brain.role == "client") {
      environment.variables = {
        OLLAMA_HOST = "http://${cfg.brain.serverHost}:${toString cfg.brain.ollamaPort}";
        KRYONIX_BRAIN_URL = "http://${cfg.brain.serverHost}:${toString cfg.brain.brainPort}";
        KRYONIX_VAULT_MODE = "remote-readonly";
      };

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "kryonix-search" ''
          set -euo pipefail
          
          # Tenta ler a key do ambiente, se não existir tenta do arquivo env
          API_KEY="''${KRYONIX_BRAIN_KEY:-}"
          if [ -z "$API_KEY" ] && [ -f "/etc/kryonix/brain.env" ]; then
            API_KEY=$(grep KRYONIX_BRAIN_KEY /etc/kryonix/brain.env | cut -d= -f2 | tr -d '"' | tr -d "'")
          fi

          query="''${1:-}"
          if [ -z "$query" ]; then
            echo "Uso: kryonix-search \"pergunta\""
            exit 1
          fi

          if [ -z "$API_KEY" ]; then
            echo "Erro: KRYONIX_BRAIN_KEY não encontrada no ambiente nem em /etc/kryonix/brain.env"
            exit 1
          fi

          ${pkgs.curl}/bin/curl -s -X POST "$KRYONIX_BRAIN_URL/search" \
            -H "Content-Type: application/json" \
            -H "X-API-Key: $API_KEY" \
            -d "{\"query\": \"$query\", \"lang\": \"pt-BR\"}" \
            | ${pkgs.jq}/bin/jq -r '.answer'
        '')

        (pkgs.writeShellScriptBin "kryonix-stats" ''
          API_KEY="''${KRYONIX_BRAIN_KEY:-}"
          if [ -z "$API_KEY" ] && [ -f "/etc/kryonix/brain.env" ]; then
            API_KEY=$(grep KRYONIX_BRAIN_KEY /etc/kryonix/brain.env | cut -d= -f2 | tr -d '"' | tr -d "'")
          fi
          
          if [ -z "$API_KEY" ]; then
            echo "Erro: KRYONIX_BRAIN_KEY não encontrada."
            exit 1
          fi

          ${pkgs.curl}/bin/curl -s -H "X-API-Key: $API_KEY" "$KRYONIX_BRAIN_URL/stats" | ${pkgs.jq}/bin/jq .
        '')
        
        (pkgs.writeShellScriptBin "kryonix-brain-health" ''
          ${pkgs.curl}/bin/curl -s "$KRYONIX_BRAIN_URL/health" | ${pkgs.jq}/bin/jq .
        '')
      ];
    })
  ];
}

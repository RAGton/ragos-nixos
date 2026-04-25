{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.rag.programs.aiWorkstation;

  codexWrapper = pkgs.writeShellApplication {
    name = "codex";
    runtimeInputs = [ pkgs.nodejs_22 ];
    text = ''
      set -euo pipefail
      exec npx --yes @openai/codex "$@"
    '';
  };

  claudeWrapper = pkgs.writeShellApplication {
    name = "claude";
    runtimeInputs = [ pkgs.nodejs_22 ];
    text = ''
      set -euo pipefail
      exec npx --yes @anthropic-ai/claude-code "$@"
    '';
  };

  traeLauncher = pkgs.writeShellApplication {
    name = "trae-launcher";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      for candidate in \
        "''${TRAE_BIN:-}" \
        "$(command -v trae 2>/dev/null || true)" \
        "$HOME/.local/bin/trae" \
        "/opt/trae/trae"; do
        if [ -n "$candidate" ] && [ -x "$candidate" ]; then
          exec "$candidate" "$@"
        fi
      done

      echo "trae-launcher: Trae nao encontrado." >&2
      echo "trae-launcher: instale o .deb/.rpm oficial e exponha o binario em PATH, ~/.local/bin/trae, /opt/trae/trae ou TRAE_BIN." >&2
      exit 1
    '';
  };
in
{
  imports = [ ../obsidian ];

  options.rag.programs.aiWorkstation = {
    enable = lib.mkEnableOption "ferramentas de estudo, IDE e IA no perfil do usuario";

    enableTraeLauncher = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Instala o wrapper e a entrada desktop do Trae sem empacotar o binario.";
    };
  };

  config = lib.mkIf (!pkgs.stdenv.isDarwin && cfg.enable) {
    home.packages = [
      pkgs.nodejs_22
      codexWrapper
      claudeWrapper
    ]
    ++ lib.optionals cfg.enableTraeLauncher [ traeLauncher ];

    home.shellAliases = {
      ai-codex = "codex";
      ai-claude = "claude";
      ai-launch = "caelestia shell drawers toggle launcher";
      ai-trae = "trae-launcher";
      kb = "rag-obsidian";
    };

    xdg.desktopEntries = lib.mkIf cfg.enableTraeLauncher {
      trae = {
        name = "Trae";
        genericName = "AI IDE";
        comment = "Launcher manual do Trae para instalacoes externas ao Nix";
        exec = "trae-launcher %U";
        terminal = false;
        categories = [
          "Development"
          "IDE"
        ];
      };
    };
  };
}

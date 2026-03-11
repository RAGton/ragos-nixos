# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para configurar o VS Code.
# - Suporta instalar via nixpkgs (legado) ou usar o VS Code do Flatpak (recomendado).
#
# Como usar:
# - Importe via `modules/home-manager/common` (recomendado).
# - Habilite:
#     rag.vscode.enable = true;
# - Opcional:
#     rag.vscode.channel = "unstable"; # ou "stable"
#     rag.vscode.flavor = "vscode";    # ou "vscodium"
#     rag.vscode.installMethod = "flatpak"; # ou "nixpkgs"
#
# Notas:
# - `vscode` (Microsoft) é unfree; este módulo força `allowUnfree` somente
#   para o pacote específico quando necessário.
# - Em modo Flatpak, NÃO instalamos `pkgs.vscode` e sim configuramos:
#   - `~/.var/app/com.visualstudio.code/config/Code/argv.json` (Wayland)
#   - `~/.var/app/com.visualstudio.code/config/Code/User/settings.json`
# =============================================================================
{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.rag.vscode;

  flatpakAppId = "com.visualstudio.code";

  flatpakConfigRoot = ".var/app/${flatpakAppId}/config/Code";
  flatpakSettingsPath = "${flatpakConfigRoot}/User/settings.json";
  flatpakLocalePath = "${flatpakConfigRoot}/User/locale.json";
  flatpakArgvPath = "${flatpakConfigRoot}/argv.json";

  flatpakSettings = {
    # Tema / UX
    "workbench.colorTheme" = "Dracula";
    "glassit.alpha" = 220;

    # Editor
    "editor.fontFamily" = "Iosevka, 'JetBrainsMono Nerd Font', monospace";
    "editor.fontSize" = 14;
    "editor.fontLigatures" = true;
    "editor.minimap.enabled" = false;
    "editor.wordWrap" = "on";

    # Terminal
    "terminal.integrated.scrollback" = 5000;
    "terminal.integrated.cursorStyle" = "line";

    # Git
    "git.enableSmartCommit" = true;
    "git.autofetch" = true;
    "git.autofetchPeriod" = 120;
  };

  flatpakLocale = {
    locale = "pt-br";
  };

  # VS Code (Electron) flags para Wayland via `argv.json` (Flatpak).
  # Keys = flags sem o prefixo `--`.
  flatpakArgv = {
    "ozone-platform-hint" = "auto";
    "enable-features" = "UseOzonePlatform,WaylandWindowDecorations";
  };

  codeFlatpakWrapper = pkgs.writeShellScriptBin "code" ''
    set -euo pipefail
    exec flatpak run ${flatpakAppId} "$@"
  '';

  flatpakExtensions = [
    # Locale
    "MS-CEINTL.vscode-language-pack-pt-BR"

    # Git
    "eamodio.gitlens"
    "mhutchie.git-graph"

    # Jupyter
    "ms-toolsai.jupyter"

    # Rust
    "rust-lang.rust-analyzer"

    # C/C++
    "ms-vscode.cpptools"

    # Python
    "ms-python.python"
    "ms-python.vscode-pylance"

    # Nix
    "jnoortheen.nix-ide"

    # UX / utilitários
    "dracula-theme.theme-dracula"
    "s-nlf-fh.glassit"
    "EditorConfig.EditorConfig"
    "Gruntfuggly.todo-tree"
    "mechatroner.rainbow-csv"
  ];

  vscodeFlatpakBootstrap = pkgs.writeShellScriptBin "vscode-flatpak-bootstrap" ''
    set -euo pipefail

    APP_ID=${lib.escapeShellArg flatpakAppId}

    if ! command -v flatpak >/dev/null 2>&1; then
      echo "[vscode-flatpak] flatpak não encontrado; pulando." >&2
      exit 0
    fi

    if ! flatpak info "$APP_ID" >/dev/null 2>&1; then
      echo "[vscode-flatpak] $APP_ID não está instalado (ainda); pulando." >&2
      exit 0
    fi

    if ! flatpak run --command=code "$APP_ID" --version >/dev/null 2>&1; then
      echo "[vscode-flatpak] não consegui executar o CLI do VS Code via Flatpak; pulando." >&2
      exit 0
    fi

    installed="$(flatpak run --command=code "$APP_ID" --list-extensions 2>/dev/null || true)"

    for ext in \
      ${lib.concatStringsSep " \\\n      " (map lib.escapeShellArg flatpakExtensions)}; do
      if ! printf '%s\n' "$installed" | grep -Fxq "$ext"; then
        echo "[vscode-flatpak] instalando extensão: $ext"
        flatpak run --command=code "$APP_ID" --install-extension "$ext" --force >/dev/null 2>&1 || true
      fi
    done
  '';

  # Pkgs estável (pinado em `inputs.nixpkgs-stable`).
  # Mantém overlays do flake para não divergir de patches/overlays comuns.
  pkgsStable = import inputs.nixpkgs-stable {
    inherit (pkgs) system;
    overlays = (pkgs.overlays or [ ]) ++ [ ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "vscode"
          "visual-studio-code"
        ];
    };
  };

  selectPkgs = if cfg.channel == "stable" then pkgsStable else pkgs;

  package =
    if cfg.flavor == "vscodium" then
      selectPkgs.vscodium
    else
      # VSCode oficial (Microsoft)
      selectPkgs.vscode;

  waylandFlags = builtins.readFile ./wayland-flags.conf;

in
{
  options.rag.vscode = {
    enable = lib.mkEnableOption "Configura o VS Code (Flatpak ou nixpkgs)";

    installMethod = lib.mkOption {
      type = lib.types.enum [ "flatpak" "nixpkgs" ];
      default = "flatpak";
      description = "Como instalar/gerenciar o VS Code: via Flatpak (recomendado) ou via nixpkgs (legado).";
    };

    channel = lib.mkOption {
      type = lib.types.enum [ "unstable" "stable" ];
      default = "unstable";
      description = "Qual nixpkgs usar para o VSCode: 'unstable' (default) ou 'stable'.";
    };

    flavor = lib.mkOption {
      type = lib.types.enum [ "vscode" "vscodium" ];
      default = "vscode";
      description = "Escolhe entre VSCode (Microsoft) e VSCodium (open-source).";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf (cfg.installMethod == "nixpkgs") {
      # Garante `allowUnfree` quando flavor for vscode.
      nixpkgs.config = lib.mkIf (cfg.flavor == "vscode") {
        allowUnfree = true;
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "vscode"
            "visual-studio-code"
          ];
      };

      home.packages = [ package ];

      # VSCode (Electron): flags por arquivo (lido pelo wrapper do nixpkgs).
      # Isso evita exportar variáveis globais e reduz warnings.
      xdg.configFile."code-flags.conf" = lib.mkIf (!pkgs.stdenv.isDarwin) {
        text = waylandFlags;
      };
    })

    (lib.mkIf (cfg.installMethod == "flatpak") {
      assertions = [
        {
          assertion = !pkgs.stdenv.isDarwin;
          message = "rag.vscode.installMethod=flatpak só é suportado em Linux.";
        }
      ];

      home.packages = [
        codeFlatpakWrapper
        vscodeFlatpakBootstrap
      ];

      home.file."${flatpakArgvPath}" = {
        text = builtins.toJSON flatpakArgv;
        force = true;
      };

      home.file."${flatpakSettingsPath}" = {
        text = builtins.toJSON flatpakSettings;
        force = true;
      };

      home.file."${flatpakLocalePath}" = {
        text = builtins.toJSON flatpakLocale;
        force = true;
      };

      # Instala/garante extensões no VS Code Flatpak (idempotente).
      # Não falha o `home-manager switch` se o Flatpak ainda não foi instalado.
      home.activation.vscode-flatpak-extensions =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          echo "[home-manager] vscode(flatpak): garantindo extensões"
          ${vscodeFlatpakBootstrap}/bin/vscode-flatpak-bootstrap || true
        '';
    })
  ]);
}

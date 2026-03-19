{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.rag.vscode;

  edition =
    if cfg.edition != null then
      cfg.edition
    else if cfg.flavor == "vscodium" then
      "codium"
    else
      "stable";

  delivery =
    if cfg.delivery != null then
      cfg.delivery
    else if edition == "insiders" then
      "managed-download"
    else
      "nixpkgs";

  configRootName =
    if edition == "codium" then
      "VSCodium"
    else if edition == "insiders" then
      "Code - Insiders"
    else
      "Code";

  userDataDir = "${config.home.homeDirectory}/.config/${configRootName}";
  extensionsDir = "${config.home.homeDirectory}/.local/share/ragos/vscode-insiders/extensions";
  insidersRoot = "${config.home.homeDirectory}/.local/share/ragos/vscode-insiders";
  insidersCurrent = "${insidersRoot}/current";
  insidersUpdateUrl = "https://update.code.visualstudio.com/latest/linux-x64/insider";

  baseVscodeSettings = {
    "workbench.colorTheme" = "Dracula";
    "editor.fontFamily" = "Iosevka, 'JetBrainsMono Nerd Font', monospace";
    "editor.fontSize" = 14;
    "editor.fontLigatures" = true;
    "editor.minimap.enabled" = false;
    "editor.wordWrap" = "on";
    "terminal.integrated.scrollback" = 5000;
    "terminal.integrated.cursorStyle" = "line";
    "git.enableSmartCommit" = true;
    "git.autofetch" = true;
    "git.autofetchPeriod" = 120;
  };

  vscodeSettings = baseVscodeSettings // cfg.extraSettings;

  vscodeLocale = {
    locale = "pt-br";
  };

  vscodeArgv = {
    "ozone-platform-hint" = "auto";
    "enable-features" = "UseOzonePlatform,WaylandWindowDecorations";
  };

  baseVscodeExtensions = [
    "MS-CEINTL.vscode-language-pack-pt-BR"
    "eamodio.gitlens"
    "mhutchie.git-graph"
    "ms-toolsai.jupyter"
    "rust-lang.rust-analyzer"
    "ms-vscode.cpptools"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "jnoortheen.nix-ide"
    "dracula-theme.theme-dracula"
    "EditorConfig.EditorConfig"
    "Gruntfuggly.todo-tree"
    "mechatroner.rainbow-csv"
  ];

  vscodeExtensions = baseVscodeExtensions ++ cfg.extraExtensions;

  vscodePackage =
    if edition == "codium" then
      pkgs.vscodium
    else
      pkgs.vscode;

  codeInsiders = pkgs.writeShellApplication {
    name = "code-insiders";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      current_dir="${insidersCurrent}"
      binary="$current_dir/bin/code"

      if [ ! -x "$binary" ]; then
        echo "code-insiders: VS Code Insiders ainda não foi baixado." >&2
        echo "code-insiders: rode 'systemctl --user start vscode-insiders-refresh.service' e tente novamente." >&2
        exit 1
      fi

      exec "$binary" \
        --user-data-dir "${userDataDir}" \
        --extensions-dir "${extensionsDir}" \
        "$@"
    '';
  };

  codeInsidersBootstrap = pkgs.writeShellApplication {
    name = "vscode-insiders-bootstrap";
    runtimeInputs = [
      codeInsiders
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      set -euo pipefail

      if ! code-insiders --version >/dev/null 2>&1; then
        echo "vscode-insiders-bootstrap: VS Code Insiders indisponível; pulando." >&2
        exit 0
      fi

      installed="$(code-insiders --list-extensions 2>/dev/null || true)"

      for ext in \
        ${lib.concatStringsSep " \\\n        " (map lib.escapeShellArg vscodeExtensions)}; do
        if ! printf '%s\n' "$installed" | grep -Fxq "$ext"; then
          echo "vscode-insiders-bootstrap: instalando extensão $ext"
          code-insiders --install-extension "$ext" --force >/dev/null 2>&1 || true
        fi
      done
    '';
  };

  codeInsidersRefresh = pkgs.writeShellApplication {
    name = "vscode-insiders-refresh";
    runtimeInputs = [
      codeInsidersBootstrap
      pkgs.coreutils
      pkgs.curl
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gzip
      pkgs.gnutar
    ];
    text = ''
      set -euo pipefail

      base_dir="${insidersRoot}"
      versions_dir="$base_dir/versions"
      metadata_file="$base_dir/latest-url"
      tmp_dir="$(mktemp -d)"

      cleanup() {
        rm -rf "$tmp_dir"
      }

      trap cleanup EXIT

      mkdir -p "$versions_dir" "${extensionsDir}"

      resolved_url="$(curl -fsSIL -o /dev/null -w '%{url_effective}' -L "${insidersUpdateUrl}")"

      if [ -z "$resolved_url" ]; then
        echo "vscode-insiders-refresh: não foi possível resolver a URL da build." >&2
        exit 1
      fi

      if [ -f "$metadata_file" ] && [ "$(cat "$metadata_file")" = "$resolved_url" ] && [ -L "$base_dir/current" ]; then
        echo "vscode-insiders-refresh: já está atualizado."
        exit 0
      fi

      archive="$tmp_dir/vscode-insiders.tar.gz"
      extract_dir="$tmp_dir/extracted"
      mkdir -p "$extract_dir"

      curl -fsSL "$resolved_url" -o "$archive"
      tar -xzf "$archive" -C "$extract_dir"

      app_dir="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

      if [ -z "$app_dir" ] || [ ! -x "$app_dir/bin/code" ]; then
        echo "vscode-insiders-refresh: estrutura inesperada da build baixada." >&2
        exit 1
      fi

      version_key="$(printf '%s' "$resolved_url" | sha256sum | cut -d' ' -f1)"
      target_dir="$versions_dir/$version_key"

      rm -rf "$target_dir"
      mv "$app_dir" "$target_dir"
      ln -sfn "$target_dir" "$base_dir/current"
      printf '%s\n' "$resolved_url" > "$metadata_file"

      vscode-insiders-bootstrap || true
    '';
  };
in
{
  options.rag.vscode = {
    enable = lib.mkEnableOption "Configura uma única origem de verdade para o VSCode";

    edition = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "stable" "codium" "insiders" ]);
      default = null;
      description = "Edição desejada do editor.";
    };

    delivery = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "nixpkgs" "managed-download" ]);
      default = null;
      description = "Como entregar a edição escolhida.";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Configurações adicionais mescladas ao settings.json do VS Code.";
    };

    extraExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Lista de extensões extras instaladas além do conjunto base.";
    };

    channel = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "unstable" "stable" ]);
      default = null;
      visible = false;
      description = "Opção legada. Use rag.vscode.edition.";
    };

    flavor = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "vscode" "vscodium" ]);
      default = null;
      visible = false;
      description = "Opção legada. Use rag.vscode.edition.";
    };

    installMethod = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "flatpak" "nixpkgs" ]);
      default = null;
      visible = false;
      description = "Opção legada. O caminho flatpak foi removido.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.installMethod != "flatpak";
          message = "rag.vscode.installMethod=flatpak foi removido. Use rag.vscode.edition/delivery.";
        }
        {
          assertion = !(edition == "insiders" && delivery != "managed-download");
          message = "rag.vscode.edition=\"insiders\" exige rag.vscode.delivery=\"managed-download\".";
        }
        {
          assertion = !(edition != "insiders" && delivery == "managed-download");
          message = "rag.vscode.delivery=\"managed-download\" só é suportado com edition=\"insiders\".";
        }
      ];

      warnings =
        lib.optionals (cfg.channel != null) [
          "rag.vscode.channel está deprecated e agora é ignorado; use rag.vscode.edition/rag.vscode.delivery."
        ]
        ++ lib.optionals (cfg.flavor != null || cfg.installMethod != null) [
          "rag.vscode.flavor/installMethod estão deprecated; use rag.vscode.edition/rag.vscode.delivery."
        ];

      xdg.configFile."${configRootName}/User/settings.json" = {
        text = builtins.toJSON vscodeSettings;
        force = true;
      };

      xdg.configFile."${configRootName}/User/locale.json" = {
        text = builtins.toJSON vscodeLocale;
        force = true;
      };

      xdg.configFile."${configRootName}/argv.json" = {
        text = builtins.toJSON vscodeArgv;
        force = true;
      };
    }

    (lib.mkIf (delivery == "nixpkgs") {
      home.packages = [ vscodePackage ];
    })

    (lib.mkIf (delivery == "managed-download") {
      home.packages = [
        codeInsiders
        codeInsidersBootstrap
        codeInsidersRefresh
      ];

      xdg.desktopEntries."code-insiders" = {
        name = "Visual Studio Code Insiders";
        genericName = "Code Editor";
        comment = "VS Code Insiders com estado isolado";
        exec = "code-insiders %F";
        terminal = false;
        icon = "${insidersCurrent}/resources/app/resources/linux/code.png";
        categories = [ "Development" "IDE" "TextEditor" ];
        mimeType = [
          "text/plain"
          "inode/directory"
        ];
        startupNotify = true;
      };

      systemd.user.services."vscode-insiders-refresh" = {
        Unit = {
          Description = "Refresh the managed VS Code Insiders installation";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${codeInsidersRefresh}/bin/vscode-insiders-refresh";
        };
      };

      systemd.user.timers."vscode-insiders-refresh" = {
        Unit = {
          Description = "Refresh the managed VS Code Insiders installation daily";
        };
        Timer = {
          OnStartupSec = "2m";
          OnUnitActiveSec = "1d";
          Persistent = true;
          Unit = "vscode-insiders-refresh.service";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    })
  ]);
}

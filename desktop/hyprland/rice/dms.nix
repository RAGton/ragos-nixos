# =============================================================================
# Rice: DankMaterialShell (DMS) - Material Design rice para Hyprland
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Rice completa baseada em Material Design para Hyprland
# - Integração com DankMaterialShell (https://github.com/AvengeMedia/DankMaterialShell)
# - Baseado em QuickShell (QML)
#
# Por quê:
# - Interface moderna e bonita para Hyprland
# - Configuração declarativa (links de arquivos do DMS repo)
# - Fácil atualizar (nix flake update)
#
# Como usar:
# 1. No flake.nix, o input DMS já está configurado
# 2. No Home Manager: rag.rice.dms.enable = true;
# 3. Este módulo faz links dos configs do DMS para ~/.config
#
# Riscos:
# - DMS pode conflitar com configs manuais em ~/.config
# - Usar force = true para sobrescrever
# =============================================================================
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.rag.rice.dms;

  # Source do DMS (flake input)
  dmsSource = inputs.dms;
  dmsQuickshellDir = "${dmsSource}/quickshell";

in
{
  options.rag.rice.dms = {
    enable = lib.mkEnableOption "DankMaterialShell rice para Hyprland";

    variant = lib.mkOption {
      type = lib.types.enum [ "default" "minimal" "full" ];
      default = "default";
      description = ''
        Variante do DMS:
        - default: Configuração padrão do DMS
        - minimal: Menos widgets, mais performance
        - full: Todos os widgets e features
      '';
    };

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Wallpaper customizado (substitui o padrão do DMS)";
    };
  };

  config = lib.mkIf cfg.enable {
    # =========================
    # Hyprland Config
    # =========================
    # DMS não fornece um hyprland.conf no upstream (neste momento).
    # Mantemos este hook para o futuro, caso upstream adicione snippets.
    wayland.windowManager.hyprland.extraConfig = lib.mkDefault "";

    # =========================
    # XDG Config Files (DMS)
    # =========================
    # DMS upstream é baseado em QuickShell (QML). Linkamos a árvore inteira.
    xdg.configFile = {
      "quickshell" = {
        source = dmsQuickshellDir;
        recursive = true;
      };
    };

    # =========================
    # Pacotes Necessários
    # =========================
    home.packages = with pkgs; [
      # Dependências Wayland utils comuns
      libnotify
      grim
      slurp
      wl-clipboard

      # Fonts (Material Design icons)
      material-design-icons
      material-symbols

      # Systray apps
      networkmanagerapplet
      blueman
      pavucontrol

      # NOTE: O runtime do DMS depende do QuickShell.
      # Se o pacote existir em nixpkgs, habilite aqui (nome pode variar por canal):
      # quickshell
    ];

    # =========================
    # Execução / Entrada
    # =========================
    # Wrapper simples para iniciar o shell do DMS (dependendo do binary `quickshell`).
    home.packages = (config.home.packages or []) ++ [
      (pkgs.writeShellApplication {
        name = "dms-shell";
        runtimeInputs = with pkgs; [ bash ];
        text = ''
          set -euo pipefail

          if ! command -v quickshell >/dev/null 2>&1; then
            echo "quickshell não encontrado no PATH. Instale/adicione o pacote QuickShell no seu setup." >&2
            exit 1
          fi

          exec quickshell -c "$HOME/.config/quickshell/DMSShell.qml"
        '';
      })
    ];

    # =========================
    # Fonts
    # =========================
    fonts.fontconfig.enable = true;

    # =========================
    # GTK Theme (Material)
    # =========================
    gtk = {
      enable = true;

      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      font = {
        name = "Roboto";
        size = 11;
        package = pkgs.roboto;
      };
    };

    # =========================
    # Qt Theme (Material)
    # =========================
    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style.name = "adwaita-dark";
    };

    # =========================
    # Cursor Theme
    # =========================
    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };

    # =========================
    # Scripts de Instalação
    # =========================
    # Script para baixar/atualizar DMS config se necessário
    home.activation.setupDMS = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c '
        echo "🎨 DankMaterialShell (DMS) está habilitado!"
        echo "Source: ${dmsSource}"
        echo ""
        echo "✅ Config do DMS (quickshell/) foi linkada para ~/.config/quickshell"
        echo "➡️  Para iniciar: rode 'dms-shell' (requer o binário quickshell no PATH)"
      '
    '';
  };
}


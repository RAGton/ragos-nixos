# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para instalar o VSCode de forma declarativa.
# - Evita "duas fontes" (systemPackages vs home.packages) e conflitos no PATH.
#
# Como usar:
# - Importe via `modules/home-manager/common` (recomendado).
# - Habilite:
#     rag.vscode.enable = true;
# - Opcional:
#     rag.vscode.channel = "unstable"; # ou "stable"
#     rag.vscode.flavor = "vscode";    # ou "vscodium"
#
# Notas:
# - `vscode` (Microsoft) é unfree; este módulo força `allowUnfree` somente
#   para o pacote específico quando necessário.
# - Este módulo instala o binário `code` no PATH do usuário.
# =============================================================================
{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.rag.vscode;

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
    enable = lib.mkEnableOption "Instala o VSCode (code) via Home Manager";

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

  config = lib.mkIf cfg.enable {
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
  };
}


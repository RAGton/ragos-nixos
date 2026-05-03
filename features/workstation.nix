# =============================================================================
# Feature: Workstation
#
# O que é:
# - Desktop/workstation sem acoplar gaming, Wine ou Lutris.
#
# Por quê:
# - Permite que hosts como o Glacier continuem servidor IA mesmo com gaming
#   desligado, mantendo a camada desktop como escolha explícita.
# =============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kryonix.features.workstation;
in
{
  options.kryonix.features.workstation = {
    enable = lib.mkEnableOption "Stack workstation (Hyprland/Caelestia + apps de produtividade)";

    desktop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Habilita o desktop padrão do projeto para workstation.";
      };
    };

    productivityApps = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Instala aplicativos gráficos de produtividade da workstation.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    kryonix.desktop.environment = lib.mkIf cfg.desktop.enable (lib.mkDefault "hyprland");
    kryonix.shell.caelestia.enable = lib.mkIf cfg.desktop.enable (lib.mkDefault true);

    environment.systemPackages = lib.optionals cfg.productivityApps.enable (
      with pkgs;
      [
        discord
        obs-studio
        vlc
        gimp
        libreoffice
      ]
    );
  };
}

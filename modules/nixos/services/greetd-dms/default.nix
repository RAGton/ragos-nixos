# =============================================================================
# NixOS: greetd + tuigreet (Wayland-friendly login manager)
#
# O que é:
# - Habilita greetd e configura a sessão padrão com tuigreet.
#
# Por quê:
# - Substitui SDDM/GDM por um login manager leve e Wayland-friendly.
# - tuigreet é o greeter padrão, estável e bem integrado com greetd.
#
# Como usar:
# - No host (ex.: hosts/inspiron/default.nix):
#     rag.services.greetdDms.enable = true;
#
# Notas:
# - O rice DMS (DankMaterialShell) é carregado pelo usuário via Home Manager.
#   Aqui só configuramos o display manager (greetd + tuigreet).
# =============================================================================
{ config, lib, pkgs, userConfig, ... }:

let
  cfg = config.rag.services.greetdDms;
  greeterUser = cfg.user;
in
{
  options.rag.services.greetdDms = {
    enable = lib.mkEnableOption "greetd com tuigreet (gerenciador de login Wayland-friendly)";

    user = lib.mkOption {
      type = lib.types.str;
      default = userConfig.name;
      defaultText = lib.literalExpression "userConfig.name";
      description = "Usuário que executa o processo greeter do greetd (deve existir em users.users).";
    };

    command = lib.mkOption {
      type = lib.types.str;
      default = "Hyprland";
      description = "Comando da sessão lançado após o login (ex.: 'Hyprland', 'sway').";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session = {
        user = greeterUser;
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${lib.escapeShellArg cfg.command}";
      };
    };

    environment.systemPackages = [ pkgs.greetd.tuigreet ];

    assertions = [
      {
        assertion = lib.hasAttr greeterUser config.users.users;
        message = "greetdDms: users.users.${greeterUser} não existe. Crie o usuário antes ou ajuste rag.services.greetdDms.user.";
      }
    ];
  };
}


# =============================================================================
# NixOS: greetd + DankMaterialShell greeter (DMS)
#
# O que é:
# - Habilita greetd e configura a sessão padrão para usar o greeter do DMS.
#
# Por quê:
# - Substitui SDDM/GDM por um login manager leve e Wayland-friendly.
# - Integra o ecossistema DMS (quickshell) já usado no Hyprland.
#
# Como usar:
# - No host (ex.: hosts/inspiron/default.nix):
#     rag.services.greetdDms.enable = true;
#
# Notas:
# - O módulo upstream do DMS fornece `programs.dank-material-shell.greeter.*`.
# - Este módulo só faz wiring no NixOS (services.greetd + user do greeter).
# =============================================================================
{ config, lib, pkgs, ... }:

let
  cfg = config.rag.services.greetdDms;
  # Usuário que o greetd usará para rodar o greeter.
  greeterUser = cfg.user;
in
{
  options.rag.services.greetdDms = {
    enable = lib.mkEnableOption "greetd with DankMaterialShell greeter";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.userConfig.name;
      defaultText = lib.literalExpression "config.userConfig.name";
      description = "User to run the DMS greeter as (must exist in users.users).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Greetd como display manager.
    services.greetd = {
      enable = true;
      settings.default_session.user = greeterUser;
      # O módulo upstream do DMS define o comando default via mkDefault,
      # mas a gente deixa isso explícito aqui pra evitar ambiguidades.
      settings.default_session.command = lib.mkDefault (lib.getExe config.programs.dank-material-shell.greeter.script);
    };

    # Ativa o greeter do DMS (módulo upstream fornece a lógica completa).
    programs.dank-material-shell.greeter.enable = true;

    assertions = [
      {
        assertion = (config.users.users.${greeterUser} or null) != null;
        message = "greetdDms: users.users.${greeterUser} não existe. Crie o usuário antes ou ajuste rag.services.greetdDms.user.";
      }
    ];
  };
}


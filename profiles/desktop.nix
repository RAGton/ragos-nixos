# =============================================================================
# Profile: desktop
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Preset composável para máquinas desktop/workstation.
# - Agrupa um conjunto de features típicas (virtualização, desenvolvimento, opcionalmente gaming).
#
# Por quê:
# - Evita repetir o mesmo bloco `rag.features.*` em múltiplos hosts.
# - Mantém hosts finos e expressivos.
#
# Como usar (no host):
#   rag.profiles.desktop.enable = true;
#
# Importante:
# - Este profile NÃO escolhe desktop environment.
# - O desktop continua sendo escolhido via `rag.desktop.environment`.
# =============================================================================
{ config, lib, ... }:

let
  cfg = config.rag.profiles.desktop;

in
{
  options.rag.profiles.desktop = {
    enable = lib.mkEnableOption "Perfil desktop (virtualização + desenvolvimento + gaming opcional)";

    gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Habilita a feature gaming como parte do perfil desktop";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    rag.features = {
      virtualization.enable = lib.mkDefault true;
      development.enable = lib.mkDefault true;

      # Gaming é opt-in neste profile.
      gaming.enable = lib.mkDefault cfg.gaming.enable;
    };
  };
}


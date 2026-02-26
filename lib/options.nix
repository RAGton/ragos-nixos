# =============================================================================
# Lib: Opções customizadas do RagOS
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Define o namespace rag.* com opções para desktop, features, rice, etc
#
# Por quê:
# - Abstração de alto nível para configuração
# - Hosts escolhem via opções, não imports
# - Facilita troca de desktop/features
#
# Como:
# - Importado nos módulos do flake via mkNixosConfiguration
# - Opções ficam disponíveis em config.rag.*
#
# Riscos:
# - NENHUM nesta etapa (apenas define opções, não força uso)
# =============================================================================
{ config, lib, pkgs, ... }:

{
  options.rag = {
    # =========================
    # Desktop Environment
    # =========================
    desktop = {
      environment = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "kde" "hyprland" "gnome" "dms" ]);
        default = null;
        description = ''
          Ambiente de desktop a usar.

          Opções:
          - "kde": KDE Plasma 6 (SDDM + Wayland)
          - "hyprland": compositor Hyprland (vanilla)
          - "dms": DankMaterialShell (Hyprland + rice Material)
          - "gnome": GNOME (suporte futuro)
          - null: sem desktop (headless/servidor)

          Nota: definir esta opção NÃO importa o desktop automaticamente ainda.
          Isso será implementado na próxima etapa de migração.
        '';
      };

      wayland = lib.mkOption {
        type = lib.types.bool;
        default = config.rag.desktop.environment != null;
        description = "Habilita suporte a Wayland (ativado automaticamente com desktop)";
      };
    };

    # =========================
    # Hardware / Drivers (host-toggles)
    # =========================
    hardware = {
      openrgb = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Habilita OpenRGB (pacotes + regras udev) via módulo common";
        };
      };
    };

    # =========================
    # Services (host-toggles)
    # =========================
    services = { };

    # =========================
    # Features (Opt-in)
    # =========================
    # NOTA: As opções de features são declaradas nos próprios módulos de features
    # (features/gaming.nix, features/virtualization.nix, etc)
    # Não declarar aqui para evitar duplicação!

    # =========================
    # Branding
    # =========================
    branding = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "RagOS";
        description = "Nome do branding do sistema (exibido na tela de login, etc)";
      };

      logo = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Caminho para o logotipo do branding";
      };
    };
  };

  # =========================
  # Config (validation only)
  # =========================
  config = {
    # Assertions para validar configuração
    assertions = [
      {
        assertion =
          config.rag.desktop.environment == null ||
          (config.services.displayManager.sddm.enable or false) ||
          (config.services.displayManager.gdm.enable or false) ||
          (config.programs.hyprland.enable or false);
        message = ''
          O ambiente de desktop requer um gerenciador de display habilitado.
          Se estiver usando rag.desktop.environment, verifique se o módulo de desktop correspondente foi importado.
        '';
      }
    ];

    # Warnings para opções definidas mas sem efeito (transição v1→v2)
    warnings =
      lib.optional
        (config.rag.desktop.environment != null &&
         !(config.services.displayManager.sddm.enable or false) &&
         !(config.services.displayManager.gdm.enable or false) &&
         !(config.programs.hyprland.enable or false))
        ''
          rag.desktop.environment está definido como "${config.rag.desktop.environment}", mas o desktop
          ainda não está sendo importado. Isso é esperado durante a migração.
          O desktop/manager.nix cuidará do import automático na próxima etapa.
        '';
  };
}

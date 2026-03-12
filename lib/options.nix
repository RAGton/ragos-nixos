# =============================================================================
# Lib: Opções customizadas do RagOS
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
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
        type = lib.types.nullOr (lib.types.enum [ "hyprland" ]);
        default = null;
        description = ''
          Ambiente de desktop a usar.

          Opções:
          - "hyprland": compositor Hyprland (com DMS)
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

      directLogin = {
        enable = lib.mkEnableOption ''
          Inicia o desktop sem display manager (sem GDM/greetd), usando autologin em TTY
          e auto-start do compositor na sessão do usuário.

          AVISO: isso remove a tela de login e entra direto no usuário.
        '';

        tty = lib.mkOption {
          type = lib.types.int;
          default = 1;
          description = "TTY (VT) em que o auto-start do compositor deve acontecer (ex.: 1 para tty1).";
        };
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
         !(config.services.displayManager.gdm.enable or false) &&
         !(config.programs.hyprland.enable or false))
        ''
          rag.desktop.environment está definido como "${config.rag.desktop.environment}", mas o desktop
          ainda não está sendo importado. Isso é esperado durante a migração.
          Verifique se hosts/common está importando modules/nixos/hyprland corretamente.
        '';
  };
}

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
          Desktop environment to use.

          Options:
          - "kde": KDE Plasma 6 (SDDM + Wayland)
          - "hyprland": Hyprland compositor (vanilla)
          - "dms": DankMaterialShell (Hyprland + Material rice)
          - "gnome": GNOME (future support)
          - null: No desktop (headless/server)

          Note: Setting this does NOT automatically import the desktop yet.
          This will be implemented in the next migration step.
        '';
      };

      wayland = lib.mkOption {
        type = lib.types.bool;
        default = config.rag.desktop.environment != null;
        description = "Enable Wayland support (auto-enabled with desktop)";
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
          description = "Enable OpenRGB (packages + udev rules) from common module";
        };
      };
    };

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
        description = "System branding name (shown in login screen, etc)";
      };

      logo = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to branding logo";
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
          Desktop environment requires a display manager to be enabled.
          If using rag.desktop.environment, ensure the corresponding desktop module is imported.
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
          rag.desktop.environment is set to "${config.rag.desktop.environment}" but the desktop
          is not being imported yet. This is expected during migration.
          The desktop/manager.nix will handle auto-import in the next step.
        '';
  };
}

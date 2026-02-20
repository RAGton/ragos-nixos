# Home Manager: Tema Bart (KDE Plasma ONLY)
# Tema da KDE Store
#
# ⚠️  IMPORTANTE: Este tema é EXCLUSIVO do KDE Plasma
# Não funciona em Hyprland, GNOME, ou outros desktops
#
# Objetivo
# - Instalar e aplicar automaticamente o tema Bart no Plasma (plasma-manager)
# - Aplicar tema GTK e ícones (via Home Manager)
# - Configurar Kvantum (engine de temas Qt/KDE)
# - Configurar Aurorae (decoração de janelas KDE)
#
# Notas
# - Cursor você já gerencia em outro lugar (Nordzy), então não mexemos.
# - O tema Bart pode ser instalado manualmente via: System Settings > Appearance > Get New...
# - Este módulo aplica as configurações depois que o tema está instalado
#
# Dependências
# - plasma-manager (programs.plasma)
# - Kvantum
# - KDE Plasma desktop environment
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.rag.theme.bart;



in
{
  options.rag.theme.bart = {
    enable = lib.mkEnableOption "Tema Bart (Plasma + GTK + Ícones)";

    # Nome a ser aplicado no Plasma/GTK/ícones.
    # Se o upstream usar outro nome, você pode ajustar no host sem mexer no módulo.
    name = lib.mkOption {
      type = lib.types.str;
      default = "Bart";
      description = "Nome do tema Bart conforme aparece no Plasma/GTK (ex.: Bart, Bart-Dark).";
    };

    iconName = lib.mkOption {
      type = lib.types.str;
      default = "Bart";
      description = "Nome do tema de ícones Bart, se existir (senão, ajuste aqui).";
    };

    gtkName = lib.mkOption {
      type = lib.types.str;
      default = "Bart";
      description = "Nome do tema GTK Bart, se existir (senão, ajuste aqui).";
    };

    kvantumTheme = lib.mkOption {
      type = lib.types.str;
      default = "Bart";
      description = "Nome do tema Kvantum Bart.";
    };

    auroraeTheme = lib.mkOption {
      type = lib.types.str;
      default = "__aurorae__svg__Bart";
      description = "Nome do tema Aurorae (decoração de janelas) Bart.";
    };

    # Por padrão NÃO aplicamos look-and-feel automaticamente porque ele pode sobrescrever
    # windowDecorations/splashScreen e gerar warning no plasma-manager.
    plasmaLookAndFeel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "Bart";
      description = "Look-and-feel do Plasma para aplicar (null para não aplicar).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Script para instalar o tema Bart da KDE Store
    home.activation.installBartTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c '
        echo "Verificando tema Bart..."

        # Verifica se o tema já está instalado
        if [ ! -d "$HOME/.local/share/plasma/look-and-feel/Bart" ] && \
           [ ! -d "$HOME/.local/share/plasma/look-and-feel/com.gitlab.jomada.bart" ]; then
          echo "Tema Bart não encontrado. Para instalar:"
          echo "1. Abra System Settings > Appearance > Global Theme"
          echo "2. Clique em 'Get New Global Themes...'"
          echo "3. Procure por 'Bart' e instale"
          echo ""
          echo "Ou instale manualmente baixando de: https://store.kde.org"
        else
          echo "Tema Bart já está instalado!"
        fi
      '
    '';

    # GTK
    gtk = {
      enable = true;
      theme = {
        name = cfg.gtkName;
      };
      iconTheme = {
        name = cfg.iconName;
      };

      # Você já pode ter arquivos existentes de tema GTK (de setups antigos/manuais).
      # Forçamos o overwrite para manter estado 100% declarativo e evitar falha no switch.
      gtk3.extraConfig = lib.mkForce { };
      gtk4.extraConfig = lib.mkForce { };

      # GTK2 está em EOL e costuma ser só fonte de conflito (.gtkrc-2.0).
      # Desabilitamos a geração do gtk2 para evitar colisões e manter switch robusto.
      gtk2.enable = lib.mkForce false;
    };

    # Arquivos GTK que o HM escreve e que normalmente conflitam com configs antigas.
    # `force = true` resolve o erro "would be clobbered".
    xdg.configFile."gtk-3.0/settings.ini".force = true;
    xdg.configFile."gtk-4.0/settings.ini".force = true;

    # Kvantum theme configuration
    xdg.configFile."Kvantum/kvantum.kvconfig" = {
      force = true;
      text = lib.generators.toINI { } {
        General = {
          theme = cfg.kvantumTheme;
        };
      };
    };

    # Plasma (plasma-manager)
    programs.plasma = {
      # não setamos enable aqui pra não forçar; o módulo kde já faz isso
      workspace = {
        lookAndFeel = lib.mkIf (cfg.plasmaLookAndFeel != null) cfg.plasmaLookAndFeel;
        iconTheme = cfg.iconName;

        # Aurorae (decoração de janelas)
        windowDecorations = {
          library = "org.kde.kwin.aurorae";
          theme = cfg.auroraeTheme;
        };
      };

      # Alguns setups usam colorscheme separado do lookandfeel.
      # Se o tema expor um colorscheme com o mesmo nome, o Plasma aplica.
      # Se não existir, ele mantém o atual.
      workspace.colorScheme = lib.mkDefault cfg.name;
      workspace.theme = lib.mkDefault cfg.name;
    };
  };
}


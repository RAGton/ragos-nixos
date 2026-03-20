#+#+#+#+####################################################################
# Home Manager: Alacritty
# Autor: rag
#
# O que é
# - Configuração do terminal Alacritty do usuário.
#
# Por quê
# - Mantém terminal consistente (fonte, shell, comportamento) entre máquinas.
#
# Como
# - Usa `programs.alacritty.settings` para gerar o arquivo de config.
#
# Riscos
# - Alterar fonte/shell pode impactar UX e integração com multiplexer (zellij).
{ pkgs, ... }:
{
  # Instala e configura o Alacritty via Home Manager.
  programs.alacritty = {
    enable = true;
    settings = {
      general = {
        live_config_reload = true;
      };

      terminal = {
        shell.program = "${pkgs.zsh}/bin/zsh";
        shell.args = [
          "-l"
          "-c"
          "zellij"
        ];
      };

      env = {
        TERM = "xterm-256color";
      };

      window = {
        decorations = if pkgs.stdenv.isDarwin then "buttonless" else "full";
        dynamic_title = false;
        dynamic_padding = true;
        dimensions = {
          columns = 170;
          lines = 45;
        };
        padding = {
          x = 5;
          y = 1;
        };
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      keyboard.bindings =
        if pkgs.stdenv.isDarwin then
          [
            {
              key = "Slash";
              mods = "Control";
              chars = ''\u001f'';
            }
          ]
        else
          [ ];

      font = {
        size = if pkgs.stdenv.isDarwin then 15 else 12;
        normal = {
          family = "Monocraft";
          style = "Regular";
        };
        bold = {
          family = "Monocraft";
          style = "Bold";
        };
        italic = {
          family = "Monocraft";
          style = "Italic";
        };
        bold_italic = {
          family = "Monocraft";
          style = "Italic";
        };
      };

      selection = {
        semantic_escape_chars = '',│`|:"' ()[]{}<>'';
        save_to_clipboard = true;
      };
    };
  };
}

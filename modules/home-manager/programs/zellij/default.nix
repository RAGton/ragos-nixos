# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager que instala o `zellij` e gera uma configuração base.
# - Inclui um script simples para iniciar o zellij pelo PATH.
#
# Por quê:
# - Substitui o uso do tmux, mantendo atalhos e fluxo parecidos.
# - Evita dependência de configuração manual em `~/.config/zellij`.
#
# Como:
# - Instala `pkgs.zellij` via `home.packages`.
# - Gera `~/.config/zellij/config.kdl` via `home.file.*.text`.
# - Publica `~/bin/start-zellij` para facilitar execução.
#
# Riscos:
# - Como a config é gerada, alterações manuais em `~/.config/zellij/config.kdl` podem ser sobrescritas.
# - Atalhos/comandos podem mudar entre versões do zellij.
# =============================================================================
{ pkgs, ... }:
{
  # Instala o Zellij e fornece uma config "traduzida" a partir do tmux.
  home.packages = [ pkgs.zellij ];

  # Cria uma config padrão baseada no tmux:
  # - prefix: Ctrl+q
  # - mouse: ligado
  # - scrollback/histórico: 10000
  # - navegação de painéis com Ctrl-h/j/k/l
  # - atalhos básicos de resize
  home.file.".config/zellij/config.kdl".text = ''
    // Configuração do zellij baseada no tmux (gerada automaticamente).
    // Revise e adapte em ~/.config/zellij/config.kdl

    general {
      // linhas de scrollback
      scrollback_lines 10000
      // habilita suporte ao mouse
      enable_mouse true
    }

    // Keybinds: mapeia binds estilo tmux para equivalentes do zellij.
    // Nota: nomes/comandos podem variar por versão.
    keybinds {
      // Usar Ctrl-q como "leader" não é idêntico no zellij;
      // então mapeamos combinações comuns diretamente.
      normal {
        // Navegação de painéis: Ctrl-h/j/k/l
        "Ctrl-h" = "MoveFocusLeft"
        "Ctrl-j" = "MoveFocusDown"
        "Ctrl-k" = "MoveFocusUp"
        "Ctrl-l" = "MoveFocusRight"

        // Splits semelhantes ao tmux: substituídos por combos diretos
        "Ctrl-\\" = "SplitVertical"
        "Ctrl-|" = "SplitHorizontal"
      }

      pane {
        // Resize com Shift+Seta (semelhante ao tmux)
        "Shift-Down" = "ResizePaneDown 8"
        "Shift-Up" = "ResizePaneUp 8"
        "Shift-Left" = "ResizePaneLeft 8"
        "Shift-Right" = "ResizePaneRight 8"
      }
    }

    // Layout simples como padrão
    layout "default" {
      pane 1
    }
  '';

  # Script simples para iniciar o zellij
  home.file."bin/start-zellij".text = ''
    #!/bin/sh
    exec ${pkgs.zellij}/bin/zellij "$@"
  '';
  # mode omitido por compatibilidade com versões antigas do Home Manager
}

{
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (pkgs.stdenv.isDarwin) {
    # Garante que o pacote aerospace esteja instalado
    home.packages = [ pkgs.aerospace ];

    # Importa a configuração do aerospace a partir do store do Home Manager
    home.file.".aerospace.toml".text = ''
      # Iniciar o AeroSpace no login
      start-at-login = true

      # Configurações de normalização
      enable-normalization-flatten-containers = true
      enable-normalization-opposite-orientation-for-nested-containers = true

      # Configurações do layout accordion
      accordion-padding = 30

      # Configurações padrão do container raiz
      default-root-container-layout = 'tiles'
      default-root-container-orientation = 'auto'

      # Configurações de “mouse segue o foco”
      on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
      on-focus-changed = ['move-mouse window-lazy-center']

      # Mostrar automaticamente apps ocultos do macOS
      automatically-unhide-macos-hidden-apps = true

      # Preset de mapeamento de teclas
      [key-mapping]
      preset = 'qwerty'

      # Configurações de gaps
      [gaps]
      inner.horizontal = 6
      inner.vertical =   6
      outer.left =       6
      outer.bottom =     6
      outer.top =        6
      outer.right =      6

      # Atalhos do modo principal
      [mode.main.binding]
      # Abrir aplicativos
      alt-shift-enter = 'exec-and-forget open -na warp-terminal'
      alt-shift-b = 'exec-and-forget open -a "Brave Browser"'
      alt-shift-t = 'exec-and-forget open -a "Telegram"'
      alt-shift-f = 'exec-and-forget open -a Finder'

      # Gerenciamento de janelas
      alt-q = "close"
      alt-m = 'fullscreen'
      alt-f = 'layout floating tiling'

      # Movimento do foco
      alt-h = 'focus left'
      alt-j = 'focus down'
      alt-k = 'focus up'
      alt-l = 'focus right'

      # Movimento de janelas
      alt-shift-h = 'move left'
      alt-shift-j = 'move down'
      alt-shift-k = 'move up'
      alt-shift-l = 'move right'

      # Redimensionar janelas
      alt-shift-minus = 'resize smart -50'
      alt-shift-equal = 'resize smart +50'

      # Gerenciamento de workspaces
      alt-1 = 'workspace 1'
      alt-2 = 'workspace 2'
      alt-3 = 'workspace 3'
      alt-4 = 'workspace 4'
      alt-5 = 'workspace 5'
      alt-6 = 'workspace 6'
      alt-7 = 'workspace 7'
      alt-8 = 'workspace 8'
      alt-9 = 'workspace 9'

      # Mover janelas para workspaces
      alt-shift-1 = 'move-node-to-workspace --focus-follows-window 1'
      alt-shift-2 = 'move-node-to-workspace --focus-follows-window 2'
      alt-shift-3 = 'move-node-to-workspace --focus-follows-window 3'
      alt-shift-4 = 'move-node-to-workspace --focus-follows-window 4'
      alt-shift-5 = 'move-node-to-workspace --focus-follows-window 5'
      alt-shift-6 = 'move-node-to-workspace --focus-follows-window 6'
      alt-shift-7 = 'move-node-to-workspace --focus-follows-window 7'
      alt-shift-8 = 'move-node-to-workspace --focus-follows-window 8'
      alt-shift-9 = 'move-node-to-workspace --focus-follows-window 9'

      # Navegação entre workspaces
      alt-tab = 'workspace-back-and-forth'
      alt-shift-tab = 'move-workspace-to-monitor --wrap-around next'

      # Entrar no modo passthrough para digitar caracteres especiais
      alt-p = 'mode passthrough'

      # Entrar no modo service
      alt-shift-semicolon = 'mode service'

      # Atalhos do modo service
      [mode.service.binding]
      # Recarregar config e sair do modo service
      esc = ['reload-config', 'mode main']

      # Resetar layout
      r = ['flatten-workspace-tree', 'mode main']

      # Alternar layout flutuante/tiling
      f = ['layout floating tiling', 'mode main']

      # Fechar todas as janelas exceto a atual
      backspace = ['close-all-windows-but-current', 'mode main']

      # Juntar com janelas adjacentes
      alt-shift-h = ['join-with left', 'mode main']
      alt-shift-j = ['join-with down', 'mode main']
      alt-shift-k = ['join-with up', 'mode main']
      alt-shift-l = ['join-with right', 'mode main']

      # Modo passthrough para permitir digitar caracteres especiais (ex.: letras polonesas)
      # Entra com 'alt-p' e sai com 'alt-p' ou 'esc'.
      [mode.passthrough.binding]
      alt-p = 'mode main'
      esc = 'mode main'

      # Regras de detecção de janelas
      [[on-window-detected]]
      if.app-id = 'com.brave.Browser'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-id = 'WezTerm'
      run = 'move-node-to-workspace 2'

      [[on-window-detected]]
      if.app-id = 'com.tdesktop.Telegram'
      run = 'move-node-to-workspace 3'

      [[on-window-detected]]
      if.app-id = 'com.obsproject.obs-studio'
      run = 'move-node-to-workspace 4'

      [[on-window-detected]]
      if.app-id = 'us.zoom.xos'
      run = 'move-node-to-workspace 5'
    '';
  };
}

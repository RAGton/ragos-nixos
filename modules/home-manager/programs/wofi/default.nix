# ==============================================================================
# Módulo: Wofi (Home Manager)
# Autor: rag
#
# O que é:
# - Configuração declarativa do launcher Wofi.
#
# Por quê:
# - Mantém launcher opcional para setups sem DMS.
#
# Como:
# - Só habilita Wofi quando DMS não está ativo.
#
# Riscos:
# - Se habilitado junto de outro launcher, gera duplicação de atalhos/fluxo.
# ==============================================================================
{ config, lib, ... }:
let
  dmsEnabled =
    (config.rag.rice.dmsUpstream.enable or false)
    || (config.rag.rice.dms.enable or false)
    || (config.programs.dank-material-shell.enable or false);
in
{
  config = lib.mkIf (!dmsEnabled) {
    programs.wofi = {
      enable = true;

    settings = {
      # Aparência
      width            = "42%";
      height           = "45%";
      location         = "center";
      no_actions       = true;
      halign           = "fill";
      orientation      = "vertical";
      columns          = 1;
      line_wrap        = "word";

      # Comportamento
      insensitive      = true;       # busca case-insensitive
      allow_markup     = true;
      allow_images     = true;
      image_size       = 28;
      normal_window    = false;      # flutuante (sem decoração Hyprland)
      layer            = "overlay";  # sobre tudo

      # Navegação estilo Vim
      key_up           = "Ctrl-k";
      key_down         = "Ctrl-j";
      key_expand       = "Ctrl-l";
      key_hide_search  = "Escape";

      prompt           = " Buscar...";

      # Sem terminal popup (usa o que está no PATH)
      term             = "warp-terminal";

      # Ícones
      show_all         = false;
      print_command    = false;
      gtk_dark         = true;
    };

    # CSS: TokyoNight Storm — alinhado com a paleta do DMS/Hyprland
      style = ''
      /* ── Variáveis ─────────────────────────────────────── */
      @define-color bg0     #1a1b26;   /* fundo principal */
      @define-color bg1     #24283b;   /* fundo itens */
      @define-color bg2     #292e42;   /* fundo selecionado */
      @define-color fg0     #c0caf5;   /* texto principal */
      @define-color fg1     #a9b1d6;   /* texto secundário */
      @define-color accent  #7aa2f7;   /* azul destaque */
      @define-color green   #9ece6a;
      @define-color red     #f7768e;
      @define-color orange  #ff9e64;
      @define-color border  rgba(122, 162, 247, 0.35);

      /* ── Janela ────────────────────────────────────────── */
      window {
        background-color: alpha(@bg0, 0.92);
        border:           2px solid @border;
        border-radius:    14px;
        font-family:      "Monocraft", sans-serif;
        font-size:        14px;
        color:            @fg0;
      }

      /* ── Conteúdo principal ────────────────────────────── */
      #outer-box {
        margin:           8px;
        padding:          6px;
      }

      #inner-box {
        background:       transparent;
      }

      /* ── Campo de busca ────────────────────────────────── */
      #input {
        background-color: @bg1;
        border:           1px solid @border;
        border-radius:    10px;
        color:            @fg0;
        padding:          8px 14px;
        margin-bottom:    6px;
        font-size:        14px;
        caret-color:      @accent;
        outline:          none;
      }

      #input:focus {
        border-color:     @accent;
        box-shadow:       0 0 0 2px alpha(@accent, 0.25);
      }

      #input > * {
        color:            @fg0;
      }

      /* ── Lista de resultados ───────────────────────────── */
      #scroll {
        background:       transparent;
        margin:           2px 0;
      }

      /* ── Cada entrada ──────────────────────────────────── */
      #entry {
        background-color: transparent;
        border-radius:    8px;
        padding:          6px 10px;
        margin:           2px 0;
        color:            @fg1;
        transition:       background-color 0.1s ease;
      }

      #entry:hover {
        background-color: @bg1;
        color:            @fg0;
      }

      /* Selecionada */
      #entry:selected,
      #entry.selected {
        background-color: @bg2;
        color:            @accent;
        border-left:      3px solid @accent;
        border-radius:    0 8px 8px 0;
      }

      /* ── Texto interno ─────────────────────────────────── */
      #text {
        font-size:        14px;
        margin:           0 4px;
      }

      #text:selected {
        color: @accent;
        font-weight: bold;
      }

      /* ── Ícones ────────────────────────────────────────── */
      #img {
        border-radius:    6px;
        margin-right:     6px;
        padding:          2px;
      }

      /* ── Barra de rolagem ──────────────────────────────── */
      scrollbar {
        background-color: transparent;
        border:           none;
        min-width:        4px;
      }

      scrollbar slider {
        background-color: alpha(@accent, 0.4);
        border-radius:    8px;
        min-width:        4px;
      }

      scrollbar slider:hover {
        background-color: @accent;
      }
      '';
    };
  };
}

# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar e configurar o `wofi` (launcher para Wayland).
#
# Por quê:
# - Padroniza atalhos e tamanho do launcher entre máquinas.
# - Facilita navegação por teclado (Ctrl-j/Ctrl-k) no estilo Vim.
#
# Como:
# - Habilita `programs.wofi` e define `settings`.
#
# Riscos:
# - Alguns settings podem variar por versão/tema; ajuste se necessário.
# =============================================================================
{ ... }:
{
  # Instala e configura o wofi via Home Manager.
  programs.wofi = {
    enable = true;
    settings = {
      insensitive = true;
      normal_window = true;
      prompt = "Search...";
      width = "40%";
      height = "40%";
      key_up = "Ctrl-k";
      key_down = "Ctrl-j";
    };
  };
}

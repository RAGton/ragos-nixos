# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar o `btop` com preferências simples.
#
# Por quê:
# - Garante monitor de recursos disponível em qualquer máquina.
# - Ativa navegação com teclas estilo Vim para produtividade.
#
# Como:
# - Habilita `programs.btop` e define `settings.vim_keys = true`.
#
# Riscos:
# - Sem riscos relevantes; é uma configuração local do usuário.
# =============================================================================
{ ... }:
{
  # Instala e configura o btop via Home Manager.
  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
    };
  };
}

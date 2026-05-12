# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar o `bat` (cat melhorado com syntax highlight).
#
# Por quê:
# - Garante que o preview do `fzf` e o uso diário tenham uma ferramenta consistente.
#
# Como:
# - Habilita `programs.bat`.
#
# Riscos:
# - Sem riscos relevantes; é uma ferramenta local do usuário.
# =============================================================================
{ ... }:
{
  # Instala o bat via Home Manager.
  programs.bat = {
    enable = true;
  };
}

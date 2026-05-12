# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar o `lazygit`.
# - Configura o pager de git dentro do lazygit para usar `delta`.
#
# Por quê:
# - Padroniza diffs/cores e melhora a leitura durante revisão.
# - Evita ter que configurar o lazygit manualmente por máquina.
#
# Como:
# - Habilita `programs.lazygit` e define `settings.git.pager`.
#
# Riscos:
# - Requer `delta` disponível; se não estiver instalado, o pager pode falhar.
# =============================================================================
{ ... }:
{
  # Instala e configura o lazygit via Home Manager.
  programs.lazygit = {
    enable = true;

    settings = {
      git = {
        pager = {
          colorArg = "always";
          pager = "delta --color-only --dark --paging=never";
        };
      };
    };
  };
}

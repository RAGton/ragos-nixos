# =============================================================================
# Autor: rag
#
# O que é:
# - Placeholder do módulo do Brave no Home Manager.
#
# Por quê:
# - Mantido no repo como referência/compatibilidade, mas o navegador principal é o Zen Browser.
#
# Como:
# - Não aplica configuração; módulo propositalmente vazio.
#
# Riscos:
# - Se alguém importar esperando instalar o Brave, nada será instalado.
# =============================================================================
{
  pkgs,
  ...
}:
{
  # Módulo desabilitado. Use zen-browser como navegador principal.
}

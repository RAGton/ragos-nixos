# =============================================================================
# Autor: rag
#
# O que é:
# - Stub do módulo do `tmux` no Home Manager.
#
# Por quê:
# - Este repo migrou o “fluxo tmux” para o `zellij`.
# - Manter este arquivo evita quebrar imports antigos em hosts/perfis.
#
# Como:
# - Mantém `programs.tmux.enable = false` explicitamente.
#
# Riscos:
# - Se alguém esperar `tmux` ativo, vai precisar reativar em um módulo dedicado.
# =============================================================================
{ ... }:
{
  # Módulo do tmux descontinuado: a funcionalidade migrou para o módulo do zellij.
  # Mantém um stub inofensivo para imports antigos não quebrarem.
  programs.tmux = {
    enable = false; # intentionally disabled
  };

  # Se você quiser remover este arquivo do repo de vez, apague manualmente.
}

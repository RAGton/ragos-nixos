{ ... }:
{
  # Módulo do tmux descontinuado: a funcionalidade migrou para o módulo do zellij.
  # Mantém um stub inofensivo para imports antigos não quebrarem.
  programs.tmux = {
    enable = false; # intentionally disabled
  };

  # Se você quiser remover este arquivo do repo de vez, apague manualmente.
}

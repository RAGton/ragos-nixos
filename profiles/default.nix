# =============================================================================
# Profiles Manager
# Autor: rag (via AI Maintainer)
#
# Importa todos os profiles disponíveis.
# Cada profile é ativado via opções `rag.profiles.*`.
#
# Nota:
# - Profiles não devem escolher desktop environment diretamente.
# - Desktop é escolhido via `rag.desktop.environment`.
# =============================================================================
{ ... }:
{
  imports = [
    ./desktop.nix
    ./laptop.nix
    ./vm.nix
  ];
}

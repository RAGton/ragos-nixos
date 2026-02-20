# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar e configurar o prompt `starship`.
#
# Por quê:
# - Mantém prompt consistente entre máquinas e shells (com integração no zsh).
# - Exibe contexto de ferramentas (kubernetes, linguagens, etc.) com ícones.
#
# Como:
# - Habilita `programs.starship` e define `settings`.
# - Configura o módulo `kubernetes` para mostrar cluster/namespace com regex de EKS.
#
# Riscos:
# - Ícones dependem de Nerd Fonts.
# - Mostrar contexto do Kubernetes pode ser barulhento se você alternar muito de cluster.
# =============================================================================
{ ... }:
{
  # Starship: prompt configurado via Home Manager.
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      directory = {
        style = "bold lavender";
      };
      aws = {
        disabled = true;
      };
      docker_context = {
        symbol = " ";
      };
      golang = {
        symbol = " ";
      };
      kubernetes = {
        disabled = false;
        style = "bold pink";
        symbol = "󱃾 ";
        format = "[$symbol$context( \($namespace\))]($style)";
        contexts = [
          {
            context_pattern = "arn:aws:eks:(?P<var_region>.*):(?P<var_account>[0-9]{12}):cluster/(?P<var_cluster>.*)";
            context_alias = "$var_cluster";
          }
        ];
      };
      helm = {
        symbol = " ";
      };
      gradle = {
        symbol = " ";
      };
      java = {
        symbol = " ";
      };
      kotlin = {
        symbol = " ";
      };
      lua = {
        symbol = " ";
      };
      package = {
        symbol = " ";
      };
      php = {
        symbol = " ";
      };
      python = {
        symbol = " ";
      };
      rust = {
        symbol = " ";
      };
      terraform = {
        symbol = " ";
      };
      right_format = "$kubernetes";
    };
  };
}

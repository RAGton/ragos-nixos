# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar e configurar o `atuin` (histórico de shell com sync/opções avançadas).
#
# Por quê:
# - Padroniza a experiência de busca no histórico entre máquinas.
# - Evita depender de configuração manual por host.
#
# Como:
# - Habilita `programs.atuin` e define settings/flags.
#
# Riscos:
# - Dependendo da configuração/conta do atuin, pode haver sync de histórico (estado fora do Nix store).
# =============================================================================
{ ... }:
{
  # Instala e configura o atuin via Home Manager.
  programs.atuin = {
    enable = true;
    settings = {
      inline_height = 25;
      invert = true;
      records = true;
      search_mode = "skim";
      secrets_filter = true;
      style = "compact";
    };
    flags = [ "--disable-up-arrow" ];
  };
}

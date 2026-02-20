{ pkgs, ... }:
{
  # =============================================================================
  # Autor: rag
  #
  # O que é:
  # - Módulo Home Manager para instalar `saml2aws` e definir variáveis padrão de sessão.
  #
  # Por quê:
  # - Padroniza o workflow de autenticação AWS via SAML.
  # - Evita ter que exportar variáveis manualmente a cada sessão.
  #
  # Como:
  # - Adiciona `pkgs.saml2aws` em `home.packages`.
  # - Define `home.sessionVariables` (região e duração de sessão).
  #
  # Riscos:
  # - `AWS_REGION` e duração podem não ser válidas para todos os perfis/contas.
  # - Variáveis globais podem sobrescrever valores específicos em projetos.
  # =============================================================================

  # Garante que o pacote saml2aws esteja instalado.
  home.packages = [ pkgs.saml2aws ];

  # Define defaults via variáveis de ambiente.
  home.sessionVariables = {
    AWS_REGION = "eu-west-1";
    SAML2AWS_SESSION_DURATION = "3600";
  };
}

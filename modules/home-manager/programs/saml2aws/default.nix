{ pkgs, ... }:
{
  # Garante que o pacote saml2aws esteja instalado
  home.packages = [ pkgs.saml2aws ];

  # Define a duração da sessão via variáveis de ambiente
  home.sessionVariables = {
    AWS_REGION = "eu-west-1";
    SAML2AWS_SESSION_DURATION = "3600";
  };
}

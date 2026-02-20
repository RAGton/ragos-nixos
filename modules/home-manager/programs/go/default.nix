# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar `go` e definir GOPATH/GOBIN do usuário.
#
# Por quê:
# - Padroniza variáveis de ambiente e PATH para tooling Go.
# - Evita inconsistências quando cada host configura Go “na mão”.
#
# Como:
# - Define `programs.go.env` com `GOPATH` e `GOBIN`.
# - Adiciona `$HOME/go/bin` ao `home.sessionPath`.
#
# Riscos:
# - Se você usar um GOPATH diferente manualmente, pode conflitar com este padrão.
# =============================================================================
{ config, ... }:
let
  GOPATH = "${config.home.homeDirectory}/go";
  GOBIN = "${GOPATH}/bin";
in
{
  # Instala e configura o Golang via módulo do Home Manager
  programs.go = {
    enable = true;
    env = { inherit GOBIN GOPATH; };
  };

  # Garante o bin do Go no PATH.
  home.sessionPath = [
    "$HOME/go/bin"
  ];
}

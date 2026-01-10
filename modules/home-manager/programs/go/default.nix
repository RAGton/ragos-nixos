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

  # Garante o bin do Go no PATH
  home.sessionPath = [
    "$HOME/go/bin"
  ];
}

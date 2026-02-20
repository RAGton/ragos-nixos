# Home Manager: Scripts (binários do usuário)
# Autor: rag
#
# O que é
# - Publica scripts versionados do repo em `~/.local/bin`.
#
# Por quê
# - Scripts são parte do ambiente (day-2 ops, atalhos, automações) e devem ser reprodutíveis.
#
# Como
# - `home.file.".local/bin"` com `recursive = true` copia o diretório `./bin`.
# - Em Darwin, adiciona `~/.local/bin` ao PATH da sessão.
#
# Riscos
# - Scripts precisam ter dependências disponíveis (via Nix) e não devem assumir paths fixos.
{
  pkgs,
  lib,
  ...
}:
{
  # Publica scripts a partir do store do Home Manager.
  home.file = {
    ".local/bin" = {
      recursive = true;
      source = ./bin;
    };
  };

  # Configuração condicional para sistemas Darwin.
  home.sessionPath = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isDarwin [
      "$HOME/.local/bin"
    ])
  ];
}

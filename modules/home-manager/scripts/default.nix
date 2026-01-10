{
  pkgs,
  lib,
  ...
}:
{
  # Publica scripts a partir do store do Home Manager
  home.file = {
    ".local/bin" = {
      recursive = true;
      source = ./bin;
    };
  };

  # Configuração condicional para sistemas Darwin
  home.sessionPath = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isDarwin [
      "$HOME/.local/bin"
    ])
  ];
}

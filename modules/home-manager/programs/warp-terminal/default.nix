{ pkgs, lib, ... }:
{
  # Fornece um módulo "warp-terminal".
  # Instala o pacote `warp-terminal` para garantir o binário correto via Nix.
  home.packages = [ pkgs.warp-terminal ];

  # Nota: não habilitamos `programs.wezterm` aqui porque a escolha foi pelo
  # `warp-terminal`, que já provê seu próprio binário.

}

{ config, pkgs, ... }:

{
  home.username = "rag";
  home.homeDirectory = "/home/rag";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # Exemplo: apps do usuário
  home.packages = with pkgs; [
    firefox
    neovim
    git
    warp-terminal
  ];
}

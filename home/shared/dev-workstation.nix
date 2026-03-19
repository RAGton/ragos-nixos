{ pkgs, ... }:
{
  # Base compartilhada entre perfis desktop focados em dev/estudo.
  programs.home-manager.enable = true;

  rag.rice.dmsUpstream.enable = true;

  programs.jupyter = {
    enable = true;
    kernels = {
      python = true;
      c = true;
      rust = true;
      cpp = true;
      bash = true;
      dotnet = false;
      node = false;
    };
  };

  rag.vscode = {
    enable = true;
    edition = "insiders";
    delivery = "managed-download";
  };

  home.packages = with pkgs; [
    steam
    gamemode
    moonlight-qt
  ];

  xdg.configFile."dms/settings.json" = {
    source = ../../files/dms/settings.json;
    force = true;
  };

  xdg.configFile."dms/session.json" = {
    source = ../../files/dms/session.json;
    force = true;
  };

  home.stateVersion = "26.05";

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}

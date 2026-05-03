{ ... }:
{
  # Base compartilhada entre perfis desktop focados em dev/estudo.
  programs.home-manager.enable = true;

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

  kryonix.vscode = {
    enable = true;
    edition = "insiders";
    delivery = "managed-download";
  };

  home.stateVersion = "26.05";

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}

{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Configuração de tema GTK
  gtk = {
    enable = true;
    colorScheme = "dark";

    # Tema padrão: Breeze Dark (pode ser sobrescrito por temas como Bart)
    theme = lib.mkDefault {
      name = "Breeze-Dark";
      package = pkgs.kdePackages.breeze-gtk;
    };

    iconTheme = lib.mkDefault {
      name = "breeze-dark";
      package = pkgs.kdePackages.breeze-icons;
    };

    cursorTheme = {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
      size = 24;
    };

    font = {
      name = "Roboto";
      size = 11;
    };

    gtk3 = {
      bookmarks = [
        "file://${config.home.homeDirectory}/Documents"
        "file://${config.home.homeDirectory}/Downloads"
        "file://${config.home.homeDirectory}/Pictures"
        "file://${config.home.homeDirectory}/Videos"
        "file://${config.home.homeDirectory}/Downloads/temp"
        "file://${config.home.homeDirectory}/Documents/repositories"
      ];
    };
  };
}

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

    # Tema padrão do stack Hyprland/DMS: base GNOME/Libadwaita.
    theme = lib.mkDefault {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = lib.mkDefault {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
      size = 24;
    };

    font = {
      name = "Monocraft";
      size = 11;
      package = pkgs.monocraft;
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

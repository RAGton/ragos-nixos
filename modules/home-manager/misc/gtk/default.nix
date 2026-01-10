{
  config,
  pkgs,
  ...
}:
{
  # Configuração de tema GTK
  gtk = {
    enable = true;
    colorScheme = "dark";
    theme = {
      name = "catppuccin-macchiato-lavender-compact";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        variant = "macchiato";
        size = "compact";
      };
    };
    iconTheme = {
      name = "kora";
      package = pkgs.kora-icon-theme;
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

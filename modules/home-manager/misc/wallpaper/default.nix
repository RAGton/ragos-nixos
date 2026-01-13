{ lib, config, ... }:

{
  options.wallpaper = lib.mkOption {
    type = lib.types.path;
    default = ../../../../files/wallpaper/wallpaper.png;
    description = "Default wallpaper image path";
  };

  options.wallpapers = lib.mkOption {
    type = lib.types.listOf lib.types.path;
    default = [ ../../../../files/wallpaper/wallpaper.png ];
    description = "Lista de wallpapers para instalar em ~/.local/share/wallpapers (galeria).";
  };

  config = {
    home.file.".config/wallpaper.png".source = config.wallpaper;

    # Galeria de wallpapers: adiciona todos os arquivos declarados em `wallpapers`.
    # Obs.: nomes repetidos (mesmo basename) vão colidir.
    xdg.dataFile = lib.listToAttrs (
      map (
        p:
        {
          name = "wallpapers/${builtins.baseNameOf p}";
          value.source = p;
        }
      ) config.wallpapers
    );
  };
}

{ lib, config, ... }:

{
  options.wallpaper = lib.mkOption {
    type = lib.types.path;
    default = ../../../../files/wallpaper/wallpaper.png;
    description = "Default wallpaper image path";
  };

  config = {
    home.file.".config/wallpaper.png".source = config.wallpaper;
  };
}

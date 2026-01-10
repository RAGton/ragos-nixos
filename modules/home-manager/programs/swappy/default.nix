{ pkgs, ... }:
{
  # Garante que o pacote swappy esteja instalado
  home.packages = [ pkgs.swappy ];

  # Importa a configuração do swappy a partir do store do Home Manager
  xdg.configFile = {
    "swappy/config".text = ''
      [Default]
      save_dir=$HOME/Pictures
      save_filename_format=screenshot-%Y%m%d-%H%M%S.png
    '';
  };
}

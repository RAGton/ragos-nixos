{ ... }:
{
  # Instala o bat via Home Manager
  programs.bat = {
    enable = true;
  };

  # Habilita tema Catppuccin para o bat
  catppuccin.bat.enable = true;
}

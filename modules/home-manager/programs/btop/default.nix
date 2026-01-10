{ ... }:
{
  # Instala o btop via módulo do Home Manager
  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
    };
  };

  # Habilita o tema Catppuccin para o btop.
  catppuccin.btop.enable = true;
}

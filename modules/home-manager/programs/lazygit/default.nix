{ ... }:
{
  # Instala o lazygit via módulo do Home Manager
  programs.lazygit = {
    enable = true;

    settings = {
      git = {
        pager = {
          colorArg = "always";
          pager = "delta --color-only --dark --paging=never";
        };
      };
    };
  };
}

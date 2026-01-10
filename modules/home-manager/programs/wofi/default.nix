{ ... }:
{
  # Instala o wofi via módulo do Home Manager
  programs.wofi = {
    enable = true;
    settings = {
      insensitive = true;
      normal_window = true;
      prompt = "Search...";
      width = "40%";
      height = "40%";
      key_up = "Ctrl-k";
      key_down = "Ctrl-j";
    };
  };
}

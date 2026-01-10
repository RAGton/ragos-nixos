{ ... }:
{
  # Gerencia o serviço do swaync via Home Manager
  services.swaync = {
    enable = true;
    settings = {
      control-center-height = 800;
      control-center-width = 400;
      fit-to-screen = false;
      notification-grouping = false;
      notification-window-width = 350;
      notification-icon-size = 32;
      notification-action-filter = {
        hide-brave-settings = {
          desktop-entry = "brave-browser";
          use-regex = false;
          id-matcher = "settings";
          text-matcher = "Settings";
        };
      };
      scripts = {
        focus-window = {
          exec = "bash -c 'hyprctl dispatch focuswindow class:\"$SWAYNC_DESKTOP_ENTRY\"'";
          app-name = ".*";
          run-on = "action";
        };
      };
    };
  };

  # Habilita o tema Catppuccin para o swaync.
  catppuccin.swaync = {
    enable = true;
    font = "Roboto Nerd Font";
  };
}

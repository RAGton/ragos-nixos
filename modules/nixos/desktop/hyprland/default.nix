{ pkgs, ... }:
{
  # Habilita o display manager GDM
  services.displayManager.gdm.enable = true;

  # Chama dbus-update-activation-environment no login
  services.xserver.updateDbusEnvironment = true;

  # Habilita suporte a Bluetooth
  services.blueman.enable = true;

  # Habilita Hyprland
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-wlr;
    withUWSM = true;
  };

  # Habilita serviços de segurança
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;
  security.pam.services = {
    hyprlock = { };
    gdm.enableGnomeKeyring = true;
  };

  # Lista de pacotes específicos do Hyprland
  environment.systemPackages = with pkgs; [
    file-roller # gerenciador de arquivos compactados
    gnome-calculator
    gnome-pomodoro
    gnome-text-editor
    loupe # visualizador de imagens
    nautilus # gerenciador de arquivos
    seahorse # gerenciador de keyring
    totem # player de vídeo

    brightnessctl
    grim
    grimblast
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    libnotify
    networkmanagerapplet
    pamixer
    pavucontrol
    slurp
    wf-recorder
    wlr-randr
    wlsunset
  ];
}

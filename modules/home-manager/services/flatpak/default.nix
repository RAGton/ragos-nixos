{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    services.flatpak = {
      enable = true;
      packages = [ 
        "app.zen_browser.zen"
        "io.github.shiftey.Desktop"
        "io.github.shonebinu.Brief"
        "com.anydesk.Anydesk"
        "com.rustdesk.RustDesk"
        "com.ranfdev.DistroShelf"
        "com.github.tchx84.Flatseal"
        "io.github.flattool.Warehouse"
        "org.kde.filelight"
        "com.rtosta.zapzap"
        "org.libreoffice.LibreOffice"
        "org.gimp.GIMP"
        ];

      uninstallUnmanaged = true;
      update.auto.enable = true;
    };

    home.packages = [ pkgs.flatpak ];

    xdg.systemDirs.data = [
      "/var/lib/flatpak/exports/share"
      "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
    ];
  };
}
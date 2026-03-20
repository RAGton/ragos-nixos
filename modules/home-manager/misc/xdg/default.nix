{
  pkgs,
  ...
}:
{
  xdg = {
    enable = true;

    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.kde.dolphin.desktop" ];
        "application/x-directory" = [ "org.kde.dolphin.desktop" ];
        "application/zip" = [ "org.kde.ark.desktop" ];
        "application/x-7z-compressed" = [ "org.kde.ark.desktop" ];
        "application/x-rar" = [ "org.kde.ark.desktop" ];
        "application/vnd.rar" = [ "org.kde.ark.desktop" ];
        "application/x-tar" = [ "org.kde.ark.desktop" ];
        "application/x-compressed-tar" = [ "org.kde.ark.desktop" ];
        "application/x-bzip-compressed-tar" = [ "org.kde.ark.desktop" ];
        "application/x-xz-compressed-tar" = [ "org.kde.ark.desktop" ];
        "application/x-zstd-compressed-tar" = [ "org.kde.ark.desktop" ];
        "application/gzip" = [ "org.kde.ark.desktop" ];
        "application/x-gzip" = [ "org.kde.ark.desktop" ];
        "application/x-bzip" = [ "org.kde.ark.desktop" ];
        "application/x-bzip2" = [ "org.kde.ark.desktop" ];
        "application/x-xz" = [ "org.kde.ark.desktop" ];
        "application/zstd" = [ "org.kde.ark.desktop" ];
      };
      defaultApplicationPackages = [
        pkgs.gnome-text-editor
        pkgs.loupe
        pkgs.totem
        pkgs.kdePackages.dolphin
        pkgs.kdePackages.ark
      ];
    };

    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}

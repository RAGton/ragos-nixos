{
  pkgs,
  ...
}:
let
  imageViewer = pkgs.loupe;
  pdfViewer = pkgs.evince;
  # Keep local media playback without mpv-with-scripts, which pulls yt-dlp ->
  # deno -> rusty-v8 and can compile V8 locally when cache is missing.
  mediaPlayer = pkgs.mpv-unwrapped;
  textEditor = pkgs.gnome-text-editor;
in
{
  xdg = {
    enable = true;

    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.kde.dolphin.desktop" ];
        "application/x-directory" = [ "org.kde.dolphin.desktop" ];
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "text/plain" = [ "org.gnome.TextEditor.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
        "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
        "image/avif" = [ "org.gnome.Loupe.desktop" ];
        "image/heic" = [ "org.gnome.Loupe.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "audio/mpeg" = [ "mpv.desktop" ];
        "audio/flac" = [ "mpv.desktop" ];
        "audio/x-wav" = [ "mpv.desktop" ];
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
        textEditor
        imageViewer
        pdfViewer
        mediaPlayer
        pkgs.kdePackages.dolphin
        pkgs.kdePackages.ark
      ];
    };

    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Os handlers padrão precisam existir de fato no perfil do usuário; só gerar
  # mimeapps.list sem os pacotes correspondentes faz o Dolphin cair no seletor.
  home.packages = [
    textEditor
    imageViewer
    pdfViewer
    mediaPlayer
  ];
}

# Pacote do tema Bart para KDE Plasma
# Baixado da KDE Store: https://store.kde.org/p/2136134
{
  lib,
  stdenvNoCC,
  fetchzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "bart-theme";
  version = "1.0.0";

  # URL da KDE Store para o tema Bart
  # Nota: Este é um exemplo - você precisa verificar o ID correto na KDE Store
  src = fetchzip {
    url = "https://store.kde.org/p/2136134/bart-theme.tar.gz";
    sha256 = lib.fakeSha256; # Será atualizado após primeira build
    stripRoot = false;
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    # Copia todos os arquivos do tema
    if [ -d "plasma" ]; then
      mkdir -p $out/plasma
      cp -r plasma/* $out/plasma/
    fi

    if [ -d "look-and-feel" ]; then
      mkdir -p $out/look-and-feel
      cp -r look-and-feel/* $out/look-and-feel/
    fi

    if [ -d "color-schemes" ] || [ -d "colorschemes" ]; then
      mkdir -p $out/color-schemes
      [ -d "color-schemes" ] && cp -r color-schemes/* $out/color-schemes/
      [ -d "colorschemes" ] && cp -r colorschemes/* $out/color-schemes/
    fi

    if [ -d "icons" ]; then
      mkdir -p $out/icons
      cp -r icons/* $out/icons/
    fi

    if [ -d "aurorae" ]; then
      mkdir -p $out/aurorae
      cp -r aurorae/* $out/aurorae/
    fi

    if [ -d "kvantum" ] || [ -d "Kvantum" ]; then
      mkdir -p $out/kvantum
      [ -d "kvantum" ] && cp -r kvantum/* $out/kvantum/
      [ -d "Kvantum" ] && cp -r Kvantum/* $out/kvantum/
    fi

    if [ -d "gtk" ] || [ -d "themes" ]; then
      mkdir -p $out/gtk
      [ -d "gtk" ] && cp -r gtk/* $out/gtk/
      [ -d "themes" ] && cp -r themes/* $out/gtk/
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "Bart - KDE Plasma Theme";
    homepage = "https://store.kde.org/p/2136134";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}


{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  iconThemeName = lib.attrByPath [ "gtk" "iconTheme" "name" ] null config;
  plasmaEnabled = lib.attrByPath [ "programs" "plasma" "enable" ] false config;

  # Detecta se tema Bart está habilitado
  bartEnabled = lib.attrByPath [ "rag" "theme" "bart" "enable" ] false config;
  kvantumThemeName =
    if bartEnabled then
      lib.attrByPath [ "rag" "theme" "bart" "kvantumTheme" ] "Bart" config
    else
      "breeze";

  qtCtAppearanceConfig = generators.toINI { } {
    Appearance = {
      icon_theme = if iconThemeName != null then iconThemeName else "breeze";
    };
  };

in
{
  home.packages = [
    pkgs.kdePackages.qtstyleplugin-kvantum
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.qt6Packages.qtstyleplugin-kvantum
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct
  ];

  qt = {
    enable = true;
    # Em KDE Plasma, evite qt5ct/qt6ct como platform theme (pode quebrar integração
    # e causar comportamento estranho no Plasma/Qt Quick). Fora do Plasma, qtct é útil.
    platformTheme.name = if plasmaEnabled then "kde" else "qtct";
    # Não force Kvantum globalmente: o Plasma (Qt Quick/Kirigami) pode tentar
    # carregar "kvantum" como estilo QML e quebrar (tela preta, wallpaper).
    # Kvantum continua instalado e configurado em ~/.config/Kvantum/kvantum.kvconfig.
    style.name = "breeze";
  };

  xdg.configFile = {
    qt5ct = {
      target = "qt5ct/qt5ct.conf";
      text = qtCtAppearanceConfig;
    };

    qt6ct = {
      target = "qt6ct/qt6ct.conf";
      text = qtCtAppearanceConfig;
    };

    # Kvantum: configuração é gerenciada pelo módulo do tema (bart/edna)
    # Este arquivo só é criado se nenhum tema estiver ativo
    kvantum = lib.mkIf (!bartEnabled) {
      target = "Kvantum/kvantum.kvconfig";
      text = generators.toINI { } {
        General = {
          theme = kvantumThemeName;
        };
      };
    };
  };
}

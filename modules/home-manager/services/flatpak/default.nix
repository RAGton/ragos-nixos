# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar `flatpak` e declarar uma lista de apps.
# - Ajusta `xdg.systemDirs.data` para expor exports do Flatpak ao desktop.
#
# Por quê:
# - Alguns apps (ex.: Zen Browser) são instalados via Flatpak por conveniência/compat.
# - Mantém a lista de apps e updates de forma declarativa e reproduzível.
#
# Como:
# - Importa `inputs.nix-flatpak.homeManagerModules.nix-flatpak`.
# - Em Linux, habilita `services.flatpak`, instala `pkgs.flatpak` e configura XDG.
#
# Riscos:
# - Flatpaks são estado fora do Nix store; podem falhar sem rede/repo.
# - `uninstallUnmanaged = true` remove flatpaks não declarados (cuidado com apps instalados manualmente).
# =============================================================================
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
        "io.github.shonebinu.Brief"
        "com.anydesk.Anydesk"
        "com.rustdesk.RustDesk"
        "com.ranfdev.DistroShelf"
        "com.github.tchx84.Flatseal"
        "io.github.flattool.Warehouse"
        "com.rtosta.zapzap"
        "org.libreoffice.LibreOffice"
        "org.gimp.GIMP"
        # Notion Desktop (wrapper community no Flathub)
        "notion-app"
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
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
let
  cfg = config.rag.flatpak;
in
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  options.rag.flatpak.enable = lib.mkOption {
    type = lib.types.bool;
    default = !pkgs.stdenv.isDarwin;
    description = "Habilita a integração Flatpak no Home Manager.";
  };

  config = lib.mkIf (!pkgs.stdenv.isDarwin && cfg.enable) {
    services.flatpak = {
      enable = true;
      packages = [
        "app.zen_browser.zen"
        "io.github.shonebinu.Brief"
        "io.github.brunofin.Cohesion"
        "com.anydesk.Anydesk"
        "com.rustdesk.RustDesk"
        "com.ranfdev.DistroShelf"
        "com.github.tchx84.Flatseal"
        "io.github.flattool.Warehouse"
        "com.rtosta.zapzap"
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

# Módulo compartilhado: nixpkgs (overlays + allowUnfree)
#
# Objetivo:
# - Centralizar a configuração de overlays e allowUnfree em um único lugar
# - Reusar no NixOS e no nix-darwin
# - Evitar duplicação (e surpresa) entre system modules e Home Manager
{
  outputs,
  lib,
  isDarwin ? false,
  ...
}:
{
  nixpkgs = {
    overlays =
      [
        outputs.overlays.stable-packages
      ]
      ++ lib.optionals (!isDarwin) [
        outputs.overlays.openrgb-git
        outputs.overlays.drkonqi-ignore-missing-buildid
        outputs.overlays.python312-docs-stub
      ];

    config = {
      allowUnfree = lib.mkDefault true;
    };
  };
}

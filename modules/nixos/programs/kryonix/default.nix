{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.kryonix;
  ragosCompat = pkgs.callPackage ../../../../packages/ragos-cli.nix {
    kryonix-cli = cfg.package;
  };
in
{
  imports = [
    (lib.mkAliasOptionModule [ "programs" "ragos" ] [ "programs" "kryonix" ])
  ];

  options.programs.kryonix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Instala a CLI `kryonix`, usada como fluxo operacional principal do Kryonix.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../../../packages/kryonix-cli.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../../../../packages/kryonix-cli.nix { }";
      description = "Pacote da CLI `kryonix` exposto no PATH do sistema.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      ragosCompat
    ];
  };
}

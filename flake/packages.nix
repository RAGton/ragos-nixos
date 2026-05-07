{ inputs, lib }:
lib.forAllSystems (
  system:
  let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    kryonixCli = pkgs.callPackage ../packages/kryonix-cli.nix { };
    denoCacheOnly = lib.mkDenoCacheOnly pkgs;
  in
  {
    default = kryonixCli;
    kryonix = kryonixCli;
    "deno-cache-only" = denoCacheOnly;
  }
)

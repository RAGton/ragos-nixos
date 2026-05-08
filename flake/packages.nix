{ inputs, lib }:
lib.forAllSystems (
  system:
  let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    kryonixCli = pkgs.callPackage ../packages/kryonix-cli.nix { };
    kryonixHome = pkgs.callPackage ../packages/kryonix-home.nix { };
    denoCacheOnly = lib.mkDenoCacheOnly pkgs;
  in
  {
    default = kryonixCli;
    kryonix = kryonixCli;
    kryonix-home = kryonixHome;
    "deno-cache-only" = denoCacheOnly;
  }
)

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
    kryonixBrainLightrag = pkgs.callPackage ../packages/kryonix-brain-lightrag.nix {
      kryonix-brain-lightrag-src = inputs.kryonix-brain-lightrag;
    };
    denoCacheOnly = lib.mkDenoCacheOnly pkgs;
  in
  {
    default = kryonixCli;
    kryonix = kryonixCli;
    kryonix-home = kryonixHome;
    kryonix-brain-lightrag = kryonixBrainLightrag;
    "deno-cache-only" = denoCacheOnly;
  }
)

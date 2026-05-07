{ inputs, lib }:
lib.forAllSystems (
  system:
  let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    denoCacheOnly = lib.mkDenoCacheOnly pkgs;
    latexShell = pkgs.mkShell {
      packages = with pkgs; [
        texlive.combined.scheme-full
        texlivePackages.latexmk
        texlab
        biber
        texlivePackages.chktex
        ghostscript
        perl
      ];
    };
  in
  {
    default = latexShell;
    latex = latexShell;
    deno = pkgs.mkShell {
      packages = [ denoCacheOnly ];
      shellHook = ''
        echo "Deno is cache-only here: Nix will refuse local builds."
      '';
    };
  }
)

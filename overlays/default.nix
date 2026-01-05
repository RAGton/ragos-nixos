{ inputs, ... }:
{
  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # OpenRGB bleeding-edge (git) pinado em um commit.
  openrgb-git = final: prev: {
    openrgb-git = prev.openrgb.overrideAttrs (old: let
      rev = "2a1b7a9e2e58c82cbd1e64131644bc2b208f9ba2";
    in {
      pname = "openrgb";
      version = "git-${builtins.substring 0 8 rev}";
      src = prev.fetchFromGitHub {
        owner = "CalcProgrammer1";
        repo = "OpenRGB";
        inherit rev;
        fetchSubmodules = true;
        hash = "sha256-mpDcFWB41wfjHkMydvJaQlkDXuMMUE1A3F1PO5mweeE=";
      };

      # Patches do nixpkgs podem não aplicar no master atual.
      patches = [ ];

      # Evita falhas de substituição herdadas do nixpkgs (scripts mudam no master).
      postPatch = ''
        patchShebangs scripts/build-udev-rules.sh
      '';

      postInstall = (old.postInstall or "") + ''
        if [ -d "$out/lib/udev/rules.d" ]; then
          for f in "$out"/lib/udev/rules.d/*.rules; do
            [ -e "$f" ] || continue
            substituteInPlace "$f" --replace-warn "/usr/bin/env" "${prev.coreutils}/bin/env"
          done
        fi
      '';
    });
  };
}

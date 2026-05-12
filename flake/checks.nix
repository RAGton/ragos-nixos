{ inputs, lib }:
let
  formattingCheck =
    lib.checkPkgs.runCommand "nixfmt-check"
      {
        nativeBuildInputs = [
          lib.checkPkgs.findutils
          lib.checkPkgs.nixfmt
        ];
        src = ../.;
      }
      ''
        cd "$src"
        ${lib.checkPkgs.findutils}/bin/find . -type f -name '*.nix' -print0 \
          | ${lib.checkPkgs.findutils}/bin/xargs -0 ${lib.checkPkgs.nixfmt}/bin/nixfmt --check
        mkdir -p "$out"
      '';
in
{
  x86_64-linux = {
    formatting = formattingCheck;

    "nixos-inspiron-eval" =
      lib.checkPkgs.writeText "nixos-inspiron-drvpath" "${lib.stripContext inputs.self.nixosConfigurations.inspiron.config.system.build.toplevel.drvPath}\n";
    "nixos-inspiron-nina-eval" =
      lib.checkPkgs.writeText "nixos-inspiron-nina-drvpath" "${lib.stripContext inputs.self.nixosConfigurations.inspiron-nina.config.system.build.toplevel.drvPath}\n";
    "nixos-glacier-eval" =
      lib.checkPkgs.writeText "nixos-glacier-drvpath" "${lib.stripContext inputs.self.nixosConfigurations.glacier.config.system.build.toplevel.drvPath}\n";
    "nixos-iso-eval" =
      lib.checkPkgs.writeText "nixos-iso-drvpath" "${lib.stripContext inputs.self.nixosConfigurations.iso.config.system.build.toplevel.drvPath}\n";

    "home-rocha-inspiron-eval" = lib.checkPkgs.writeText "home-rocha-inspiron-drvpath" "${
      lib.stripContext inputs.self.homeConfigurations."rocha@inspiron".activationPackage.drvPath
    }\n";
    "home-rocha-glacier-eval" = lib.checkPkgs.writeText "home-rocha-glacier-drvpath" "${
      lib.stripContext inputs.self.homeConfigurations."rocha@glacier".activationPackage.drvPath
    }\n";
    "home-nina-inspiron-nina-eval" = lib.checkPkgs.writeText "home-nina-inspiron-nina-drvpath" "${
      lib.stripContext inputs.self.homeConfigurations."nina@inspiron-nina".activationPackage.drvPath
    }\n";
  };
}

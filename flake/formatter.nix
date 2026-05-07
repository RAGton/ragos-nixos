{ inputs, lib }: lib.forAllSystems (system: (import inputs.nixpkgs { inherit system; }).nixfmt)

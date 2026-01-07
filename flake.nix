{
  description = "Configurações NixOS e nix-darwin das minhas máquinas";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Módulos de hardware do NixOS (nixos-hardware)
    hardware.url = "github:nixos/nixos-hardware";

    # Tema global Catppuccin
    catppuccin.url = "github:catppuccin/nix";

    # Gerenciador declarativo de Flatpak
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=v0.6.0";

    # Gerenciador declarativo do KDE Plasma
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Nix Darwin (para máquinas macOS)
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      catppuccin,
      darwin,
      home-manager,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      # Definição de usuários
      users = {
        rag = {
          avatar = ./files/avatar/face;
          email = "g.rocha@estudante.ifmt.edu.br";
          fullName = "Gabriel Aguiar Rocha";
          gitKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINAFi1/wOXb839pka/DhBlk0FfJWDy2M6r1ho7ejkNuu gabriel.rag@proton.me";
          name = "rag";
        };
      };

      # Função para configuração de sistema (NixOS)
      mkNixosConfiguration =
        hostname: username:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs hostname;
            userConfig = users.${username};
            nixosModules = "${self}/modules/nixos";
          };
          modules = [ ./hosts/${hostname} ];
        };

      # Função para configuração de sistema (nix-darwin)
      mkDarwinConfiguration =
        hostname: username:
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs outputs hostname;
            userConfig = users.${username};
            darwinModules = "${self}/modules/darwin";
          };
          modules = [ ./hosts/${hostname} ];
        };

      # Função para configuração do Home Manager
      mkHomeConfiguration =
        system: username: hostname:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          extraSpecialArgs = {
            inherit inputs outputs;
            userConfig = users.${username};
            nhModules = "${self}/modules/home-manager";
          };
          modules = [
            ./home/${username}/${hostname}
            catppuccin.homeModules.catppuccin
          ];
        };
    in
    {
      nixosConfigurations = {
        inspiron = mkNixosConfiguration "inspiron" "rag";
        Glacier = mkNixosConfiguration "Glacier" "rag";
      };

      homeConfigurations = {
        "rag@inspiron" = mkHomeConfiguration "x86_64-linux" "rag" "inspiron";
        "rag@Glacier" = mkHomeConfiguration "x86_64-linux" "rag" "Glacier";
      };

      overlays = import ./overlays { inherit inputs; };
    };
}

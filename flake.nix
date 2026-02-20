# Flake principal do repo
# Autor: rag
#
# O que é
# - Fonte única de verdade (flakes) para NixOS e nix-darwin das máquinas.
# - Centraliza inputs, overlays e outputs (nixosConfigurations/homeConfigurations).
#
# Por quê
# - Reprodutibilidade: mesmos inputs -> mesmo resultado.
# - Portabilidade: mesma base para Linux e macOS.
# - Manutenção: entradas e saídas claras num único lugar.
#
# Como
# - Inputs: nixpkgs (unstable + stable), home-manager, plasma-manager, nix-darwin etc.
# - Outputs: funções `mkNixosConfiguration`/`mkDarwinConfiguration` para montar hosts.
#
# Riscos
# - Atualizar pins (nixpkgs/home-manager) pode introduzir regressões; prefira atualizar de forma incremental.
{
  description = "Configurações NixOS e nix-darwin das minhas máquinas";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Módulos de hardware do NixOS (nixos-hardware)
    hardware.url = "github:nixos/nixos-hardware";

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

    # Particionamento declarativo (usado na ISO instaladora)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tema (Plasma/GTK/Icons): Edna
    # Repo: https://gitlab.com/jomada/edna
    # Obs.: usamos flake=false porque é um repositório de assets, não um flake Nix.
    edna-theme = {
      url = "git+https://gitlab.com/jomada/edna";
      flake = false;
    };

    # Tema Bart: instalado via KDE Store (não disponível como flake)
    # Para usar: System Settings > Get New Global Themes > Busque "Bart"

    # DankMaterialShell (DMS) - Rice para Hyprland (assets/configs)
    # Repo: https://github.com/AvengeMedia/DankMaterialShell
    # Obs.: flake=false porque é um repositório de dotfiles/configs, não um flake Nix.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      flake = false;
    };

    # DankMaterialShell (DMS) como flake (para acessar packages/modules upstream)
    dms-flake = {
      url = "github:AvengeMedia/DankMaterialShell";
      flake = true;
    };
  };

  outputs =
    {
      self,
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
          avatar = ./files/avatar/ragton.jpeg;
          email = "gabriel.rag@proton.me";
          fullName = "Gabriel Aguiar Rocha";
          gitKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFLt1vJ3bluf8Df37jUUktr1MwMzQctci8wi3z4O9AGP gabriel.rag@proton.me";
          name = "rag";
        };

        # Usuário adicional (ex.: para separar perfil pessoal/trabalho ou testar configs)
        rocha = {
          avatar = ./files/avatar/ragton.jpeg;
          email = "gabriel.rag@proton.me";
          fullName = "Rocha";
          name = "rocha";
        };
      };

      # Função para configuração de sistema (NixOS)
      mkNixosConfiguration =
        hostname: username:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs hostname;
            isDarwin = false;
            userConfig = users.${username};
            nixosModules = "${self}/modules/nixos";
          };
          modules = [
            ./hosts/${hostname}
            ./lib/options.nix     # Sistema de opções rag.* (v2 migration)
            ./desktop/manager.nix # Desktop auto-import (v2 migration)
            ./features            # Features modulares (v2 migration)
            ./profiles            # Profiles composáveis (v2 migration)
          ];
        };

      # Função para configuração de sistema (nix-darwin)
      mkDarwinConfiguration =
        hostname: username:
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs outputs hostname;
            isDarwin = true;
            userConfig = users.${username};
            darwinModules = "${self}/modules/darwin";
          };
          modules = [ ./hosts/${hostname} ];
        };

      # Função para configuração do Home Manager
      mkHomeConfiguration =
        system: username: hostname:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              outputs.overlays.stable-packages
              outputs.overlays.warp-terminal-latest
              # Workaround: nixpkgs unstable sometimes fails building xeus-cling due to
              # notebook-based install checks (papermill). Disable checks so HM can switch.
              outputs.overlays.xeus-cling-no-checks
            ];
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs outputs;
            userConfig = users.${username};
            nhModules = "${self}/modules/home-manager";
          };
          modules = [
            ./home/${username}/${hostname}
          ];
        };
    in
    {
      nixosConfigurations = {
        inspiron = mkNixosConfiguration "inspiron" "rocha";
        Glacier = mkNixosConfiguration "Glacier" "rag";

        # Live ISO instaladora (multi-host)
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs outputs;
            hostname = "iso";
            isDarwin = false;
            nixosModules = "${self}/modules/nixos";
            # A ISO não precisa de userConfig; se algum módulo exigir, ajustamos no host iso.
          };
          modules = [ ./hosts/iso ];
        };
      };

      homeConfigurations = {
        "rag@inspiron" = mkHomeConfiguration "x86_64-linux" "rag" "inspiron";
        "rag@Glacier" = mkHomeConfiguration "x86_64-linux" "rag" "Glacier";

        "rocha@inspiron" = mkHomeConfiguration "x86_64-linux" "rocha" "inspiron";
      };

      overlays = import ./overlays { inherit inputs; };
    };
}

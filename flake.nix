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
# - Inputs: nixpkgs (unstable + stable), home-manager, nix-darwin etc.
# - Outputs: funções `mkNixosConfiguration`/`mkDarwinConfiguration` para montar hosts.
#
# Riscos
# - Atualizar pins (nixpkgs/home-manager) pode introduzir regressões; prefira atualizar de forma incremental.
{
  description = "Infraestrutura declarativa NixOS/nix-darwin multi-host/multi-user com Flakes, Home Manager, Flatpak, VS Code, Jupyter e toolchains de desenvolvimento.";

  # =============================
  # Inputs (flakes externos)
  # =============================
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

    # OpenAI Codex CLI (coding agent que roda localmente)
    codex = {
      url = "github:openai/codex";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # =============================
  # Outputs (sistemas, usuários, overlays)
  # =============================
  outputs = { self, darwin, home-manager, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;

      # =============================
      # Usuários declarados (multi-user ready)
      # =============================
      users = {
        rocha = {
          avatar = ./files/avatar/ragton.jpeg;
          email = "gabriel.rag@proton.me";
          gitKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGIlk6EkcD7aTDYYmZVr636Jo1Vz9zDqUWiwzEpBgmMY gabriel.rag@proton.me";
          gitSigningKeyPath = ".ssh/id_ed25519_git_signing";
          fullName = "Gabriel Rocha";
          name = "rocha";
        };
        # Adicione outros usuários aqui
      };

      # =============================
      # Funções helpers para sistemas e home
      # =============================
      mkNixosConfiguration = hostname: username:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs hostname;
            isDarwin = false;
            userConfig = users.${username};
            nixosModules = "${self}/modules/nixos";
          };
          modules = [
            ./hosts/${hostname}
            ./hosts/common
          ];
        };

      mkDarwinConfiguration = hostname: username:
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

      mkHomeConfiguration = system: username: hostname:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              outputs.overlays.stable-packages
              outputs.overlays.warp-terminal-latest
              outputs.overlays.xeus-cling-no-checks
            ];
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs outputs;
            userConfig = users.${username};
            nhModules = "${self}/modules/home-manager";
            dmsPkgs = if inputs ? dms-flake then inputs.dms-flake.packages.${system} else { };
          };
          modules = [ ./home/${username}/${hostname} ];
        };

    in {
      # =============================
      # Sistemas NixOS (multi-host)
      # =============================
      nixosConfigurations = {
        inspiron = mkNixosConfiguration "inspiron" "rocha";
        glacier = mkNixosConfiguration "glacier" "rocha";
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs outputs;
            hostname = "iso";
            isDarwin = false;
            nixosModules = "${self}/modules/nixos";
          };
          modules = [ ./hosts/iso ];
        };
      };

      # =============================
      # Home Manager (multi-user, multi-host)
      # =============================
      homeConfigurations = {
        "rocha@inspiron" = let cfg = mkHomeConfiguration "x86_64-linux" "rocha" "inspiron"; in cfg // { type = "homeManagerConfiguration"; };
        "rocha@glacier" = let cfg = mkHomeConfiguration "x86_64-linux" "rocha" "glacier"; in cfg // { type = "homeManagerConfiguration"; };
        # Adicione outros usuários/hosts aqui
      };

      # =============================
      # Overlays (modular, multi-overlay)
      # =============================
      overlays = import ./overlays { inherit inputs; };
    };
}

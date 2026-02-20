# =============================================================================
# Feature: Development Environment
# Autor: rag (via AI Maintainer)
#
# O que é:
# - Ferramentas e ambientes de desenvolvimento
# - Git, editors, language servers, containers
#
# Por quê:
# - Centraliza configuração de desenvolvimento
# - Escolhe linguagens via opções
# - Mantém consistência entre hosts
#
# Como usar:
# No host:
#   rag.features.development.enable = true;
#   rag.features.development.languages.rust.enable = true;
#
# Riscos:
# - Muitos language servers podem usar bastante RAM
# - Ajuste conforme necessidade do host
# =============================================================================
{ config, lib, pkgs, ... }:

let
  cfg = config.rag.features.development;

in
{
  options.rag.features.development = {
    enable = lib.mkEnableOption "Development environment";

    git = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Git and related tools";
      };
    };

    languages = {
      rust = {
        enable = lib.mkEnableOption "Rust development environment";
      };

      python = {
        enable = lib.mkEnableOption "Python development environment";
      };

      javascript = {
        enable = lib.mkEnableOption "JavaScript/TypeScript development";
      };

      go = {
        enable = lib.mkEnableOption "Go development environment";
      };

      nix = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Nix development tools (always useful on NixOS)";
        };
      };

      c = {
        enable = lib.mkEnableOption "C/C++ development environment";
      };

      java = {
        enable = lib.mkEnableOption "Java development environment";
      };
    };

    editors = {
      vscode = {
        enable = lib.mkEnableOption "Visual Studio Code";
      };

      neovim = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Neovim editor";
        };
      };
    };

    tools = {
      direnv = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable direnv (per-directory environments)";
        };
      };

      kubernetes = {
        enable = lib.mkEnableOption "Kubernetes tools (kubectl, k9s, helm)";
      };

      terraform = {
        enable = lib.mkEnableOption "Terraform and related tools";
      };

      ansible = {
        enable = lib.mkEnableOption "Ansible configuration management";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # =========================
    # Git
    # =========================
    programs.git = lib.mkIf cfg.git.enable {
      enable = true;
      lfs.enable = true;
    };

    # =========================
    # Direnv
    # =========================
    programs.direnv = lib.mkIf cfg.tools.direnv.enable {
      enable = true;
      nix-direnv.enable = true;
    };

    # =========================
    # System Packages
    # =========================
    environment.systemPackages = with pkgs; lib.flatten [
      # Git tools
      (lib.optionals cfg.git.enable [
        git
        git-lfs
        gh  # GitHub CLI
        lazygit
        gitui
        delta  # Better git diff
      ])

      # Editors
      (lib.optional cfg.editors.neovim.enable neovim)
      (lib.optional cfg.editors.vscode.enable vscode)

      # Rust
      (lib.optionals cfg.languages.rust.enable [
        rustc
        cargo
        rustfmt
        rust-analyzer
        clippy
      ])

      # Python
      (lib.optionals cfg.languages.python.enable [
        python312
        python312Packages.pip
        python312Packages.virtualenv
        python312Packages.ipython
        ruff  # Linter/formatter
        pyright  # LSP
      ])

      # JavaScript/TypeScript
      (lib.optionals cfg.languages.javascript.enable [
        nodejs_22
        nodePackages.npm
        nodePackages.yarn
        nodePackages.pnpm
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.eslint
        nodePackages.prettier
      ])

      # Go
      (lib.optionals cfg.languages.go.enable [
        go
        gopls  # LSP
        golangci-lint
        delve  # Debugger
      ])

      # Nix
      (lib.optionals cfg.languages.nix.enable [
        nixd  # LSP
        nixfmt-rfc-style
        nix-tree
        nix-diff
        nix-output-monitor
        nvd  # Nix version diff
      ])

      # C/C++
      (lib.optionals cfg.languages.c.enable [
        gcc
        clang
        cmake
        gnumake
        gdb
        clang-tools  # clangd LSP
      ])

      # Java
      (lib.optionals cfg.languages.java.enable [
        jdk21
        maven
        gradle
      ])

      # Kubernetes
      (lib.optionals cfg.tools.kubernetes.enable [
        kubectl
        kubernetes-helm
        k9s
        kubectx
        kustomize
        stern  # Multi-pod log tailing
      ])

      # Terraform
      (lib.optionals cfg.tools.terraform.enable [
        terraform
        terraform-ls  # LSP
        tflint
        terragrunt
      ])

      # Ansible
      (lib.optionals cfg.tools.ansible.enable [
        ansible
        ansible-lint
      ])

      # Common dev tools (always included when dev is enabled)
      [
        # Build tools
        gnumake
        cmake
        pkg-config

        # Version control
        mercurial
        subversion

        # Network tools
        curl
        wget
        httpie

        # JSON/YAML tools
        jq
        yq-go

        # File tools
        ripgrep
        fd
        bat
        eza

        # Process tools
        htop
        btop

        # Compression
        unzip
        p7zip

        # Misc
        tree
        tmux
        screen
      ]
    ];

    # =========================
    # Environment Variables
    # =========================
    environment.variables = {
      # Editor
      EDITOR = lib.mkIf cfg.editors.neovim.enable "nvim";
      VISUAL = lib.mkIf cfg.editors.neovim.enable "nvim";

      # Go
      GOPATH = lib.mkIf cfg.languages.go.enable "$HOME/go";

      # Rust
      CARGO_HOME = lib.mkIf cfg.languages.rust.enable "$HOME/.cargo";
    };

    # =========================
    # Programs
    # =========================

    # Neovim
    programs.neovim = lib.mkIf cfg.editors.neovim.enable {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    # =========================
    # Documentation
    # =========================
    documentation = {
      dev.enable = true;
      man.enable = true;
      info.enable = true;
    };
  };
}


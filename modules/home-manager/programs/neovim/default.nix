# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para instalar e configurar o Neovim como editor padrão.
# - Empacota dependências de LSP/formatters/linters usadas no dia a dia.
# - Importa a configuração Lua (LazyVim) versionada neste repositório.
#
# Por quê:
# - Garante uma experiência consistente entre máquinas sem setup manual.
# - Evita “funciona numa máquina e na outra não” por falta de ferramentas.
#
# Como:
# - Usa `pkgs.neovim-unwrapped` e habilita providers (Node/Python/Ruby).
# - Declara `extraPackages` com ferramentas por linguagem.
# - Publica `./lazyvim` em `~/.config/nvim` via `xdg.configFile`.
#
# Riscos:
# - A lista de `extraPackages` pode aumentar tempo/tamanho do build.
# - Mudanças em `./lazyvim` afetam todas as máquinas que importarem este módulo.
# =============================================================================
{ pkgs, ... }:
{
  # Neovim: editor padrão e providers habilitados.
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    extraPackages = with pkgs; [
      black
      golangci-lint
      gopls
      gotools
      hadolint
      isort
      lua-language-server
      markdownlint-cli
      nixd
      nixfmt
      nodePackages.bash-language-server
      nodePackages.prettier
      pyright
      ruff
      shellcheck
      shfmt
      stylua
      terraform-ls
      tflint
      tree-sitter
      vscode-langservers-extracted
      yaml-language-server
    ];
  };

  # Importa a configuração Lua a partir deste repositório.
  xdg.configFile = {
    "nvim" = {
      source = ./lazyvim;
      recursive = true;
    };
  };
}

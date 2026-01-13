{ pkgs, lib, ... }:

{
  home.activation.create-p10k-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/zsh"
  '';

  home.file.".config/zsh/.p10k.zsh" = {
    # Fonte global compartilhada entre hosts.
    # Importante: este arquivo precisa estar rastreado no Git para flakes enxergarem.
    source = ./.p10k.zsh;
    force = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = false; # usaremos plugin via Nix
    syntaxHighlighting.enable = false;

    oh-my-zsh = {
      enable = true;

      # Não carregar tema via oh-my-zsh: o Powerlevel10k será carregado via pacote Nix.
      # Isso evita o erro "theme 'powerlevel10k/powerlevel10k' not found".
      theme = "";

      plugins = [
        "git"
        "kubectl"
      ];
    };

    shellAliases = {
      ff = "fastfetch";
      v  = "nvim";
      ls = "eza --icons always";
    };

    initContent = ''
      # =========================
      # Startup (interativo)
      # =========================
      if [[ -o interactive ]] && [[ -t 1 ]] && [[ -z "''${RAG_ZSH_STARTUP_BANNER_DONE-}" ]]; then
        export RAG_ZSH_STARTUP_BANNER_DONE=1
        clear
        fastfetch || true
      fi

      # =========================
      # Completion
      # =========================
      autoload -Uz compinit
      compinit

      # =========================
      # Powerlevel10k
      # =========================
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      if [ -f "$HOME/.config/zsh/.p10k.zsh" ]; then
        source "$HOME/.config/zsh/.p10k.zsh"
      fi

      # =========================
      # Plugins via Nix
      # =========================
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

      # =========================
      # Keybindings
      # =========================
      bindkey -e
      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey "^v" edit-command-line

      # =========================
      # kubectl completion
      # =========================
      source <(${pkgs.kubectl}/bin/kubectl completion zsh)
    '';
  };

  home.packages = with pkgs; [
    git
    kubectl
    eza
    fastfetch
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}

# Home Manager: módulo comum (base do usuário)
# Autor: rag
#
# O que é
# - Ponto de entrada de configuração do Home Manager para o usuário.
# - Agrega imports de programas/serviços e define variáveis de sessão comuns.
#
# Por quê
# - Mantém os `home/*/default.nix` (por-host) pequenos e focados.
# - Centraliza defaults consistentes entre máquinas.
#
# Como
# - Importa módulos em `modules/home-manager/**`.
# - Define `home.username`, `home.homeDirectory`, `home.sessionVariables`.
#
# Riscos
# - Variáveis de sessão podem afetar apps Electron/Qt; mudanças devem ser testadas em Wayland/X11.
{
  userConfig,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../programs/aerospace
    ../programs/warp-terminal
    ../programs/albert
    ../programs/atuin
    ../programs/bat
    ../programs/mangohud
    ../programs/zen-browser
    ../programs/btop
    ../programs/fastfetch
    ../programs/fzf
    ../programs/git
    ../programs/go
    ../programs/rust
    ../programs/gpg
    ../programs/k9s
    ../programs/krew
    ../programs/lazygit
    ../programs/neovim
    ../programs/obs-studio
    ../programs/saml2aws
    ../programs/starship
    ../programs/telegram
    ../programs/vscode
    ../programs/virt-manager
    ../programs/jupyter
    ../programs/zellij
    ../programs/zsh
    ../scripts

    # Rices / desktops (opt-in por opção)
    ../../../desktop/hyprland/rice/dms-upstream.nix
  ];

  # Habilita Jupyter via módulo declarativo.
  # IMPORTANTE: manter opt-in por host/usuário, porque Jupyter/kernels podem quebrar builds
  # (ex.: xeus-cling e dependências python binárias). Habilite em `home/<user>/<host>/default.nix`.
  # programs.jupyter.enable = true;

  # Recarrega unidades do systemd de forma suave ao mudar configs.
  systemd.user.startServices = "sd-switch";

  # Identidade do usuário (paths variam entre Linux e macOS).
  home = {
    username = "${userConfig.name}";
    homeDirectory =
      if pkgs.stdenv.isDarwin then "/Users/${userConfig.name}" else "/home/${userConfig.name}";
  };

  # Ajustes de sessão (principalmente Electron/VS Code em Wayland).
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_USE_PORTAL = "1";

    # Qt Quick Controls: evitar estilos QML incompatíveis.
    # Kvantum é para Qt Widgets; se Qt Quick tentar carregar "kvantum" como QML,
    # o Plasma pode quebrar (wallpaper/overview) e ficar com tela preta.
    QT_QUICK_CONTROLS_STYLE = "org.kde.desktop";

    # Evita cair no libvirt rootless (qemu:///session), que não consegue criar bridges.
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  # Garante que os pacotes comuns estejam instalados
  home.packages =
    with pkgs;
    [
      awscli2
      dig
      dust
      eza
      fd
      jq
      kubectl
      nh
      openconnect
      pipenv
      podman-compose
      podman-tui

      # =========================
      # Python (interpretador)
      # =========================
      # O que é
      # - Runtime Python para uso no terminal/IDE.
      # - Tooling básico: pip e virtualenv para ambientes isolados.
      #
      # Como usar
      # - Criar venv: `python -m venv .venv`
      # - Ativar: `source .venv/bin/activate`
      #
      # Nota
      # - Alguns tools/IDEs ainda chamam o comando `python`.
      # - No nixpkgs atual, o pacote `python3` pode expor `python` e `python3`.
      #   Se o seu editor ainda reclamar, use um venv no projeto e aponte para `.venv/bin/python`.
      python3
      python3Packages.pip
      python3Packages.virtualenv

      ripgrep
    ];
}

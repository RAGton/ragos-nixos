{
  outputs,
  userConfig,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;

  commonPackages = with pkgs; [
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
    python3
    ripgrep
    terraform
    vscode
  ];

  darwinPackages = with pkgs; [
    anki-bin
    colima
    hidden-bar
    mos
    podman
    raycast
  ];

  linuxPackages = with pkgs; [
    anki
    tesseract
    unzip
    wl-clipboard
  ];
in
{
  imports = [
    ../programs/aerospace
    ../programs/warp-terminal
    ../programs/albert
    ../programs/atuin
    ../programs/bat
    ../programs/zen-browser
    ../programs/btop
    ../programs/fastfetch
    ../programs/fzf
    ../programs/git
    ../programs/go
    ../programs/gpg
    ../programs/k9s
    ../programs/krew
    ../programs/lazygit
    ../programs/neovim
    ../programs/obs-studio
    ../programs/saml2aws
    ../programs/starship
    ../programs/telegram
    ../programs/zellij
    ../programs/zsh
    ../scripts
  ];

  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

  # Recarrega unidades do systemd de forma suave ao mudar configs
  systemd.user.startServices = "sd-switch";

  # Configuração do Home Manager para o ambiente do usuário
  home = {
    username = "${userConfig.name}";
    homeDirectory =
      if pkgs.stdenv.isDarwin then "/Users/${userConfig.name}" else "/home/${userConfig.name}";
  };

  # Ajustes de sessão (principalmente Electron/VS Code em Wayland)
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GTK_USE_PORTAL = "1";
  };

  # Garante que os pacotes comuns estejam instalados
  home.packages =
    commonPackages
    ++ lib.optionals isDarwin darwinPackages
    ++ lib.optionals (!isDarwin) linuxPackages;

  # Flavor e accent do Catppuccin
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };
}

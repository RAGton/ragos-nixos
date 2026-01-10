{
  inputs,
  outputs,
  lib,
  config,
  userConfig,
  pkgs,
  hostname,
  ...
}:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ../programs/steam
    ../programs/gaming
    ../services/tlp
    ../services/snapper
  ];
  # Configuração do nixpkgs
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
      outputs.overlays.openrgb-git
    ];

    config = {
      allowUnfree = true;
    };
  };

  # Registra os inputs da flake para comandos do nix
  nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) (
    lib.filterAttrs (_: lib.isType "flake") inputs
  );

  # Expõe inputs via canais legados (NIX_PATH)
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  # Ajustes do Nix
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  # Ajustes de boot
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "rd.udev.log_level=3"
    ];
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.enable = true;
    loader.timeout = 0;
    plymouth.enable = true;

    # Ajustes do módulo v4l (câmera virtual)
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
  };

  # Mitigação prática contra travamentos por pressão de memória.
  # Swap já existe no host, mas zram tende a melhorar muito a responsividade.
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
    # Em máquinas com ~16GB RAM, 100% resulta em ~16GB de zram.
    memoryPercent = lib.mkDefault 100;
  };

  # Rede
  networking.networkmanager.enable = true;
  networking.hostName = lib.mkDefault hostname;

  # Desabilita serviços systemd que impactam o boot
  systemd.services = {
    NetworkManager-wait-online.enable = false;
    plymouth-quit-wait.enable = false;
  };

  # Fuso horário
  time.timeZone = "America/Cuiaba";

  # Internacionalização
  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Habilita suporte a Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      Name = lib.mkDefault hostname;
      Alias = lib.mkDefault hostname;
    };
  };

  # Base para gerenciamento de cor/ICC (útil para HDR/WCG quando suportado)
  services.colord.enable = lib.mkDefault true;

  # Ajustes de entrada
  services.libinput.enable = true;

  # Ajustes do Xserver
  services.xserver = {
    xkb.layout = "br";
    xkb.variant = "abnt2";
    excludePackages = with pkgs; [ xterm ];
  };

  # Habilita Wayland no Chromium/Electron
  # Remove decorações em apps Qt
  # Define tamanho do cursor
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XCURSOR_SIZE = "24";
  };

  # Configuração de PATH
  environment.localBinInPath = true;

  # Desabilita impressão via CUPS
  services.printing.enable = false;

  # devmon depende de udevil, que frequentemente quebra build em toolchains novos.
  # Em desktops (ex.: KDE), o fluxo recomendado para dispositivos removíveis é via udisks2.
  services.devmon.enable = false;

  # Habilita PipeWire para áudio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Flatpak (sistema) + gerenciamento declarativo via nix-flatpak
  services.flatpak = {
    enable = true;

    packages = [
      "app.zen_browser.zen"
      "com.heroicgameslauncher.hgl"
      "io.github.shiftey.Desktop"
      "io.github.shonebinu.Brief"
      "com.anydesk.Anydesk"
      "com.rustdesk.RustDesk"
      "com.ranfdev.DistroShelf"
      "com.github.tchx84.Flatseal"
      "io.github.flattool.Warehouse"
      "org.kde.filelight"
      "com.rtosta.zapzap"
      "org.libreoffice.LibreOffice"
      "org.gimp.GIMP"
    ];

    uninstallUnmanaged = true;
    update.auto.enable = true;
  };

  # Configuração do usuário
  users.users.${userConfig.name} = {
    description = userConfig.fullName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    isNormalUser = true;
    shell = pkgs.zsh;
  };

  # Define o avatar do usuário
  system.activationScripts.script.text = ''
    mkdir -p /var/lib/AccountsService/{icons,users}
    cp ${userConfig.avatar} /var/lib/AccountsService/icons/${userConfig.name}

    touch /var/lib/AccountsService/users/${userConfig.name}

    if ! grep -q "^Icon=" /var/lib/AccountsService/users/${userConfig.name}; then
      if ! grep -q "^\[User\]" /var/lib/AccountsService/users/${userConfig.name}; then
        echo "[User]" >> /var/lib/AccountsService/users/${userConfig.name}
      fi
      echo "Icon=/var/lib/AccountsService/icons/${userConfig.name}" >> /var/lib/AccountsService/users/${userConfig.name}
    fi
  '';

  # Sudo sem senha
  security.sudo.wheelNeedsPassword = false;

  # Pacotes do sistema
  environment.systemPackages = with pkgs; [
    gcc
    glib
    gnumake
    killall
    mesa
    openrgb-git
  ];

  # Regras udev para permitir acesso do OpenRGB aos dispositivos.
  services.udev.packages = with pkgs; [ openrgb-git ];

  # Configuração comum de containers
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Habilita xwayland
  programs.xwayland.enable = true;

  # Configuração do Zsh
  programs.zsh.enable = true;

  # Configuração de fontes
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    roboto
  ];

  # Serviços adicionais
  services.locate.enable = true;

  # Daemon OpenSSH
  services.openssh.enable = true;
}

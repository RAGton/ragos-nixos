# ==============================================================================
# Módulo: Base Comum NixOS
# Autor: rag
#
# O que é:
# - Camada compartilhada entre hosts com defaults de sistema, serviços e pacotes.
# - Ponto único para opções globais não ligadas a hardware específico.
#
# Por quê:
# - Evita duplicação entre hosts.
# - Mantém as configurações por host focadas em hardware e diferenças locais.
#
# Como:
# - Importa módulos compartilhados e define defaults com `mkDefault`.
# - Expõe registry/NIX_PATH e stack base (PipeWire, rede, locale, etc).
#
# Riscos:
# - Qualquer regressão aqui afeta todos os hosts; sempre validar com `nixos-rebuild test`.
# ==============================================================================
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
    ../../shared/nixpkgs

    # Branding global (RagOS).
    # Mantemos aqui para que todos os hosts herdem o mesmo "nome do sistema".
    ../branding/ragos

    ../programs/steam
    ../programs/wallpaper-engine-kde
    # ../services/lightdm  # TEMPORARIAMENTE REMOVIDO PARA TESTE
    ../services/tlp
    ../services/snapper
    ../services/tailscale
  ];

  # Registra inputs da flake no registry (melhora UX com comandos `nix ...`).
  nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) (
    lib.filterAttrs (_: lib.isType "flake") inputs
  );

  # Compat: expõe inputs via NIX_PATH (canais legados).
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  # Nix: ajustes globais.
  nix.package = pkgs.nixVersions.latest;
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;

    # Build paralelo (conservador para evitar travamentos):
    # - max-jobs: máximo de derivations simultâneas
    # - cores: 0 = usa todos os cores disponíveis POR JOB (mas respeitando load)
    # - auto = deixa Nix decidir baseado em RAM/CPU disponíveis
    max-jobs = lib.mkDefault "auto";
    cores = lib.mkDefault 0;
  };

  # Boot: defaults pensados para reduzir ruído e melhorar UX.
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "rd.udev.log_level=3"
    ];
    loader.efi.canTouchEfiVariables = true;
   # loader.systemd-boot.enable = false;
#    loader.systemd-boot.extraFiles =
 #     let
  #      splashSrc = ../../../files/wallpaper/wallpaper.png;
   #     splashBmp = pkgs.runCommand "systemd-boot-splash.bmp" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    #      convert "${splashSrc}" \
     #       -alpha off \
      #      -resize 1920x1080^ \
       #     -gravity center \
        #    -extent 1920x1080 \
         #   BMP3:"$out"
       # '';
      #in
     # {
     #   "loader/splash.bmp" = splashBmp;
     # };
    #loader.timeout = 0;
   # plymouth = {
   #   enable = true;
   #   theme = "nixos-bgrt";
   #   themePackages = [ pkgs.nixos-bgrt-plymouth ];
   # };

    # Ajustes do módulo v4l (câmera virtual)
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';

    # Tuning balanceado para desktop/games (evita OOM e travamentos).
    kernel.sysctl = {
      # swappiness 60 = padrão Linux, balanceado entre RAM e swap
      # Valor muito baixo pode causar OOM kills e travamentos
      "vm.swappiness" = lib.mkDefault 60;

      # Latência do scheduler (6ms é seguro para desktop)
      "kernel.sched_latency_ns" = lib.mkDefault 6000000;

      # Proteção contra OOM: permite usar mais swap antes de matar processos
      "vm.vfs_cache_pressure" = lib.mkDefault 50;
      "vm.dirty_ratio" = lib.mkDefault 10;
      "vm.dirty_background_ratio" = lib.mkDefault 5;
    };
  };

  # Mitigação prática contra travamentos por pressão de memória.
  # Swap já existe no host, mas zram tende a melhorar muito a responsividade.
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
    # 50% é mais conservador e trabalha melhor com swap em disco
    # Evita pressão excessiva quando a RAM está cheia
    memoryPercent = lib.mkDefault 50;
    # Prioridade alta: tenta usar zram antes do swap em disco
    priority = lib.mkDefault 10;
  };

  # earlyoom: proteção crítica contra travamentos por OOM
  # Mata processos ANTES do sistema travar completamente
  services.earlyoom = {
    enable = lib.mkDefault true;
    enableNotifications = lib.mkDefault true;
    # Mata processos quando RAM livre < 5% E swap livre < 5%
    freeMemThreshold = lib.mkDefault 5;
    freeSwapThreshold = lib.mkDefault 5;
    # Evita matar processos críticos do sistema
    extraArgs = [
      "--avoid"
      "^(Xorg|kwin_wayland|plasmashell|sddm)$"
      "--prefer"
      "^(firefox|chromium|chrome|electron)$"
    ];
  };

  # Rede
  networking.networkmanager.enable = true;
  networking.hostName = lib.mkDefault hostname;

  # Desabilita serviços systemd que impactam o boot
  systemd.services = {
    NetworkManager-wait-online.enable = false;
    plymouth-quit-wait.enable = false;
    plymouth-quit.enable = false;
    plymouth-start.enable = false;
  };

  # Desabilita plymouth completamente (não será usado, evita dependências)
  boot.plymouth.enable = false;

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

    # BlueZ: ajustes para melhorar compatibilidade/qualidade (BT audio)
    # - Experimental habilita suporte a recursos/códigos mais novos quando disponíveis.
    # - Manter como mkDefault para facilitar override.
    settings = {
      General = {
        Name = lib.mkDefault hostname;
        Alias = lib.mkDefault hostname;
        Experimental = lib.mkDefault true;
      };
    };
  };

  # Base para gerenciamento de cor/ICC (útil para HDR/WCG quando suportado)
  services.colord.enable = lib.mkDefault true;
  # Necessário para integração de bateria/energia em apps Wayland (incluindo DMS).
  services.upower.enable = lib.mkDefault true;

  # Ajustes de entrada
  services.libinput.enable = true;
  services.logind.settings.Login = {
    KillUserProcesses = lib.mkForce true;
    HandleLidSwitch = lib.mkDefault "suspend";
    HandleLidSwitchExternalPower = lib.mkDefault "ignore";
    HandleLidSwitchDocked = lib.mkDefault "ignore";
  };

  # Evita troca inesperada de implementação do D-Bus durante `nixos-rebuild test/switch`.
  # (Isso costuma disparar o pre-switch check `switchInhibitors`.)
  services.dbus.implementation = lib.mkDefault "broker";

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

  # Habilita impressão via CUPS
  services.printing.enable = true;

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
    wireplumber.enable = true;

    # Melhorias de qualidade/volume (seguras)
    # - Resampler de melhor qualidade para reduzir "som abafado" em alguns hardwares.
    # - Headroom no layer Pulse (permite aumentar acima de 100% quando necessário).
    extraConfig = {
      pipewire."92-low-latency" = {
        context.properties = {
          default.clock.rate = lib.mkDefault 48000;
          default.clock.quantum = lib.mkDefault 128;
          default.clock.min-quantum = lib.mkDefault 64;
          default.clock.max-quantum = lib.mkDefault 2048;
        };
      };

      pipewire."95-audio-quality" = {
        context.properties = {
          # Resampler: qualidade melhor (custa um pouco mais de CPU, mas costuma valer a pena no desktop)
          default.clock.allowed-rates = lib.mkDefault [ 44100 48000 96000 ];
          resample.quality = lib.mkDefault 10;
        };
      };

      pipewire-pulse."95-pulse-headroom" = {
        stream.properties = {
          # Permite volume acima de 1.0 (100%). Útil quando o hardware é baixo.
          # Isso NÃO melhora a qualidade por si só, mas aumenta o ganho disponível.
          pulse.min.quantum = lib.mkDefault 64;
        };
        context.properties = {
          pulse.min.req = lib.mkDefault 64;
          pulse.default.req = lib.mkDefault 128;
        };
      };
    };
  };

  # Flatpak (sistema) + gerenciamento declarativo via nix-flatpak
  services.flatpak = {
    enable = true;

    packages = lib.mkDefault [
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
  users.mutableUsers = true;

  # Emergency initial password for root: empty = passwordless access on first boot.
  # Override per-host with a proper hashedPassword. Change immediately with passwd after boot.
  users.users.root.initialHashedPassword = lib.mkDefault "";

  users.users.${userConfig.name} = {
    description = userConfig.fullName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    isNormalUser = true;
    shell = pkgs.zsh;
    # Emergency initial password: empty = passwordless on first boot (new accounts only).
    # Override per-host or change immediately with passwd after first login.
    initialHashedPassword = lib.mkDefault "";
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
    nodejs_20
    killall
    mesa
    (lib.mkIf config.rag.hardware.openrgb.enable openrgb-git)
    podman
    distrobox

    # =========================
    # Python (global)
    # =========================
    # PyCharm/IntelliJ (GUI) frequentemente não herda PATH do Home Manager.
    # Expor o interpretador via systemPackages garante:
    # - /run/current-system/sw/bin/python3
    # - criação de venv por projeto via `python3 -m venv .venv`
    python3
    python3Packages.pip
    python3Packages.virtualenv

    # Rust (global): `rustup` gerencia toolchains; `cargo`/`rustc` úteis para uso imediato.
    rustup
    cargo
    rustc

    # =========================
    # Java (global)
    # =========================
    # JDK para apps Java (TLauncher, Minecraft, etc.)
    # jdk21 é LTS e compatível com a maioria dos apps modernos
    jdk21

    jetbrains.idea-oss
    jetbrains.pycharm-oss
    jetbrains.rust-rover
    kdePackages.dolphin
  ];

   # Rustup: evita o estado "rustup instalado, mas sem toolchain default".
  # Faz bootstrap no primeiro rebuild (e mantém idempotente).
  system.activationScripts.rustupBootstrap = {
    text = ''
      USER=${lib.escapeShellArg userConfig.name}
      HOME_DIR=${lib.escapeShellArg (config.users.users.${userConfig.name}.home or "/home/${userConfig.name}")}

      if [ -d "$HOME_DIR" ]; then
        # Só roda se rustup existir no sistema
        if command -v rustup >/dev/null 2>&1; then
          # Rodamos como o usuário pra evitar permissões erradas em ~/.rustup e ~/.cargo
          ${pkgs.su}/bin/su - ${userConfig.name} -c ${lib.escapeShellArg ''
            set -euo pipefail
            export HOME="$HOME_DIR"

            # Se não existe toolchain default, instala/define stable.
            if ! rustup show active-toolchain >/dev/null 2>&1; then
              rustup toolchain install stable
              rustup default stable
            fi
          ''}
        fi
      fi
    '';
  };

  # Regras udev para permitir acesso do OpenRGB aos dispositivos.
  services.udev.packages = lib.optionals config.rag.hardware.openrgb.enable (with pkgs; [ openrgb-git ]);

  # Configuração comum de containers
  # Nota: não habilitamos `podman.dockerCompat` por padrão porque conflita com
  # `virtualisation.docker` quando Docker também está ativo.
  # Deixe isso ser controlado pelo módulo de features (rag.features.virtualization.*)
  # ou por-host.
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = lib.mkDefault false;
      dockerSocket.enable = lib.mkDefault false;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Habilita xwayland
  programs.xwayland.enable = true;

  # Configuração do Zsh
  programs.zsh.enable = true;

  # Winbox (MikroTik): o nixpkgs já fornece `programs.winbox`.
  # Habilite por-host (ex.: `hosts/inspiron/default.nix`) com `programs.winbox.enable = true`.

  # Permite carregar binários fora do Nix com GLIBC/linker compatível (útil p/ plugins JetBrains/VSCode)
  programs.nix-ld.enable = true;

  # Configuração de fontes
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.caskaydia-cove
    roboto
  ];

  # Serviços adicionais
  services.locate.enable = true;

  # Daemon OpenSSH
  services.openssh.enable = true;
}

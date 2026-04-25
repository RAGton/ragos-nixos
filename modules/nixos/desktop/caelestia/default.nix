{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.rag.shell.caelestia;
  system = pkgs.stdenv.hostPlatform.system;
  caelestiaPackages = inputs.caelestia-shell.packages.${system};
  defaultPackage = caelestiaPackages.with-cli;
  cliPackage = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default;
  launcherPatch = ./patches/rag-launch-desktop-entry-desktop-id.patch;
  launcherHelper = pkgs.writeShellApplication {
    name = "rag-launch-desktop-entry";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      set -eu

      entry="''${1-}"
      [ -n "$entry" ] || exit 2
      shift || true

      action_suffix=""
      case "$entry" in
        *:*)
          action_suffix=":''${entry#*:}"
          entry="''${entry%%:*}"
          ;;
      esac

      case "$entry" in
        *.desktop|/*|./*|../*)
          desktop_target="$entry"
          ;;
        *)
          desktop_target="''${entry}.desktop"
          ;;
      esac

      exec uwsm app -- "''${desktop_target}''${action_suffix}" "$@"
    '';
  };
  effectivePackage = cfg.package.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ launcherPatch ];
  });
in
{
  options.rag.shell.caelestia = {
    enable = lib.mkEnableOption "Caelestia Shell como shell principal do stack Hyprland";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "inputs.caelestia-shell.packages.<system>.with-cli";
      description = ''
        Pacote do Caelestia instalado no sistema.

        O padrão usa o input `caelestia-shell` pinado no flake. Para testar o clone
        local em `/home/rocha/src/caelestia-shell` sem vazar esse path para outros
        hosts, prefira rebuilds com:

          --override-input caelestia-shell path:/home/rocha/src/caelestia-shell
      '';
    };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "hyprland-session.target";
      description = "Target systemd-user responsável por iniciar o Caelestia na sessão gráfica.";
    };

    environment = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "QT_QPA_PLATFORM=wayland" ];
      description = "Variáveis extras exportadas para o serviço systemd-user do Caelestia.";
    };

    extraRuntimePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        cliPackage
        pkgs.app2unit
        pkgs.brightnessctl
        pkgs.coreutils
        pkgs.ddcutil
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.libqalculate
        pkgs.lm_sensors
        pkgs.networkmanager
        pkgs.procps
        launcherHelper
        pkgs.swappy
        pkgs.systemd
        pkgs.util-linux
      ];
      description = ''
        Dependências de runtime adicionadas ao PATH do serviço do Caelestia.

        O upstream depende explicitamente do CLI `caelestia` e de ferramentas
        como `lsblk`, `pidof`, `nmcli` e `brightnessctl` para o shell operar
        com funcionalidade completa.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.rag.desktop.environment == "hyprland";
        message = "rag.shell.caelestia.enable requer rag.desktop.environment = \"hyprland\".";
      }
    ];

    environment.systemPackages = [
      effectivePackage
      cliPackage
    ];

    systemd.user.services.caelestia = {
      description = "Caelestia Shell";
      after = [ cfg.systemdTarget ];
      partOf = [ cfg.systemdTarget ];
      wantedBy = [ cfg.systemdTarget ];
      path = cfg.extraRuntimePackages;

      serviceConfig = {
        Type = "exec";
        ExecStart = "${effectivePackage}/bin/caelestia-shell";
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStopSec = "5s";
        Slice = "session.slice";
        Environment = cfg.environment;
      };
    };
  };
}

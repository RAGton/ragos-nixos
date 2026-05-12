{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.kryonix.shell.caelestia;
  system = pkgs.stdenv.hostPlatform.system;
  caelestiaPackages = inputs.caelestia-shell.packages.${system};
  defaultPackage = caelestiaPackages.with-cli;
  cliPackage = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default;
  launcherPatch = ./patches/rag-launch-desktop-entry-desktop-id.patch;
  kryonixLaunch = pkgs.writeShellApplication {
    name = "kryonix-launch";
    runtimeInputs = with pkgs; [
      coreutils
      flatpak
      gawk
      gnused
      gtk3
      uwsm
    ];
    text = ''
      fail() {
        echo "kryonix-launch: $*" >&2
        exit 127
      }

      entry="''${1-}"
      [ -n "$entry" ] || fail "missing desktop id; expected e.g. org.kde.dolphin.desktop"
      shift || true
      extra_args=("$@")

      action_suffix=""
      case "$entry" in
        *:*)
          action_suffix=":''${entry#*:}"
          entry="''${entry%%:*}"
          ;;
      esac

      desktop_id="$entry"
      case "$desktop_id" in
        *.desktop|/*|./*|../*) ;;
        *) desktop_id="''${desktop_id}.desktop" ;;
      esac

      data_dirs=()
      if [ -n "''${XDG_DATA_HOME-}" ]; then
        data_dirs+=("$XDG_DATA_HOME")
      else
        data_dirs+=("$HOME/.local/share")
      fi

      if [ -n "''${XDG_DATA_DIRS-}" ]; then
        IFS=: read -r -a xdg_data_dirs <<< "$XDG_DATA_DIRS"
        data_dirs+=("''${xdg_data_dirs[@]}")
      fi

      data_dirs+=(
        "$HOME/.nix-profile/share"
        "/etc/profiles/per-user/$(id -un)/share"
        "/run/current-system/sw/share"
        "$HOME/.local/share/flatpak/exports/share"
        "/var/lib/flatpak/exports/share"
      )

      find_desktop_file() {
        local candidate="$1"
        local data_dir=""
        local desktop_name="$candidate"

        case "$candidate" in
          /*|./*|../*)
            [ -f "$candidate" ] || return 1
            printf '%s\n' "$candidate"
            return 0
            ;;
        esac

        case "$desktop_name" in
          *.desktop) ;;
          *) desktop_name="''${desktop_name}.desktop" ;;
        esac

        for data_dir in "''${data_dirs[@]}"; do
          [ -n "$data_dir" ] || continue
          if [ -f "$data_dir/applications/$desktop_name" ]; then
            printf '%s\n' "$data_dir/applications/$desktop_name"
            return 0
          fi
        done

        return 1
      }

      add_path_entry() {
        local path_entry="$1"
        [ -d "$path_entry" ] || return 0
        case ":''${PATH-}:" in
          *:"$path_entry":*) ;;
          *) PATH="$path_entry''${PATH:+:$PATH}" ;;
        esac
      }

      ensure_launcher_path() {
        local desktop_file="''${1-}"
        local desktop_dir=""
        local package_root=""
        local path_entry=""

        for path_entry in \
          "$HOME/.local/bin" \
          "/run/wrappers/bin" \
          "$HOME/.local/share/flatpak/exports/bin" \
          "/var/lib/flatpak/exports/bin" \
          "$HOME/.nix-profile/bin" \
          "$HOME/.local/state/nix/profile/bin" \
          "/etc/profiles/per-user/$(id -un)/bin" \
          "/nix/var/nix/profiles/default/bin" \
          "/run/current-system/sw/bin"
        do
          add_path_entry "$path_entry"
        done

        if [ -n "$desktop_file" ]; then
          desktop_dir="$(dirname "$desktop_file")"
          case "$desktop_dir" in
            */share/applications)
              package_root="''${desktop_dir%/share/applications}"
              add_path_entry "$package_root/bin"
              add_path_entry "$package_root/sbin"
              ;;
          esac
        fi

        export PATH
      }

      run_exec_fallback() {
        local desktop_file="$1"
        local exec_line=""

        exec_line="$(
          awk '
            /^\[Desktop Entry\]$/ { in_entry = 1; next }
            /^\[/ { if (in_entry) exit; next }
            in_entry && /^Exec=/ {
              sub(/^Exec=/, "")
              print
              exit
            }
          ' "$desktop_file" \
            | sed -E 's/(^|[[:space:]])%[fFuUdDnNickvm]([[:space:]]|$)/ /g; s/%%/%/g; s/[[:space:]]+/ /g; s/^ //; s/ $//'
        )"

        [ -n "$exec_line" ] || return 1

        # Desktop entries are trusted local package metadata; this is only the final fallback.
        # shellcheck disable=SC2086
        eval "set -- $exec_line"
        exec "$@" "''${extra_args[@]}"
      }

      desktop_file="$(find_desktop_file "$desktop_id" || true)"
      ensure_launcher_path "$desktop_file"

      uwsm_target="''${desktop_id}''${action_suffix}"

      if DEBUG="" uwsm app -- "$uwsm_target" "''${extra_args[@]}"; then
        exit 0
      fi

      gtk_candidates=("$entry" "$desktop_id")
      if [ -n "$desktop_file" ]; then
        gtk_candidates+=("$(basename "$desktop_file")" "$(basename "$desktop_file" .desktop)")
      fi

      for gtk_id in "''${gtk_candidates[@]}"; do
        [ -n "$gtk_id" ] || continue
        if gtk-launch "$gtk_id" "''${extra_args[@]}"; then
          exit 0
        fi
      done

      if [ -n "$desktop_file" ]; then
        run_exec_fallback "$desktop_file"
      fi

      fail "could not launch '$entry'; expected a desktop entry resolvable by uwsm, gtk-launch or Exec"
    '';
  };
  legacyLauncherHelper = pkgs.writeShellApplication {
    name = "rag-launch-desktop-entry";
    runtimeInputs = [ kryonixLaunch ];
    text = ''
      exec kryonix-launch "$@"
    '';
  };
  gtkLaunch = pkgs.writeShellApplication {
    name = "gtk-launch";
    runtimeInputs = [ pkgs.gtk3 ];
    text = ''
      exec ${pkgs.gtk3}/bin/gtk-launch "$@"
    '';
  };
  effectivePackage = cfg.package.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ launcherPatch ];
    postPatch = (old.postPatch or "") + ''
      sed -i '/pragma DefaultEnv/d' shell.qml
    '';
  });
in
{
  options.kryonix.shell.caelestia = {
    enable = lib.mkEnableOption "Caelestia Shell como shell principal do stack Hyprland";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "inputs.caelestia-shell.packages.<system>.with-cli";
      description = ''
        Pacote do Caelestia instalado no sistema.

        O padrão usa o input `caelestia-shell` pinado no flake. Para testar o clone
        local sem vazar paths de desenvolvimento para outros hosts, prefira
        rebuilds executados a partir deste checkout com:

          --override-input caelestia-shell path:../caelestia-shell
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
        pkgs.flatpak
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.libqalculate
        pkgs.lm_sensors
        pkgs.networkmanager
        pkgs.procps
        kryonixLaunch
        legacyLauncherHelper
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
        assertion = config.kryonix.desktop.environment == "hyprland";
        message = "kryonix.shell.caelestia.enable requer kryonix.desktop.environment = \"hyprland\".";
      }
    ];

    environment.systemPackages = [
      effectivePackage
      cliPackage
      gtkLaunch
      kryonixLaunch
      legacyLauncherHelper
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
        Environment = [
          "USER=%u"
          "LOGNAME=%u"
        ]
        ++ cfg.environment;
      };
    };
  };
}

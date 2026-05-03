{
  pkgs,
  lib,
  config,
  ...
}:
let
  shellBackend = config.kryonix.shell.backend or null;
in
{
  home.packages = with pkgs; [
    (writeShellApplication {
      name = "rag-screenshot";
      runtimeInputs = [
        bash
        coreutils
        grim
        slurp
        wl-clipboard
        swappy
        libnotify
        jq
        hyprland
      ];
      text = ''
        set -euo pipefail

        action="''${1-}"
        shift || true

        screenshots_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
        mkdir -p "$screenshots_dir"

        ts="$(date +%F_%H-%M-%S)"
        file="$screenshots_dir/Screenshot_$ts.png"

        notify() {
          notify-send -a "screenshot" "$@" >/dev/null 2>&1 || true
        }

        case "$action" in
          copy-area)
            geometry="$(slurp)" || exit 0
            grim -g "$geometry" - | wl-copy
            notify "Screenshot" "Área copiada para o clipboard"
            ;;

          copysave-screen)
            grim "$file"
            wl-copy < "$file"
            notify "Screenshot" "Tela salva e copiada: $(basename "$file")"
            ;;

          copysave-active)
            x="$(hyprctl -j activewindow | jq -r '.at[0] // empty')"
            y="$(hyprctl -j activewindow | jq -r '.at[1] // empty')"
            w="$(hyprctl -j activewindow | jq -r '.size[0] // empty')"
            h="$(hyprctl -j activewindow | jq -r '.size[1] // empty')"
            if [[ -n "$x" && -n "$y" && -n "$w" && -n "$h" ]]; then
              geometry="$x,$y ''${w}x''${h}"
              grim -g "$geometry" "$file"
              wl-copy < "$file"
              notify "Screenshot" "Janela ativa salva e copiada: $(basename "$file")"
            fi
            ;;

          edit-area)
            tmp="''${TMPDIR:-/tmp}/screenshot-area-$ts.png"
            geometry="$(slurp)" || exit 0
            grim -g "$geometry" "$tmp"
            exec swappy -f "$tmp"
            ;;

          *)
            echo "Uso: rag-screenshot {copy-area|copysave-screen|copysave-active|edit-area}" >&2
            exit 2
            ;;
        esac
      '';
    })

    (writeShellApplication {
      name = "rag-brightness";
      runtimeInputs = [
        bash
        brightnessctl
      ];
      text = ''
        set -euo pipefail
        case "''${1-}" in
          up) exec brightnessctl -q set 10%+ ;;
          down) exec brightnessctl -q set 10%- ;;
          *) echo "Uso: rag-brightness {up|down}" >&2; exit 2 ;;
        esac
      '';
    })

    (writeShellApplication {
      name = "rag-caelestia-ipc";
      runtimeInputs = [
        bash
        coreutils
        jq
      ];
      text = ''
        set -euo pipefail
        pid="$(caelestia-shell list --all --json | jq -r 'map(select(.config_path | contains("caelestia-shell/shell.qml"))) | first | .pid // empty')"
        [ -n "$pid" ] || exit 1
        qs_bin="$(readlink -f "/proc/$pid/exe")"
        [ -n "$qs_bin" ] || exit 1
        exec "$qs_bin" ipc --pid "$pid" call "$@"
      '';
    })

    (writeShellApplication {
      name = "rag-shell-launcher";
      runtimeInputs = [
        bash
        coreutils
        rofi
      ];
      text = ''
        set -euo pipefail
        backend="${if shellBackend == "caelestia" then "caelestia" else "none"}"
        if [ "$backend" = "caelestia" ] && command -v rag-caelestia-ipc >/dev/null 2>&1; then
          if rag-caelestia-ipc drawers toggle launcher; then exit 0; fi
        fi
        exec rofi -show drun
      '';
    })

    (writeShellApplication {
      name = "rag-shell-dashboard";
      runtimeInputs = [
        bash
        coreutils
      ];
      text = ''
        set -euo pipefail
        backend="${if shellBackend == "caelestia" then "caelestia" else "none"}"
        if [ "$backend" = "caelestia" ] && command -v rag-caelestia-ipc >/dev/null 2>&1; then
          if rag-caelestia-ipc drawers toggle dashboard; then exit 0; fi
        fi
        exec rag-quick-actions
      '';
    })

    (writeShellApplication {
      name = "rag-shell-notifications";
      runtimeInputs = [
        bash
        coreutils
        swaynotificationcenter
      ];
      text = ''
        set -euo pipefail
        backend="${if shellBackend == "caelestia" then "caelestia" else "none"}"
        if [ "$backend" = "caelestia" ] && command -v rag-caelestia-ipc >/dev/null 2>&1; then
          if rag-caelestia-ipc drawers toggle sidebar; then exit 0; fi
        fi
        if command -v swaync-client >/dev/null 2>&1; then exec swaync-client -t -sw; fi
      '';
    })

    (writeShellApplication {
      name = "rag-shell-lock";
      runtimeInputs = [
        bash
        coreutils
        systemd
      ];
      text = ''
        set -euo pipefail
        backend="${if shellBackend == "caelestia" then "caelestia" else "none"}"
        if [ "$backend" = "caelestia" ] && command -v rag-caelestia-ipc >/dev/null 2>&1; then
          if rag-caelestia-ipc lock lock; then exit 0; fi
        fi
        exec loginctl lock-session
      '';
    })

    (writeShellApplication {
      name = "rag-power-menu";
      runtimeInputs = [
        bash
        coreutils
        rofi
        wlogout
        systemd
        hyprland
      ];
      text = ''
        set -euo pipefail
        backend="${if shellBackend == "caelestia" then "caelestia" else "none"}"
        if [ "$backend" = "caelestia" ] && command -v rag-caelestia-ipc >/dev/null 2>&1; then
          if rag-caelestia-ipc drawers toggle session; then exit 0; fi
        fi
        if command -v wlogout >/dev/null 2>&1; then exec wlogout -b 5; fi
        choice="$(printf '%s\n' 'Lock' 'Logout' 'Suspend' 'Reboot' 'Poweroff' | rofi -dmenu -i -p 'Power')" || exit 0
        case "$choice" in
          Lock) exec loginctl lock-session ;;
          Logout) exec hyprctl dispatch exit ;;
          Suspend) exec systemctl suspend ;;
          Reboot) exec systemctl reboot ;;
          Poweroff) exec systemctl poweroff ;;
        esac
      '';
    })

    (writeShellApplication {
      name = "rag-audio-menu";
      runtimeInputs = [
        bash
        coreutils
        gawk
        rofi
        wireplumber
        pavucontrol
        playerctl
      ];
      text = ''
        set -euo pipefail
        menu="$(printf '%s\n' 'Pavucontrol' 'Mute' 'Play/Pause' 'Next' 'Prev' | rofi -dmenu -i -p 'Audio')" || exit 0
        case "$menu" in
          Pavucontrol) exec pavucontrol ;;
          Mute) exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
          "Play/Pause") exec playerctl play-pause ;;
          Next) exec playerctl next ;;
          Prev) exec playerctl previous ;;
        esac
      '';
    })
    (writeShellApplication {
      name = "rag-window-menu";
      runtimeInputs = [
        bash
        coreutils
        rofi
        jq
        hyprland
      ];
      text = ''
        set -euo pipefail
        sel="$(hyprctl -j clients | jq -r '.[] | select(.mapped == true) | "[\(.workspace.name)] \(.class) - \(.title) ::: \(.address)"' | rofi -dmenu -i -p 'Windows')" || exit 0
        [ -n "$sel" ] || exit 0
        exec hyprctl dispatch focuswindow "address:''${sel##*::: }"
      '';
    })

    (writeShellApplication {
      name = "rag-calc-menu";
      runtimeInputs = [
        bash
        coreutils
        rofi
        libqalculate
        wl-clipboard
        libnotify
      ];
      text = ''
        set -euo pipefail
        expr="$(rofi -dmenu -i -p 'calc')" || exit 0
        res="$(qalc -t "$expr" | tail -n 1)" || exit 1
        printf '%s' "$res" | wl-copy
        notify-send -a "qalc" "Result copied" "$res"
      '';
    })

    (writeShellApplication {
      name = "rag-record-menu";
      runtimeInputs = [
        bash
        coreutils
        rofi
        jq
        hyprland
        slurp
        wf-recorder
        libnotify
        procps
      ];
      text = ''
        set -euo pipefail
        if pgrep -x wf-recorder >/dev/null 2>&1; then
          pkill -INT -x wf-recorder || true
          notify-send "Recording" "Finished"
          exit 0
        fi
        mode="$(printf '%s\n' 'Area' 'Active' 'Screen' | rofi -dmenu -i -p 'Record')" || exit 0
        file="$HOME/Videos/Recordings/Recording_$(date +%F_%H-%M-%S).mp4"
        mkdir -p "$(dirname "$file")"
        case "$mode" in
          Area) geometry="$(slurp)" || exit 0; wf-recorder -f "$file" -g "$geometry" >/dev/null 2>&1 & ;;
          Active)
            x="$(hyprctl -j activewindow | jq -r '.at[0]')"; y="$(hyprctl -j activewindow | jq -r '.at[1]')"
            w="$(hyprctl -j activewindow | jq -r '.size[0]')"; h="$(hyprctl -j activewindow | jq -r '.size[1]')"
            wf-recorder -f "$file" -g "$x,$y ''${w}x''${h}" >/dev/null 2>&1 &
            ;;
          Screen) wf-recorder -f "$file" >/dev/null 2>&1 & ;;
        esac
        notify-send "Recording" "Started: $(basename "$file")"
      '';
    })

    (writeShellApplication {
      name = "rag-clipboard-menu";
      runtimeInputs = [
        bash
        coreutils
        cliphist
        wl-clipboard
        rofi
      ];
      text = ''
        set -euo pipefail
        sel="$(cliphist list | rofi -dmenu -i -p 'Clipboard')" || exit 0
        cliphist decode <<<"$sel" | wl-copy
      '';
    })

    (writeShellApplication {
      name = "rag-network-menu";
      runtimeInputs = [
        bash
        coreutils
        rofi
        networkmanagerapplet
        bluez
      ];
      text = ''
        set -euo pipefail
        choice="$(printf '%s\n' 'Connections' 'Bluetooth' | rofi -dmenu -i -p 'Network')" || exit 0
        case "$choice" in
          Connections) exec nm-connection-editor ;;
          Bluetooth) exec bluetoothctl power on ;;
        esac
      '';
    })

    (writeShellApplication {
      name = "rag-quick-actions";
      runtimeInputs = [
        bash
        coreutils
        rofi
      ];
      text = ''
        set -euo pipefail
        choice="$(printf '%s\n' 'Launcher' 'Terminal' 'Files' 'Windows' 'Calc' 'Screenshot' 'Record' 'Clipboard' 'Audio' 'Network' 'Power' | rofi -dmenu -i -p 'Quick')" || exit 0
        case "$choice" in
          Launcher) exec rag-shell-launcher ;;
          Terminal) exec uwsm app -- foot ;; # Fallback
          Files) exec uwsm app -- dolphin ;;
          Windows) exec rag-window-menu ;;
          Calc) exec rag-calc-menu ;;
          Screenshot) exec rag-screenshot edit-area ;;
          Record) exec rag-record-menu ;;
          Clipboard) exec rag-clipboard-menu ;;
          Audio) exec rag-audio-menu ;;
          Network) exec rag-network-menu ;;
          Power) exec rag-power-menu ;;
        esac
      '';
    })
  ];
}

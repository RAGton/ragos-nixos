# ==============================================================================
# Módulo: Hyprland (User-level)
# Autor: Gabriel Rocha (rag) + Codex
# Data: 2026-03-12
#
# O que é:
# - Configuração Home Manager do Hyprland (arquivos em ~/.config/hypr e serviços user).
# - Integra o rice DMS como shell principal da sessão.
#
# Por quê:
# - Evita duplicação entre DMS, Waybar, Wofi e outros daemons de sessão.
# - Garante idle/lock declarativos com integração correta ao logind.
#
# Como:
# - Publica `hyprland.conf`, `hypridle.conf` e `hyprlock.conf`.
# - Desativa launchers/notificações duplicados quando DMS está ativo.
#
# Riscos:
# - Ajustes agressivos de idle/lock podem interromper workflows longos se mal calibrados.
# ==============================================================================
{
  config,
  lib,
  pkgs,
  nhModules,
  ...
}:
let
  dmsEnabled =
    (config.rag.rice.dmsUpstream.enable or false)
    || (config.rag.rice.dms.enable or false)
    || (config.programs.dank-material-shell.enable or false);
in
{
  # Monitores: voltar ao padrão do DMS/Hyprland (sem kanshi forçando scale/posições).
  services.kanshi.enable = lib.mkForce false;

  # Screenshot stack (Wayland nativo) no nível do usuário, para os binds funcionarem
  # mesmo antes de um `nixos-rebuild`.
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    swappy
    libnotify
    jq
    hyprland

    (writeShellApplication {
      name = "grimblast";
      runtimeInputs = [ bash coreutils grim slurp wl-clipboard libnotify jq hyprland ];
      text = ''
        set -euo pipefail

        notify=0
        if [[ "''${1-}" = "--notify" ]]; then
          notify=1
          shift
        fi

        verb="''${1-}"
        target="''${2-}"

        screenshots_dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
        mkdir -p "$screenshots_dir"
        ts="$(date +%F_%H-%M-%S)"
        file="$screenshots_dir/Screenshot_$ts.png"

        do_notify() {
          [[ "$notify" = 1 ]] || return 0
          notify-send -a "screenshot" "$@" >/dev/null 2>&1 || true
        }

        usage() {
          echo "Uso: grimblast [--notify] <copy|save|copysave> <area|screen|active>" >&2
          exit 2
        }

        [[ -n "$verb" && -n "$target" ]] || usage

        case "$target" in
          area)
            geometry="$(slurp)" || exit 0
            [[ -n "$geometry" ]] || exit 0
            case "$verb" in
              copy)
                grim -g "$geometry" - | wl-copy
                do_notify "Screenshot" "Área copiada para o clipboard"
                ;;
              save)
                grim -g "$geometry" "$file"
                do_notify "Screenshot" "Área salva: $(basename "$file")"
                ;;
              copysave)
                grim -g "$geometry" "$file"
                wl-copy < "$file"
                do_notify "Screenshot" "Área salva e copiada: $(basename "$file")"
                ;;
              *) usage ;;
            esac
            ;;

          screen)
            case "$verb" in
              copy)
                grim - | wl-copy
                do_notify "Screenshot" "Tela copiada para o clipboard"
                ;;
              save)
                grim "$file"
                do_notify "Screenshot" "Tela salva: $(basename "$file")"
                ;;
              copysave)
                grim "$file"
                wl-copy < "$file"
                do_notify "Screenshot" "Tela salva e copiada: $(basename "$file")"
                ;;
              *) usage ;;
            esac
            ;;

          active)
            x="$(hyprctl -j activewindow | jq -r '.at[0] // empty')"
            y="$(hyprctl -j activewindow | jq -r '.at[1] // empty')"
            w="$(hyprctl -j activewindow | jq -r '.size[0] // empty')"
            h="$(hyprctl -j activewindow | jq -r '.size[1] // empty')"
            [[ -n "$x" && -n "$y" && -n "$w" && -n "$h" ]] || {
              echo "grimblast: não foi possível obter geometria da janela ativa" >&2
              exit 1
            }
            geometry="$x,$y ''${w}x''${h}"
            case "$verb" in
              copy)
                grim -g "$geometry" - | wl-copy
                do_notify "Screenshot" "Janela ativa copiada para o clipboard"
                ;;
              save)
                grim -g "$geometry" "$file"
                do_notify "Screenshot" "Janela ativa salva: $(basename "$file")"
                ;;
              copysave)
                grim -g "$geometry" "$file"
                wl-copy < "$file"
                do_notify "Screenshot" "Janela ativa salva e copiada: $(basename "$file")"
                ;;
              *) usage ;;
            esac
            ;;

          *) usage ;;
        esac
      '';
    })

    (writeShellApplication {
      name = "rag-screenshot";
      runtimeInputs = [ bash coreutils grim slurp wl-clipboard swappy libnotify grimblast ];
      text = ''
        set -euo pipefail

        action="''${1-}"
        shift || true

        case "$action" in
          copy-area)
            exec grimblast --notify copy area
            ;;

          copysave-screen)
            exec grimblast --notify copysave screen
            ;;

          copysave-active)
            exec grimblast --notify copysave active
            ;;

          edit-area)
            tmp="''${TMPDIR:-/tmp}/screenshot-area-$(date +%F_%H-%M-%S).png"
            geometry="$(slurp)" || exit 0
            [[ -n "$geometry" ]] || exit 0
            grim -g "$geometry" "$tmp"
            exec swappy -f "$tmp"
            ;;

          edit-output)
            tmp="''${TMPDIR:-/tmp}/screenshot-screen-$(date +%F_%H-%M-%S).png"
            grim "$tmp"
            exec swappy -f "$tmp"
            ;;

          *)
            echo "Uso: rag-screenshot {copy-area|copysave-screen|copysave-active|edit-area|edit-output}" >&2
            exit 2
            ;;
        esac
      '';
    })

    (writeShellApplication {
      name = "rag-clipboard-menu";
      runtimeInputs = [ bash coreutils cliphist wl-clipboard rofi-wayland ];
      text = ''
        set -euo pipefail

        # Se DMS estiver respondendo, usa o clipboard nativo do shell.
        if command -v dms >/dev/null 2>&1 && dms ipc clipboard toggle >/dev/null 2>&1; then
          exit 0
        fi

        # Fallback: cliphist + rofi (Wayland).
        sel="$(cliphist list | rofi -dmenu -i -p 'Clipboard')" || exit 0
        [ -n "$sel" ] || exit 0
        cliphist decode <<<"$sel" | wl-copy
      '';
    })

    (writeShellApplication {
      name = "rag-power-menu";
      runtimeInputs = [ bash coreutils wlogout systemd ];
      text = ''
        set -euo pipefail

        if command -v wlogout >/dev/null 2>&1; then
          exec wlogout -b 5
        fi

        # Fallback simples sem UI
        echo "wlogout não disponível; suspendendo em 3s" >&2
        sleep 3
        exec systemctl suspend
      '';
    })

    (writeShellApplication {
      name = "rag-audio-menu";
      runtimeInputs = [ bash coreutils grep gnugrep gawk rofi-wayland wireplumber pavucontrol ];
      text = ''
        set -euo pipefail

        menu="$(printf '%s
' 'Abrir pavucontrol' 'Saída padrão' 'Entrada padrão' | rofi -dmenu -i -p 'Áudio')" || exit 0
        case "$menu" in
          "Abrir pavucontrol") exec pavucontrol ;;
          "Saída padrão")
            out="$(wpctl status | awk '/Sinks:/{f=1;next}/Sources:/{f=0}f && $1 ~ /^[0-9]+\./{gsub("\.","",$1); print $1":"substr($0,index($0,$2))}' | rofi -dmenu -i -p 'Selecionar saída')" || exit 0
            [ -n "$out" ] || exit 0
            wpctl set-default "''${out%%:*}"
            ;;
          "Entrada padrão")
            inn="$(wpctl status | awk '/Sources:/{f=1;next}/Filters:/{f=0}f && $1 ~ /^[0-9]+\./{gsub("\.","",$1); print $1":"substr($0,index($0,$2))}' | rofi -dmenu -i -p 'Selecionar entrada')" || exit 0
            [ -n "$inn" ] || exit 0
            wpctl set-default "''${inn%%:*}"
            ;;
          *) exit 0 ;;
        esac
      '';
    })

    (writeShellApplication {
      name = "rag-network-menu";
      runtimeInputs = [ bash coreutils rofi-wayland networkmanager_dmenu nm-connection-editor blueman ];
      text = ''
        set -euo pipefail

        choice="$(printf '%s
' 'Wi-Fi rápido (dmenu)' 'Editor de conexões' 'Bluetooth manager' | rofi -dmenu -i -p 'Rede/Bluetooth')" || exit 0
        case "$choice" in
          "Wi-Fi rápido (dmenu)") exec networkmanager_dmenu ;;
          "Editor de conexões") exec nm-connection-editor ;;
          "Bluetooth manager") exec blueman-manager ;;
          *) exit 0 ;;
        esac
      '';
    })

  ];

  imports = [
    "${nhModules}/misc/gtk"
    "${nhModules}/misc/qt"
    "${nhModules}/misc/wallpaper"
    "${nhModules}/misc/xdg"
    "${nhModules}/programs/swappy"
  ];

  # Boot direto (sem display manager): ao logar no tty, inicia Hyprland via UWSM.
  # Segurança: isso remove a tela de login (autologin). Use apenas se você confia no acesso físico.
  programs.zsh.loginExtra = lib.mkIf (config.rag.desktop.directLogin.enable or false) (lib.mkAfter ''
    if [[ -z "''${WAYLAND_DISPLAY-}" && -z "''${DISPLAY-}" && "''${XDG_VTNR-}" = "${toString (config.rag.desktop.directLogin.tty or 1)}" ]]; then
      if command -v uwsm >/dev/null 2>&1; then
        exec uwsm start hyprland || exec uwsm start hyprland-uwsm.desktop
      fi
      exec Hyprland
    fi
  '');

  # Tema de cursor consistente em todos os aplicativos.
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = config.gtk.cursorTheme.package;
    name = config.gtk.cursorTheme.name;
    size = 24;
  };

  # Requisito do projeto: launcher do DMS exclusivamente (sem Wofi).
  programs.wofi.enable = lib.mkForce false;

  # Hyprland via Home Manager.
  wayland.windowManager.hyprland = {
    enable = true;

    # CRÍTICO: variables = ["--all"] exporta WAYLAND_DISPLAY, DISPLAY e todas as
    # variáveis de ambiente do Hyprland para o systemd-user e o D-Bus.
    # Sem isso, serviços como waybar/cliphist/swaync esperam indefinidamente
    # até o timeout de 60s do systemd antes de continuar.
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    # Reaproveita o config versionado no repo.
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  # Publica a configuração do Hyprland a partir do store do Home Manager.
  xdg.configFile = lib.mkMerge [
    (lib.mkIf (!dmsEnabled) {
      "hypr/hyprpaper.conf".text = ''
        splash = false
        preload = ${config.wallpaper}
        wallpaper = , ${config.wallpaper}
      '';
    })
    {
      "hypr/hypridle.conf".text = ''
        general {
          # Usa hyprlock (não um script customizado) como comando de lock.
          # `pidof hyprlock ||` evita iniciar duas instâncias.
          lock_cmd = pidof hyprlock || hyprlock
          # Bloqueia VIA LOGIND antes de dormir (integração correta com systemd).
          before_sleep_cmd = loginctl lock-session
          # Re-liga displays após wakeup.
          after_sleep_cmd = hyprctl dispatch dpms on
          # Ignora idle ao reproduzir mídia fullscreen
          ignore_dbus_inhibit = false
        }

        # 3 min: dim displays
        listener {
          timeout = 150
          on-timeout = brightnessctl -s set 20%
          on-resume  = brightnessctl -r
        }

        # 5 min: bloquear tela
        listener {
          timeout = 300
          on-timeout = loginctl lock-session
          on-resume  = hyprctl dispatch dpms on
        }

        # 10 min: desligar displays (economiza bateria)
        listener {
          timeout = 600
          on-timeout = hyprctl dispatch dpms off
          on-resume  = hyprctl dispatch dpms on
        }

        # 30 min: suspender sistema
        listener {
          timeout = 1800
          on-timeout = systemctl suspend
        }
      '';

      # hyprlock: tela de bloqueio completa com blur + relógio
      "hypr/hyprlock.conf".text = ''
        general {
          grace     = 2       # segundos de grace period (teclado visível)
          hide_cursor = true
          no_fade_in  = false
          no_fade_out = false
          pam_module  = hyprlock
        }

        # Fundo com blur
        background {
          monitor =
          path    = screenshot
          blur_passes  = 3
          blur_size    = 7
          noise        = 0.0117
          contrast     = 0.8916
          brightness   = 0.8172
          vibrancy     = 0.1696
          vibrancy_darkness = 0.0
        }

        # Relógio grande centralizado
        label {
          monitor =
          text     = cmd[update:1000] echo "$(date +"%-H:%M")"
          color    = rgba(207, 213, 245, 1.0)
          font_size   = 90
          font_family = JetBrains Mono
          position    = 0, 80
          halign      = center
          valign      = center
          shadow_passes = 2
          shadow_size   = 4
        }

        # Data
        label {
          monitor =
          text     = cmd[update:10000] echo "$(date +"%A, %d de %B")"
          color    = rgba(166, 173, 200, 0.8)
          font_size   = 18
          font_family = JetBrains Mono
          position    = 0, -15
          halign      = center
          valign      = center
          shadow_passes = 2
          shadow_size   = 2
        }

        # Campo de senha
        input-field {
          monitor =
          size     = 250, 50
          outline_thickness = 2
          dots_size    = 0.26
          dots_spacing = 0.64
          dots_center  = true
          outer_color  = rgba(138, 133, 193, 1.0)
          inner_color  = rgba(26, 27, 38, 0.85)
          font_color   = rgba(207, 213, 245, 1.0)
          fade_on_empty = true
          placeholder_text = <span foreground="##a9b1d6" font_size="small">Senha...</span>
          rounding     = 12
          check_color  = rgba(115, 218, 202, 1.0)
          fail_color   = rgba(247, 118, 142, 1.0)
          fail_text    = <i>Senha incorreta :(</i>
          fail_timeout = 2000
          capslock_color = rgba(255, 158, 100, 1.0)
          position = 0, -200
          halign   = center
          valign   = center
        }
      '';
    }
  ];

  # DMS como fonte única de barra/launcher/notificações/wallpaper.
  programs.dank-material-shell = lib.mkIf dmsEnabled {
    systemd.target = "hyprland-session.target";

    # Settings: sempre usar o snapshot versionado no repo.
    # Importante: isso mantém o arquivo “fonte da verdade” no Git e evita drift.
    settings = lib.mkMerge [
      (builtins.fromJSON (builtins.readFile ../../files/dms/settings.json))

      # Evita timeout de PowerProfiles quando o serviço D-Bus não está pronto.
      { osdPowerProfileEnabled = false; }
    ];

    # Wallpaper declarativo vindo da configuração Nix/Home Manager.
    session = {
      wallpaperPath = toString config.wallpaper;
      wallpaperPathLight = toString config.wallpaper;
      wallpaperPathDark = toString config.wallpaper;
    };
  };

  # Garante que os arquivos do DMS existam como arquivos graváveis.
  # O Hyprland faz `source` desses arquivos; se não existirem, podem gerar erros.
  # Importante: NÃO gerenciar via xdg.configFile/home.file, para não virar symlink read-only.
  home.activation.ensureHyprDmsSnippets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/hypr/dms"

    for f in binds.conf colors.conf layout.conf windowrules.conf; do
      if [ ! -e "$HOME/.config/hypr/dms/$f" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/touch "$HOME/.config/hypr/dms/$f"
      fi
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 0644 "$HOME/.config/hypr/dms/$f"
    done
  '';

  dconf.settings = {
    "org/blueman/general" = {
      "plugin-list" = lib.mkForce [ "!StatusNotifierItem" ];
    };

    "org/blueman/plugins/powermanager" = {
      "auto-power-on" = true;
    };

    "org/gnome/calculator" = {
      "accuracy" = 9;
      "angle-units" = "degrees";
      "base" = 10;
      "button-mode" = "basic";
      "number-format" = "automatic";
      "show-thousands" = false;
      "show-zeroes" = false;
      "source-currency" = "";
      "source-units" = "degree";
      "target-currency" = "";
      "target-units" = "radian";
      "window-maximized" = false;
    };

    "org/gnome/desktop/wm/preferences" = {
      "button-layout" = lib.mkForce "";
    };


    "org/gnome/nm-applet" = {
      "disable-connected-notifications" = true;
      "disable-vpn-notifications" = true;
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      "show-hidden" = true;
    };

    "org/gtk/settings/file-chooser" = {
      "date-format" = "regular";
      "location-mode" = "path-bar";
      "show-hidden" = true;
      "show-size-column" = true;
      "show-type-column" = true;
      "sort-column" = "name";
      "sort-directories-first" = false;
      "sort-order" = "ascending";
      "type-format" = "category";
      "view-type" = "list";
    };
  };
}

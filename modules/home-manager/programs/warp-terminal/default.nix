{
  config,
  pkgs,
  lib,
  ...
}:
let
  warpDistroboxName = "ragos-warp";
  warpManifestPath = "${config.xdg.configHome}/distrobox/warp-terminal.ini";
  warpPacmanArch =
    if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "x86_64"
    else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then "aarch64"
    else throw "Unsupported platform for Warp distrobox: ${pkgs.stdenv.hostPlatform.system}";
  warpBootstrap = pkgs.writeShellApplication {
    name = "rag-warp-bootstrap";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.distrobox
      pkgs.podman
      pkgs.gawk
      pkgs.gnugrep
    ];
    text = ''
      set -euo pipefail

      container_name="${warpDistroboxName}"
      manifest_path="${warpManifestPath}"

      list_containers() {
        distrobox list --no-color 2>/dev/null | tail -n +2 | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}'
      }

      create_container() {
        export DBX_NON_INTERACTIVE=1
        distrobox assemble create --file "$manifest_path" --name "$container_name"
      }

      if ! list_containers | grep -qx "$container_name"; then
        create_container
      fi

      if ! podman container inspect "$container_name" >/dev/null 2>&1 || ! podman start "$container_name" >/dev/null 2>&1; then
        distrobox rm --force "$container_name" >/dev/null 2>&1 || true
        create_container
      fi

      retries=30
      until podman exec --user 0 "$container_name" sh -lc '
        set -euo pipefail
        tmp_config="$(mktemp)"
        awk "
          BEGIN { skip = 0 }
          /^\[warpdotdev\]$/ { skip = 1; next }
          skip && /^\[/ { skip = 0 }
          !skip { print }
        " /etc/pacman.conf > "$tmp_config"
        pacman --config "$tmp_config" -Sy --noconfirm --needed curl gnupg sudo
        rm -f "$tmp_config"
      '; do
        retries="$((retries - 1))"
        if [ "$retries" -le 0 ]; then
          exit 1
        fi
        sleep 2
      done

      distrobox enter --no-tty --name "$container_name" -- sh -lc '
        set -euo pipefail

        if ! grep -Fq "[warpdotdev]" /etc/pacman.conf; then
          printf "%s\n%s\n" \
            "[warpdotdev]" \
            "Server = https://releases.warp.dev/linux/pacman/warpdotdev/${warpPacmanArch}" | sudo tee -a /etc/pacman.conf >/dev/null
        fi

        if ! sudo pacman-key --list-keys "linux-maintainers@warp.dev" >/dev/null 2>&1; then
          sudo pacman-key -r "linux-maintainers@warp.dev"
        fi

        sudo pacman-key --lsign-key "linux-maintainers@warp.dev" >/dev/null 2>&1 || true
        sudo pacman -Syu --noconfirm --needed warp-terminal

        distrobox-export --app /usr/share/applications/dev.warp.Warp.desktop --export-label none >/dev/null 2>&1 || true
      '
    '';
  };
in
{
  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    xdg.configFile."distrobox/warp-terminal.ini".text = ''
      [${warpDistroboxName}]
      image=archlinux:latest
      pull=true
      init=false
      nvidia=false
      start_now=false
    '';

    home.packages = [
      warpBootstrap
      (pkgs.writeShellApplication {
        name = "warp-terminal";
        runtimeInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.distrobox
          warpBootstrap
        ];
        text = ''
          set -euo pipefail

          container_name="${warpDistroboxName}"
          rag-warp-bootstrap

          exec distrobox enter --no-tty --name "$container_name" -- warp-terminal "$@"
        '';
      })
    ];

    # Garante que o app desktop do Warp apareça no host para DMS, launcher e mime handlers.
    home.activation.warp-terminal-distrobox-bootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${warpBootstrap}/bin/rag-warp-bootstrap >/dev/null 2>&1 || true
    '';

    # Ajustes de performance:
    # - Desliga auto-indexação de codebase do Agent Mode (pode ser bem pesado)
    # - Desliga sync de settings (reduz tráfego/latência na inicialização)
    # Mantém o arquivo intacto, apenas sobrescrevendo essas duas chaves.
    home.activation.warp-terminal-performance-tweaks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      prefs_file="${config.xdg.configHome}/warp-terminal/user_preferences.json"
      if [ -f "$prefs_file" ]; then
        tmp="$(mktemp)"
        if ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1 < "$prefs_file"; then
          ${pkgs.jq}/bin/jq '
            .prefs.AgentModeCodebaseContextAutoIndexing = "false" |
            .prefs.IsSettingsSyncEnabled = "false"
          ' "$prefs_file" > "$tmp" && mv "$tmp" "$prefs_file"
        else
          rm -f "$tmp"
        fi
      fi
    '';
  };
}

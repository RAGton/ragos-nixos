{
  writeShellApplication,
  coreutils,
  curl,
  gitMinimal,
  gnugrep,
  gnused,
  jq,
  libvirt,
  nh,
  nix,
  nvd,
  nixos-install-tools,
  util-linux,
}:
writeShellApplication {
  name = "kryonix";
  runtimeInputs = [
    coreutils
    curl
    gitMinimal
    gnugrep
    gnused
    jq
    libvirt
    nh
    nix
    nvd
    nixos-install-tools
    util-linux
  ];
  text = ''
        set -euo pipefail

        current_hostname() {
          cat /proc/sys/kernel/hostname
        }

        init_colors() {
          blue=""
          reset=""

          if [[ -t 1 && -z "''${NO_COLOR:-}" ]]; then
            blue=$'\033[34m'
            reset=$'\033[0m'
          fi
        }

        blue_line() {
          local text="$1"

          if [[ -n "$blue" ]]; then
            printf '%b%s%b\n' "$blue" "$text" "$reset"
          else
            printf '%s\n' "$text"
          fi
        }

        init_colors

        map_runtime_host() {
          local runtime_host lower
          runtime_host="$(current_hostname)"
          lower="$(printf '%s' "$runtime_host" | tr '[:upper:]' '[:lower:]')"

          case "$lower" in
            rve-glacier)
              printf '%s\n' "glacier"
              ;;
            glacier)
              printf '%s\n' "glacier"
              ;;
            inspiron|inspiron-nina|iso)
              printf '%s\n' "$lower"
              ;;
            *)
              printf '%s\n' "$lower"
              ;;
          esac
        }

        is_kryonix_checkout() {
          local repo_root="$1"

          [[ -e "$repo_root/flake.nix" ]] || return 1
          [[ -e "$repo_root/packages/kryonix-cli.nix" || -e "$repo_root/packages/ragos-cli.nix" ]] || return 1
          [[ -d "$repo_root/hosts" ]] || return 1
        }

        find_git_root() {
          git rev-parse --show-toplevel 2>/dev/null
        }

        find_local_flake_root() {
          local git_root

          if [[ -e ./flake.nix ]]; then
            printf '%s\n' "."
            return 0
          fi

          if git_root="$(find_git_root)" && [[ -e "$git_root/flake.nix" ]]; then
            printf '%s\n' "$git_root"
            return 0
          fi

          return 1
        }

        print_command() {
          local line="+"
          local arg

          for arg in "$@"; do
            line="$line $(printf '%q' "$arg")"
          done

          blue_line "$line"
        }

        run_command() {
          print_command "$@"

          if "$@"; then
            return 0
          else
            local status=$?
            printf '%s\n' "ERRO: comando falhou com status $status." >&2
            return "$status"
          fi
        }

        run_flake_command() {
          if [[ -n "$flake_workdir" ]]; then
            (
              cd "$flake_workdir"
              run_command "$@"
            )
            return $?
          fi

          run_command "$@"
        }

        capture_flake_command() {
          if [[ -n "$flake_workdir" ]]; then
            (
              cd "$flake_workdir"
              "$@"
            )
            return $?
          fi

          "$@"
        }

        resolve_bootstrap_repo_source() {
          if [[ -n "''${KRYONIX_BOOTSTRAP_REPO:-}" ]]; then
            printf '%s\n' "$KRYONIX_BOOTSTRAP_REPO"
            return 0
          fi

          if [[ -n "''${KRYONIX_REPO_URL:-}" ]]; then
            printf '%s\n' "$KRYONIX_REPO_URL"
            return 0
          fi

          if [[ -n "''${KRYONIX_REPO:-}" ]]; then
            printf '%s\n' "$KRYONIX_REPO"
            return 0
          fi

          if [[ -n "''${RAGOS_BOOTSTRAP_REPO:-}" ]]; then
            printf '%s\n' "$RAGOS_BOOTSTRAP_REPO"
            return 0
          fi

          if [[ -n "''${RAGOS_REPO_URL:-}" ]]; then
            printf '%s\n' "$RAGOS_REPO_URL"
            return 0
          fi

          if [[ -n "''${RAGOS_REPO:-}" ]]; then
            printf '%s\n' "$RAGOS_REPO"
            return 0
          fi

          printf '%s\n' 'https://github.com/RAGton/kryonix'
        }

        run_privileged() {
          if [[ "$(id -u)" -eq 0 ]]; then
            "$@"
            return $?
          fi

          if command -v sudo >/dev/null 2>&1; then
            sudo -n "$@"
            return $?
          fi

          printf '%s\n' 'kryonix bootstrap requer root ou sudo sem prompt.' >&2
          return 1
        }

        write_default_host_skeleton() {
          local destination="$1"
          local skeleton_file
          skeleton_file="$(mktemp)"

          printf '%s\n' \
            '{ hostname, ... }:' \
            '{' \
            '  imports = [' \
            '    ./hardware-configuration.nix' \
            '  ];' \
            '  networking.hostName = hostname;' \
            '  system.stateVersion = "26.05";' \
            '}' > "$skeleton_file"

          run_privileged install -Dm0644 "$skeleton_file" "$destination"
          rm -f "$skeleton_file"
          bootstrap_host_created=1
        }

        ensure_local_hardware_config() {
          local local_hw_path="$1"
          local generated_hw
          local temp_hw

          if [[ -e "$local_hw_path" ]]; then
            return 0
          fi

          if ! command -v nixos-generate-config >/dev/null 2>&1; then
            printf '%s\n' "kryonix: não encontrei nixos-generate-config para gerar $local_hw_path" >&2
            return 1
          fi

          generated_hw="$(run_privileged nixos-generate-config --show-hardware-config)"
          temp_hw="$(mktemp)"
          printf '%s\n' "$generated_hw" > "$temp_hw"
          run_privileged install -Dm0644 "$temp_hw" "$local_hw_path"
          rm -f "$temp_hw"
          bootstrap_local_created=1
        }

        ensure_bootstrap_host_layout() {
          local repo_root="$1"
          local host_name="$2"
          local repo_host_dir="$repo_root/hosts/$host_name"
          local repo_host_default="$repo_host_dir/default.nix"
          local repo_hw="$repo_host_dir/hardware-configuration.nix"
          local local_host_dir="$repo_root/local/$host_name"
          local local_hw="$local_host_dir/hardware-configuration.nix"
          local existing_target

          if [[ -e "$repo_host_dir" && ! -d "$repo_host_dir" ]]; then
            printf '%s\n' "kryonix: $repo_host_dir existe, mas não é um diretório" >&2
            return 1
          fi

          if [[ ! -d "$repo_host_dir" ]]; then
            run_privileged install -d -m 0755 "$repo_host_dir"
            bootstrap_host_created=1
          fi

          if [[ -L "$repo_hw" ]]; then
            existing_target="$(readlink "$repo_hw")"
            if [[ "$existing_target" != "$local_hw" ]]; then
              printf '%s\n' "kryonix: conflito em $repo_hw: symlink aponta para $existing_target, esperado $local_hw" >&2
              return 1
            fi
          elif [[ -e "$repo_hw" ]]; then
            if [[ ! -d "$local_host_dir" ]]; then
              run_privileged install -d -m 0755 "$local_host_dir"
              bootstrap_local_created=1
            fi

            ensure_local_hardware_config "$local_hw" || return 1
            bootstrap_conflict_detected=1
          else
            if [[ ! -d "$local_host_dir" ]]; then
              run_privileged install -d -m 0755 "$local_host_dir"
              bootstrap_local_created=1
            fi

            ensure_local_hardware_config "$local_hw" || return 1
            run_privileged ln -s "$local_hw" "$repo_hw"
            bootstrap_symlink_created=1
          fi

          if [[ ! -e "$repo_host_default" ]]; then
            write_default_host_skeleton "$repo_host_default"
          fi
        }

        bootstrap_kryonix_checkout() {
          local host_name="$1"
          local repo_root="/etc/kryonix"
          local repo_source

          repo_source="$(resolve_bootstrap_repo_source)"

          if [[ -e "$repo_root/flake.nix" ]]; then
            return 0
          fi

          if [[ -e /etc/ragos/flake.nix ]]; then
            bootstrap_repo_root="/etc/ragos"
            return 0
          fi

          if [[ -e "$repo_root" && ! -e "$repo_root/flake.nix" ]]; then
            printf '%s\n' "kryonix: $repo_root existe, mas não contém flake.nix; não posso bootstrapar sem limpeza manual." >&2
            return 1
          fi

          if [[ -z "$repo_source" ]]; then
            printf '%s\n' 'kryonix: não existe repo configurado para bootstrap.' >&2
            return 1
          fi

          if ! run_privileged git clone --origin origin "$repo_source" "$repo_root"; then
            printf '%s\n' "kryonix: falha ao clonar $repo_source para $repo_root" >&2
            return 1
          fi

          bootstrap_performed=1
          bootstrap_repo_created=1
          bootstrap_repo_source="$repo_source"
          bootstrap_repo_root="$repo_root"

          ensure_bootstrap_host_layout "$repo_root" "$host_name" || return 1
          return 0
        }

        is_path_like_flake_ref() {
          local candidate="$1"

          case "$candidate" in
            path:*|/*|./*|../*|.|..)
              return 0
              ;;
          esac

          [[ -d "$candidate" ]]
        }

        use_local_flake() {
          local mode="$1"
          local root="$2"

          if [[ "$root" == path:* ]]; then
            root="''${root#path:}"
          fi

          if [[ -z "$root" || ! -d "$root" ]]; then
            printf '%s\n' "kryonix: flake local inválida '$root'; esperado diretório com flake.nix." >&2
            return 1
          fi

          if [[ ! -e "$root/flake.nix" ]]; then
            printf '%s\n' "kryonix: flake local inválida '$root'; esperado arquivo flake.nix." >&2
            return 1
          fi

          flake_mode="$mode"
          flake_root="$root"
          flake_workdir="$root"
          flake_ref="."
        }

        use_flake_input() {
          local mode="$1"
          local candidate="$2"

          if is_path_like_flake_ref "$candidate"; then
            use_local_flake "$mode" "$candidate"
            return $?
          fi

          flake_mode="$mode"
          flake_root=""
          flake_workdir=""
          flake_ref="$candidate"
        }

        kryonix_git_repo_path() {
          if [[ -n "''${KRYONIX_SYSTEM_REPO:-}" ]]; then
            printf '%s\n' "$KRYONIX_SYSTEM_REPO"
            return 0
          fi

          if [[ -n "''${RAGOS_SYSTEM_REPO:-}" ]]; then
            printf '%s\n' "$RAGOS_SYSTEM_REPO"
            return 0
          fi

          if [[ -e /etc/kryonix ]]; then
            printf '%s\n' "/etc/kryonix"
            return 0
          fi

          printf '%s\n' "/etc/ragos"
        }

        is_git_repo() {
          local repo_path="$1"

          git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1
        }

        git_current_branch() {
          local repo_path="$1"

          git -C "$repo_path" branch --show-current 2>/dev/null || true
        }

        git_origin_url() {
          local repo_path="$1"

          git -C "$repo_path" remote get-url origin 2>/dev/null || true
        }

        git_short_changes() {
          local repo_path="$1"

          git -C "$repo_path" status --short 2>/dev/null || true
        }

        print_git_changes() {
          local repo_path="$1"
          local changes

          changes="$(git_short_changes "$repo_path")"
          if [[ -z "$changes" ]]; then
            blue_line '  mudanças locais : nenhuma'
            return 0
          fi

          blue_line '  mudanças locais :'
          printf '%s\n' "$changes"
        }

        print_kryonix_git_status() {
          local repo_path repo_root branch origin

          repo_path="$(kryonix_git_repo_path)"
          blue_line 'Kryonix git-status'
          blue_line "  path            : $repo_path"
          if [[ -L "$repo_path" ]]; then
            blue_line "  symlink         : $(readlink "$repo_path")"
          fi

          if ! is_git_repo "$repo_path"; then
            blue_line '  status          : ERRO'
            printf '%s\n' "ERRO: $repo_path não é um git repo válido." >&2
            return 1
          fi

          repo_root="$(git -C "$repo_path" rev-parse --show-toplevel)"
          branch="$(git_current_branch "$repo_path")"
          origin="$(git_origin_url "$repo_path")"
          blue_line "  repo root       : $repo_root"
          blue_line "  branch          : ''${branch:-desconhecida}"
          blue_line "  remoto origin   : ''${origin:-ausente}"

          if [[ "$branch" != "main" ]]; then
            blue_line '  ATENÇÃO         : branch ativa não é main'
          fi
          if [[ -z "$origin" ]]; then
            blue_line '  ATENÇÃO         : remote origin ausente'
          fi

          print_git_changes "$repo_path"
          [[ "$branch" == "main" && -n "$origin" ]]
        }

        print_usage() {
          while IFS= read -r line; do
            blue_line "$line"
          done <<'EOF'
    Kryonix CLI
    Uso:
      kryonix <comando> [opcoes] [-- args extras]
    Comandos:
      switch    Aplica o host com nh os switch
      boot      Gera e registra a proxima geracao com nh os boot
      test      Testa a geracao atual com nh os test
      home      Aplica o Home Manager do usuario atual
      update    Atualiza os inputs da flake
      rebuild   Builda o toplevel do host sem ativar
      clean     Limpa geracoes antigas com nh clean all
      diff      Compara /run/current-system com o proximo toplevel
      repl      Abre nix repl na flake
      doctor    Mostra diagnostico rapido do host e do repositorio
      git-status Mostra branch, origin e mudanças locais de /etc/kryonix (fallback: /etc/ragos)
      vm        Lista VMs via libvirt
      iso       Builda a ISO publica do Kryonix
      fmt       Roda o formatter da flake
      check     Roda nix flake check --keep-going
      brain     Acessa o Kryonix Brain (search, stats, health)
    Opcoes globais:
      --host <host>    Forca o alvo da flake (ex.: glacier)
      --user <user>    Usuario para o comando home
      --flake <path>   Caminho ou flake ref a usar
      --update         Atualiza inputs quando suportado
      --no-update      Usa o flake.lock atual
      --verbose        Aumenta verbosidade
      --dry            Dry-run quando suportado
      --help           Mostra esta ajuda
    Exemplos:
      kryonix switch
      kryonix switch inspiron
      kryonix switch --update --verbose
      kryonix boot --update
      kryonix home --user rocha
      kryonix rebuild
      kryonix diff
      kryonix doctor
      kryonix git-status
      kryonix iso
    EOF
        }

        resolve_flake() {
          local explicit="''${1:-}"
          local local_root

          flake_mode=""
          flake_root=""
          flake_workdir=""
          flake_ref=""
          bootstrap_performed=0
          bootstrap_repo_created=0
          bootstrap_local_created=0
          bootstrap_host_created=0
          bootstrap_symlink_created=0
          bootstrap_conflict_detected=0
          bootstrap_repo_source=""
          bootstrap_repo_root=""

          if [[ -n "$explicit" ]]; then
            use_flake_input "explicit" "$explicit"
          elif [[ -n "''${KRYONIX_FLAKE:-}" ]]; then
            use_flake_input "env" "$KRYONIX_FLAKE"
          elif [[ -n "''${RAGOS_FLAKE:-}" ]]; then
            use_flake_input "env-ragos-compat" "$RAGOS_FLAKE"
          elif local_root="$(find_local_flake_root)"; then
            use_local_flake "dev-repo" "$local_root"
          elif [[ -e /etc/kryonix/flake.nix ]]; then
            use_local_flake "etc-kryonix" "/etc/kryonix"
          elif [[ -e /etc/ragos/flake.nix ]]; then
            use_local_flake "etc-ragos-compat" "/etc/ragos"
          else
            printf '%s\n' 'kryonix: não foi possível resolver uma flake.' >&2
            printf '%s\n' 'Use um destes caminhos:' >&2
            printf '%s\n' '- kryonix <comando> --flake /caminho/para/o/repo' >&2
            printf '%s\n' '- exporte KRYONIX_FLAKE com uma flake válida' >&2
            printf '%s\n' '- execute o comando dentro do checkout Git do projeto' >&2
            printf '%s\n' '- garanta que /etc/kryonix/flake.nix ou /etc/ragos/flake.nix exista na máquina instalada' >&2
            return 1
          fi
        }

        flake_lock_hash() {
          local lock_path="$1"

          if [[ ! -f "$lock_path" ]]; then
            printf '%s\n' "missing"
            return 0
          fi

          sha256sum "$lock_path" | sed 's/[[:space:]].*//'
        }

        update_flake_lock() {
          local include_extra="''${1:-0}"
          local before_hash=""
          local after_hash=""
          local update_args=()

          update_args+=("''${verbose_args[@]}")
          if (( include_extra )); then
            update_args+=("''${extra_args[@]}")
          fi

          if [[ -n "$flake_workdir" ]]; then
            before_hash="$(flake_lock_hash "$flake_workdir/flake.lock")"
            run_flake_command nix flake update "''${update_args[@]}"
            after_hash="$(flake_lock_hash "$flake_workdir/flake.lock")"

            if [[ "$before_hash" == "$after_hash" ]]; then
              blue_line 'OK: flake.lock já estava atualizado.'
            else
              blue_line 'OK: flake.lock atualizado.'
            fi
            return 0
          fi

          run_command nix flake update --flake "$flake_ref" "''${update_args[@]}"
        }

        update_flake_if_requested() {
          if (( update )); then
            update_flake_lock 0
          elif (( verbose > 0 )); then
            blue_line '  update          : não solicitado; usando flake.lock atual'
          fi
        }

        print_flake_resolution() {
          if (( verbose > 0 )); then
            blue_line 'Kryonix CLI'
            blue_line "  host atual      : $(current_hostname)"
            blue_line "  modo detectado   : $flake_mode"
            blue_line "  flake resolvida  : $flake_ref"
            if [[ -n "$flake_root" ]]; then
              blue_line "  flake raiz       : $flake_root"
            fi
            if [[ -n "$flake_workdir" ]]; then
              blue_line "  diretório exec   : $flake_workdir"
            fi
            blue_line "  flake host       : $flake_host"
            blue_line "  update          : $(if (( update )); then printf 'sim'; else printf 'não'; fi)"
            if (( bootstrap_performed || bootstrap_repo_created || bootstrap_host_created || bootstrap_local_created || bootstrap_symlink_created || bootstrap_conflict_detected )); then
              blue_line '  bootstrap        : sim'
              if [[ -n "$bootstrap_repo_source" ]]; then
                blue_line "  repo origem      : $bootstrap_repo_source"
              fi
              if [[ -n "$bootstrap_repo_root" ]]; then
                blue_line "  repo raiz        : $bootstrap_repo_root"
              fi
              blue_line "  repo clonado     : $(if (( bootstrap_repo_created )); then printf 'sim'; else printf 'não'; fi)"
              blue_line "  host local       : $(if (( bootstrap_host_created )); then printf 'sim'; else printf 'não'; fi)"
              blue_line "  local file       : $(if (( bootstrap_local_created )); then printf 'sim'; else printf 'não'; fi)"
              blue_line "  symlink          : $(if (( bootstrap_symlink_created )); then printf 'sim'; else printf 'não'; fi)"
              blue_line "  bootstrap ok     : $(if (( bootstrap_performed )); then printf 'sim'; else printf 'não'; fi)"
              if (( bootstrap_conflict_detected )); then
                blue_line '  conflito         : arquivo versionado preservado'
              fi
            fi
          fi
        }

        accepts_positional_host() {
          case "$subcommand" in
            switch|boot|test|home|rebuild|diff|doctor)
              return 0
              ;;
          esac

          return 1
        }

        if [[ "''${1:-}" == "--help" || "''${1:-}" == "-h" ]]; then
          subcommand="help"
        else
          subcommand="''${1:-help}"
        fi
        if [[ $# -gt 0 ]]; then
          shift
        fi

        update=0
        verbose=0
        dry=0
        flake_arg=""
        host_arg=""
        user_arg="$(id -un)"
        extra_args=()

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --update|-u)
              update=1
              ;;
            --no-update)
              update=0
              ;;
            --verbose|-v)
              verbose=$((verbose + 1))
              ;;
            --dry|-n)
              dry=1
              ;;
            --host|-H)
              if [[ $# -lt 2 ]]; then
                printf '%s\n' 'kryonix: --host requer um valor.' >&2
                exit 2
              fi
              host_arg="$2"
              shift
              ;;
            --user)
              if [[ $# -lt 2 ]]; then
                printf '%s\n' 'kryonix: --user requer um valor.' >&2
                exit 2
              fi
              user_arg="$2"
              shift
              ;;
            --flake)
              if [[ $# -lt 2 ]]; then
                printf '%s\n' 'kryonix: --flake requer um valor.' >&2
                exit 2
              fi
              flake_arg="$2"
              shift
              ;;
            --help|-h)
              print_usage
              exit 0
              ;;
            --)
              shift
              extra_args+=("$@")
              break
              ;;
            *)
              if accepts_positional_host && [[ -z "$host_arg" && "$1" != -* ]]; then
                host_arg="$1"
              else
                extra_args+=("$1")
              fi
              ;;
          esac
          shift
        done

        flake_host="''${host_arg:-$(map_runtime_host)}"

        case "$subcommand" in
          help|"")
            print_usage
            exit 0
            ;;

          clean|vm|git-status)
            needs_flake=0
            ;;

          *)
            needs_flake=1
            ;;
        esac

        if (( needs_flake )); then
          resolve_flake "$flake_arg"
        else
          flake_mode="none"
          flake_root=""
          flake_workdir=""
          flake_ref=""
        fi

        home_target="''${user_arg}@''${flake_host}"
        verbose_args=()
        dry_args=()

        verbose_count="$verbose"
        while (( verbose_count > 0 )); do
          verbose_args+=("-v")
          verbose_count=$((verbose_count - 1))
        done

        if (( needs_flake )); then
          print_flake_resolution
        fi

        if (( dry )); then
          dry_args+=("--dry")
        fi

        case "$subcommand" in
          switch|boot|test)
            update_flake_if_requested
            cmd=(nh os "$subcommand" "$flake_ref" -H "$flake_host")
            cmd+=("''${verbose_args[@]}" "''${dry_args[@]}")
            if [[ "''${#extra_args[@]}" -gt 0 ]]; then
              cmd+=("--" "''${extra_args[@]}")
            fi
            run_flake_command "''${cmd[@]}"
            ;;

          home)
            update_flake_if_requested
            cmd=(nh home switch "$flake_ref" -c "$home_target")
            cmd+=("''${verbose_args[@]}" "''${dry_args[@]}")
            if [[ "''${#extra_args[@]}" -gt 0 ]]; then
              cmd+=("--" "''${extra_args[@]}")
            fi
            run_flake_command "''${cmd[@]}"
            ;;

          rebuild)
            update_flake_if_requested
            cmd=(nix build "''${flake_ref}#nixosConfigurations.''${flake_host}.config.system.build.toplevel")
            cmd+=("''${verbose_args[@]}" "''${extra_args[@]}")
            run_flake_command "''${cmd[@]}"
            ;;

          update)
            update_flake_lock 1
            ;;

          clean)
            cmd=(nh clean all "''${verbose_args[@]}" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          diff)
            target_path="$(capture_flake_command nix build --no-link --print-out-paths "''${flake_ref}#nixosConfigurations.''${flake_host}.config.system.build.toplevel" "''${extra_args[@]}")"
            run_command nvd diff /run/current-system "$target_path"
            ;;

          repl)
            cmd=(nix repl "$flake_ref" "''${extra_args[@]}")
            run_flake_command "''${cmd[@]}"
            ;;

          doctor)
            blue_line 'Kryonix doctor'
            blue_line "  host atual   : $(current_hostname)"
            blue_line "  modo detectado: $flake_mode"
            blue_line "  flake resolvida: $flake_ref"
            blue_line "  flake host   : $flake_host"
            blue_line "  home target  : $home_target"
            blue_line "  flake root   : $flake_root"
            blue_line "  exec dir     : $flake_workdir"
            blue_line "  user         : $user_arg"

            if [[ -n "$flake_root" && -e "$flake_root/flake.nix" ]]; then
              blue_line '  flake        : ok'
            elif [[ -n "$flake_root" ]]; then
              blue_line "  flake        : ausente em $flake_root"
            else
              blue_line '  flake        : origem remota ou raiz nao local'
            fi

            if mount_info="$(findmnt -no SOURCE,TARGET /srv/ragenterprise 2>/dev/null)"; then
              blue_line "  storage      : $mount_info"
            else
              blue_line '  storage      : /srv/ragenterprise nao montado'
            fi

            if command -v systemctl >/dev/null 2>&1; then
              blue_line "  libvirtd     : $(systemctl is-enabled libvirtd 2>/dev/null || printf 'unknown')"
            fi

            if drv_path="$(capture_flake_command nix eval "''${flake_ref}#nixosConfigurations.''${flake_host}.config.system.build.toplevel.drvPath" --raw 2>/dev/null)"; then
              blue_line "  toplevel drv : $drv_path"
            else
              blue_line '  toplevel drv : falhou na avaliacao'
            fi
            ;;

          git-status)
            print_kryonix_git_status
            ;;

          vm)
            run_command virsh list --all
            ;;

          iso)
            cmd=(nix build "''${flake_ref}#nixosConfigurations.iso.config.system.build.isoImage" "''${verbose_args[@]}" "''${extra_args[@]}")
            run_flake_command "''${cmd[@]}"
            ;;

          fmt)
            cmd=(nix fmt "$flake_ref" "''${verbose_args[@]}" "''${extra_args[@]}")
            run_flake_command "''${cmd[@]}"
            ;;

          check)
            cmd=(nix flake check "$flake_ref" --keep-going "''${verbose_args[@]}" "''${extra_args[@]}")
            run_flake_command "''${cmd[@]}"
            ;;
            
          brain)
            brain_sub="''${1:-help}"
            shift || true
            case "$brain_sub" in
              search|ask|stats|health)
                # Tenta ler a key do ambiente, se não existir tenta do arquivo env
                API_KEY="''${KRYONIX_BRAIN_KEY:-}"
                if [[ -z "$API_KEY" ]] && [[ -f "/etc/kryonix/brain.env" ]]; then
                  API_KEY=$(grep KRYONIX_BRAIN_KEY /etc/kryonix/brain.env | cut -d= -f2 | tr -d '"' | tr -d "'")
                fi

                case "$brain_sub" in
                  search|ask)
                    query="''${*:-}"
                    if [[ -z "$query" ]]; then echo "Uso: kryonix brain search \"pergunta\""; exit 1; fi
                    if [[ -z "$API_KEY" ]]; then echo "Erro: KRYONIX_BRAIN_KEY não encontrada."; exit 1; fi
                    
                    if [[ -n "''${KRYONIX_BRAIN_URL:-}" ]]; then
                       curl -s -X POST "$KRYONIX_BRAIN_URL/search" \
                         -H "Content-Type: application/json" \
                         -H "X-API-Key: $API_KEY" \
                         -d "{\"query\": \"$query\"}" | jq -r '.answer'
                    else
                       echo "Erro: KRYONIX_BRAIN_URL não definida. Host não está em modo CLIENTE."
                       exit 1
                    fi
                    ;;
                  stats)
                    if [[ -z "$API_KEY" ]]; then echo "Erro: KRYONIX_BRAIN_KEY não encontrada."; exit 1; fi
                    if [[ -n "''${KRYONIX_BRAIN_URL:-}" ]]; then
                       curl -s -H "X-API-Key: $API_KEY" "$KRYONIX_BRAIN_URL/stats" | jq .
                    else
                       echo "Erro: KRYONIX_BRAIN_URL não definida."
                       exit 1
                    fi
                    ;;
                  health)
                    if [[ -n "''${KRYONIX_BRAIN_URL:-}" ]]; then
                       curl -s "$KRYONIX_BRAIN_URL/health" | jq .
                    else
                       echo "Erro: KRYONIX_BRAIN_URL não definida."
                       exit 1
                    fi
                    ;;
                esac
                ;;
               *)
                 echo "Uso: kryonix brain <search|stats|health>"
                 exit 1
                 ;;
            esac
            ;;

          *)
            printf 'Comando desconhecido: %s\n\n' "$subcommand" >&2
            print_usage >&2
            exit 1
            ;;
        esac
  '';
}

{
  writeShellApplication,
  coreutils,
  gitMinimal,
  gnugrep,
  gnused,
  libvirt,
  nh,
  nix,
  nvd,
  nixos-install-tools,
  util-linux,
}:
writeShellApplication {
  name = "ragos";
  runtimeInputs = [
    coreutils
    gitMinimal
    gnugrep
    gnused
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

        find_local_flake_root() {
          local current_dir parent_dir
          current_dir="$(pwd)"

          while [[ -n "$current_dir" ]]; do
            if [[ -e "$current_dir/flake.nix" ]]; then
              printf '%s\n' "$current_dir"
              return 0
            fi

            if [[ "$current_dir" == "/" ]]; then
              return 1
            fi

            parent_dir="$(dirname "$current_dir")"
            if [[ "$parent_dir" == "$current_dir" ]]; then
              return 1
            fi

            current_dir="$parent_dir"
          done

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
          "$@"
        }

        run_repo_command() {
          local repo_path="$1"
          shift

          (
            cd "$repo_path"
            run_command "$@"
          )
        }

        resolve_bootstrap_repo_source() {
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

          printf '%s\n' 'https://github.com/RAGton/ragos-nixos'
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

          printf '%s\n' 'ragos bootstrap requer root ou sudo sem prompt.' >&2
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
            printf '%s\n' "ragos: não encontrei nixos-generate-config para gerar $local_hw_path" >&2
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
            printf '%s\n' "ragos: $repo_host_dir existe, mas não é um diretório" >&2
            return 1
          fi

          if [[ ! -d "$repo_host_dir" ]]; then
            run_privileged install -d -m 0755 "$repo_host_dir"
            bootstrap_host_created=1
          fi

          if [[ -L "$repo_hw" ]]; then
            existing_target="$(readlink "$repo_hw")"
            if [[ "$existing_target" != "$local_hw" ]]; then
              printf '%s\n' "ragos: conflito em $repo_hw: symlink aponta para $existing_target, esperado $local_hw" >&2
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

        bootstrap_ragos_checkout() {
          local host_name="$1"
          local repo_root="/etc/ragos"
          local repo_source

          repo_source="$(resolve_bootstrap_repo_source)"

          if [[ -e "$repo_root/flake.nix" ]]; then
            return 0
          fi

          if [[ -e "$repo_root" && ! -e "$repo_root/flake.nix" ]]; then
            printf '%s\n' "ragos: $repo_root existe, mas não contém flake.nix; não posso bootstrapar sem limpeza manual." >&2
            return 1
          fi

          if [[ -z "$repo_source" ]]; then
            printf '%s\n' 'ragos: não existe repo configurado para bootstrap.' >&2
            return 1
          fi

          if ! run_privileged git clone --origin origin "$repo_source" "$repo_root"; then
            printf '%s\n' "ragos: falha ao clonar $repo_source para $repo_root" >&2
            return 1
          fi

          bootstrap_performed=1
          bootstrap_repo_created=1
          bootstrap_repo_source="$repo_source"
          bootstrap_repo_root="$repo_root"

          ensure_bootstrap_host_layout "$repo_root" "$host_name" || return 1
          return 0
        }

        normalize_flake_ref() {
          local candidate="''${1:-}"

          if [[ "$candidate" == path:* ]]; then
            printf '%s\n' "$candidate"
            return 0
          fi

          if [[ -e "$candidate/flake.nix" ]]; then
            printf 'path:%s\n' "$candidate"
            return 0
          fi

          printf '%s\n' "$candidate"
        }

        ragos_git_repo_path() {
          printf '%s\n' "''${RAGOS_SYSTEM_REPO:-/etc/ragos}"
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

        git_absolute_dir() {
          local repo_path="$1"

          git -C "$repo_path" rev-parse --absolute-git-dir 2>/dev/null || true
        }

        git_has_conflict_state() {
          local repo_path="$1"
          local git_dir

          git_dir="$(git_absolute_dir "$repo_path")"
          [[ -n "$git_dir" ]] || return 1

          [[ -d "$git_dir/rebase-merge" ]] \
            || [[ -d "$git_dir/rebase-apply" ]] \
            || [[ -f "$git_dir/MERGE_HEAD" ]] \
            || [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]
        }

        git_has_tracked_changes() {
          local repo_path="$1"

          ! git -C "$repo_path" diff --quiet --no-ext-diff --cached \
            || ! git -C "$repo_path" diff --quiet --no-ext-diff
        }

        ensure_ragos_git_repo() {
          local repo_path="$1"

          if ! is_git_repo "$repo_path"; then
            printf '%s\n' "ERRO: $repo_path não é um git repo válido." >&2
            return 1
          fi

          if [[ ! -e "$repo_path/flake.nix" ]]; then
            printf '%s\n' "ERRO: $repo_path não contém flake.nix." >&2
            return 1
          fi
        }

        ensure_ragos_git_state() {
          local repo_path="$1"
          local branch
          local origin

          ensure_ragos_git_repo "$repo_path" || return 1

          branch="$(git_current_branch "$repo_path")"
          origin="$(git_origin_url "$repo_path")"

          if [[ -z "$origin" ]]; then
            printf '%s\n' "ERRO: $repo_path não possui remote origin configurado." >&2
            return 1
          fi

          if [[ "$branch" != "main" ]]; then
            printf '%s\n' "ERRO: branch ativa '$branch' inválida; esperado 'main'." >&2
            return 1
          fi

          if git_has_conflict_state "$repo_path"; then
            printf '%s\n' "ERRO: $repo_path já está com merge/rebase em andamento." >&2
            return 1
          fi
        }

        validate_ragos_flake() {
          local repo_path="$1"

          ensure_ragos_git_repo "$repo_path" || return 1
          run_repo_command "$repo_path" nix flake check path:. --keep-going
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

        print_ragos_git_status() {
          local repo_path repo_root branch origin

          repo_path="$(ragos_git_repo_path)"
          blue_line 'RagOS VE git-status'
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

        ragos_pull_repo() {
          local repo_path

          repo_path="$(ragos_git_repo_path)"
          ensure_ragos_git_state "$repo_path" || return 1

          if git_has_tracked_changes "$repo_path"; then
            printf '%s\n' "ERRO: $repo_path possui mudanças locais versionadas; revise com 'ragos git-status' antes de puxar." >&2
            return 1
          fi

          run_repo_command "$repo_path" git fetch origin

          if ! run_repo_command "$repo_path" git pull --rebase origin main; then
            if git_has_conflict_state "$repo_path"; then
              printf '%s\n' "ERRO: conflito detectado em $repo_path durante git pull --rebase." >&2
              printf '%s\n' "Resolva manualmente e use 'git rebase --continue' ou 'git rebase --abort'." >&2
              return 1
            fi

            printf '%s\n' "ERRO: git pull --rebase falhou em $repo_path." >&2
            return 1
          fi

          if git_has_conflict_state "$repo_path"; then
            printf '%s\n' "ERRO: conflito detectado em $repo_path após git pull --rebase." >&2
            return 1
          fi
        }

        ragos_deploy_repo() {
          local repo_path
          local cmd

          repo_path="$(ragos_git_repo_path)"
          ensure_ragos_git_state "$repo_path" || return 1
          validate_ragos_flake "$repo_path" || {
            printf '%s\n' "ERRO: flake inválida em $repo_path; deploy abortado." >&2
            return 1
          }

          cmd=(nh os switch "$repo_path" -H "$flake_host")
          cmd+=("''${verbose_args[@]}" "''${dry_args[@]}" "''${extra_args[@]}")
          run_command "''${cmd[@]}"
        }

        ragos_sync_repo() {
          ragos_pull_repo || return 1
          ragos_deploy_repo
        }

        print_usage() {
          while IFS= read -r line; do
            blue_line "$line"
          done <<'EOF'
    RagOS VE CLI
    Uso:
      ragos <comando> [opcoes] [-- args extras]
    Comandos:
      switch    Aplica o host com nh os switch
      boot      Gera e registra a proxima geracao com nh os boot
      test      Testa a geracao atual com nh os test
      home      Aplica o Home Manager do usuario atual
      update    Atualiza os inputs da flake
      pull      Atualiza /etc/ragos com git fetch + git pull --rebase
      deploy    Valida a flake e aplica /etc/ragos no host atual
      sync      Pull + validação + deploy do checkout /etc/ragos
      clean     Limpa geracoes antigas com nh clean all
      diff      Compara /run/current-system com o proximo toplevel
      repl      Abre nix repl na flake
      doctor    Mostra diagnostico rapido do host e do repositorio
      git-status Mostra branch, origin e mudanças locais de /etc/ragos
      vm        Lista VMs via libvirt
      iso       Builda a ISO publica do RagOS VE
      fmt       Roda o formatter da flake
      check     Roda nix flake check --keep-going
    Opcoes globais:
      --host <host>    Forca o alvo da flake (ex.: glacier)
      --user <user>    Usuario para o comando home
      --flake <path>   Caminho/flake ref a usar
      --update         Atualiza inputs quando suportado
      --verbose        Aumenta verbosidade
      --dry            Dry-run quando suportado
      --help           Mostra esta ajuda
    Exemplos:
      ragos switch
      ragos pull
      ragos deploy
      ragos sync
      ragos switch --update --verbose
      ragos boot --update
      ragos home --user rocha
      ragos diff
      ragos doctor
      ragos git-status
      ragos iso
    EOF
        }

        resolve_flake_context() {
          local explicit="''${1:-}"

          flake_mode=""
          flake_root=""
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
            flake_mode="explicit"
            flake_ref="$(normalize_flake_ref "$explicit")"
          elif [[ -n "''${RAGOS_FLAKE:-}" ]]; then
            flake_mode="env"
            flake_ref="$(normalize_flake_ref "$RAGOS_FLAKE")"
          elif flake_root="$(find_local_flake_root)"; then
            flake_mode="dev-repo"
            flake_ref="path:$flake_root"
          elif [[ -e /etc/ragos/flake.nix ]]; then
            flake_mode="etc-ragos"
            flake_root="/etc/ragos"
            flake_ref="path:/etc/ragos"
            ensure_bootstrap_host_layout "$flake_root" "$flake_host" || return 1
          elif bootstrap_ragos_checkout "$flake_host"; then
            flake_mode="bootstrap"
            flake_root="/etc/ragos"
            flake_ref="path:/etc/ragos"
          else
            printf '%s\n' 'ragos: não foi possível resolver uma flake.' >&2
            printf '%s\n' 'Use um destes caminhos:' >&2
            printf '%s\n' '- ragos <comando> --flake path:/caminho/para/o/repo' >&2
            printf '%s\n' '- exporte RAGOS_FLAKE com uma flake válida' >&2
            printf '%s\n' '- execute o comando dentro do checkout do projeto' >&2
            printf '%s\n' '- garanta que /etc/ragos/flake.nix exista na máquina instalada' >&2
            return 1
          fi

          if [[ -z "$flake_root" ]]; then
            case "$flake_ref" in
              path:*)
                flake_root="''${flake_ref#path:}"
                ;;
              /*|./*|../*|.|..)
                flake_root="$flake_ref"
                ;;
            esac
          fi
        }

        print_flake_resolution() {
          if (( verbose > 0 )); then
            blue_line 'RagOS VE CLI'
            blue_line "  host atual      : $(current_hostname)"
            blue_line "  modo detectado   : $flake_mode"
            blue_line "  flake resolvida  : $flake_ref"
            if [[ -n "$flake_root" ]]; then
              blue_line "  flake raiz       : $flake_root"
            fi
            blue_line "  flake host       : $flake_host"
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

        subcommand="''${1:-help}"
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
            --verbose|-v)
              verbose=$((verbose + 1))
              ;;
            --dry|-n)
              dry=1
              ;;
            --host|-H)
              host_arg="$2"
              shift
              ;;
            --user)
              user_arg="$2"
              shift
              ;;
            --flake)
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
              extra_args+=("$1")
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

          clean|vm|git-status|pull|deploy|sync)
            needs_flake=0
            ;;

          *)
            needs_flake=1
            ;;
        esac

        if (( needs_flake )); then
          resolve_flake_context "$flake_arg"
        else
          flake_mode="none"
          flake_root=""
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
            cmd=(nh os "$subcommand" "$flake_ref" -H "$flake_host")
            if (( update )); then
              cmd+=("--update")
            fi
            cmd+=("''${verbose_args[@]}" "''${dry_args[@]}" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          home)
            cmd=(nh home switch "$flake_ref" -c "$home_target")
            if (( update )); then
              cmd+=("--update")
            fi
            cmd+=("''${verbose_args[@]}" "''${dry_args[@]}" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          update)
            cmd=(nix flake update --flake "$flake_ref" "''${verbose_args[@]}" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          pull)
            ragos_pull_repo
            ;;

          deploy)
            ragos_deploy_repo
            ;;

          sync)
            ragos_sync_repo
            ;;

          clean)
            cmd=(nh clean all "''${verbose_args[@]}" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          diff)
            target_path="$(nix build --no-link --print-out-paths "''${flake_ref}#nixosConfigurations.''${flake_host}.config.system.build.toplevel" "''${extra_args[@]}")"
            run_command nvd diff /run/current-system "$target_path"
            ;;

          repl)
            cmd=(nix repl "$flake_ref" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          doctor)
            blue_line 'RagOS VE doctor'
            blue_line "  host atual   : $(current_hostname)"
            blue_line "  modo detectado: $flake_mode"
            blue_line "  flake resolvida: $flake_ref"
            blue_line "  flake host   : $flake_host"
            blue_line "  home target  : $home_target"
            blue_line "  flake root   : $flake_root"
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

            if drv_path="$(nix eval "''${flake_ref}#nixosConfigurations.''${flake_host}.config.system.build.toplevel.drvPath" --raw 2>/dev/null)"; then
              blue_line "  toplevel drv : $drv_path"
            else
              blue_line '  toplevel drv : falhou na avaliacao'
            fi
            ;;

          git-status)
            print_ragos_git_status
            ;;

          vm)
            run_command virsh list --all
            ;;

          iso)
            cmd=(nix build "''${flake_ref}#nixosConfigurations.iso.config.system.build.isoImage" "''${verbose_args[@]}" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          fmt)
            cmd=(nix fmt "$flake_ref" "''${verbose_args[@]}" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          check)
            cmd=(nix flake check "$flake_ref" --keep-going "''${verbose_args[@]}" "''${extra_args[@]}")
            run_command "''${cmd[@]}"
            ;;

          *)
            printf 'Comando desconhecido: %s\n\n' "$subcommand" >&2
            print_usage >&2
            exit 1
            ;;
        esac
  '';
}

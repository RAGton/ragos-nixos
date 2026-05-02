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
  uv,
  stdenv,
  zlib,
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
    uv
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
                nixos)
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
              [[ -e "$repo_root/packages/kryonix-cli.nix" ]] || return 1
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

              printf '%s\n' "/etc/kryonix"
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

            git_has_conflict_state() {
              local repo_path="$1"
              local git_dir

              git_dir="$(git -C "$repo_path" rev-parse --absolute-git-dir 2>/dev/null || true)"
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

            ensure_kryonix_git_state() {
              local repo_path="$1"
              local branch
              local origin

              if ! is_git_repo "$repo_path"; then
                printf '%s\n' "ERRO: $repo_path não é um git repo válido." >&2
                return 1
              fi

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

            kryonix_pull_repo() {
              local repo_path
              repo_path="$(kryonix_git_repo_path)"

              ensure_kryonix_git_state "$repo_path" || return 1

              if git_has_tracked_changes "$repo_path"; then
                printf '%s\n' "ERRO: $repo_path possui mudanças locais versionadas; revise com 'kryonix git-status' antes de puxar." >&2
                return 1
              fi

              run_command git -C "$repo_path" fetch origin
              if ! run_command git -C "$repo_path" pull --rebase origin main; then
                 printf '%s\n' "ERRO: git pull --rebase falhou em $repo_path." >&2
                 return 1
              fi

              run_command git -C "$repo_path" submodule update --init --recursive
            }

            kryonix_deploy_repo() {
              local repo_path
              repo_path="$(kryonix_git_repo_path)"

              ensure_kryonix_git_state "$repo_path" || return 1

              # Validação antes do deploy
              run_command nix flake check "$repo_path" --keep-going || {
                printf '%s\n' "ERRO: falha na validação da flake em $repo_path." >&2
                return 1
              }

              cmd=(nh os switch "$repo_path" -H "$flake_host")
              cmd+=("''${verbose_args[@]}" "''${dry_args[@]}" "''${extra_args[@]}")
              run_command "''${cmd[@]}"
            }

            kryonix_sync_repo() {
              kryonix_pull_repo || return 1
              kryonix_deploy_repo
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

            kryonix_repo_root() {
              local git_root

              if [[ -n "$flake_workdir" ]]; then
                printf '%s\n' "$flake_workdir"
                return 0
              fi

              if git_root="$(find_git_root)" && is_kryonix_checkout "$git_root"; then
                printf '%s\n' "$git_root"
                return 0
              fi

              if is_kryonix_checkout /etc/kryonix; then
                printf '%s\n' /etc/kryonix
                return 0
              fi

              printf '%s\n' "kryonix: não encontrei checkout Kryonix com packages/kryonix-brain-lightrag." >&2
              return 1
            }

            brain_project_dir() {
              local repo_root project_dir

              repo_root="$(kryonix_repo_root)" || return 1
              project_dir="$repo_root/packages/kryonix-brain-lightrag"

              if [[ ! -f "$project_dir/pyproject.toml" ]]; then
                printf '%s\n' "kryonix: Brain não encontrado em $project_dir." >&2
                return 1
              fi

              printf '%s\n' "$project_dir"
            }

            run_brain_cli() {
              local project_dir

              project_dir="$(brain_project_dir)" || return 1
              if [[ -f "/etc/kryonix/brain.env" ]]; then
                set -a
                # shellcheck disable=SC1091
                source "/etc/kryonix/brain.env"
                set +a
              fi
              export KRYONIX_BRAIN_HOME="/home/rocha/.local/share/kryonix/kryonix-vault"
              export LIGHTRAG_VAULT_DIR="/home/rocha/.local/share/kryonix/kryonix-vault/vault"
              export LIGHTRAG_WORKING_DIR="/home/rocha/.local/share/kryonix/kryonix-vault/storage"
              export LD_LIBRARY_PATH="${stdenv.cc.cc.lib}/lib:${zlib}/lib:''${LD_LIBRARY_PATH:-}"
              run_command uv run --project "$project_dir" python -m kryonix_brain_lightrag.cli "$@"
            }

            run_brain_module() {
              local module="$1"
              local project_dir
              shift

              project_dir="$(brain_project_dir)" || return 1
              if [[ -f "/etc/kryonix/brain.env" ]]; then
                set -a
                # shellcheck disable=SC1091
                source "/etc/kryonix/brain.env"
                set +a
              fi
              export KRYONIX_BRAIN_HOME="/home/rocha/.local/share/kryonix/kryonix-vault"
              export LIGHTRAG_VAULT_DIR="/home/rocha/.local/share/kryonix/kryonix-vault/vault"
              export LIGHTRAG_WORKING_DIR="/home/rocha/.local/share/kryonix/kryonix-vault/storage"
              export LD_LIBRARY_PATH="${stdenv.cc.cc.lib}/lib:${zlib}/lib:''${LD_LIBRARY_PATH:-}"
              run_command uv run --project "$project_dir" python -m "$module" "$@"
            }

            kryonix_brain_role() {
              local explicit lower

              explicit="''${KRYONIX_BRAIN_ROLE:-}"
              lower="$(printf '%s' "$explicit" | tr '[:upper:]' '[:lower:]')"
              case "$lower" in
                client|server)
                  printf '%s\n' "$lower"
                  return 0
                  ;;
              esac

              case "$(map_runtime_host)" in
                glacier)
                  printf '%s\n' "server"
                  ;;
                *)
                  printf '%s\n' "client"
                  ;;
              esac
            }

            brain_api_url() {
              local url

              url="''${KRYONIX_BRAIN_API:-''${KRYONIX_BRAIN_URL:-}}"
              printf '%s\n' "''${url%/}"
            }

            brain_remote_required() {
              if [[ -z "$(brain_api_url)" ]]; then
                printf '%s\n' "Brain remoto não configurado. Defina KRYONIX_BRAIN_API." >&2
                return 2
              fi
            }

            brain_should_use_remote() {
              local mode="$1"

              case "$mode" in
                remote)
                  return 0
                  ;;
                local)
                  return 1
                  ;;
              esac

              [[ -n "$(brain_api_url)" ]] && return 0
              [[ "$(kryonix_brain_role)" == "client" ]]
            }

            brain_remote_curl() {
              local method="$1"
              local path="$2"
              local data="''${3:-}"
              local url
              local status
              local -a curl_args

              brain_remote_required || return $?
              url="$(brain_api_url)"
              curl_args=(-fsS --connect-timeout 3 --max-time 20 -X "$method" -H "Accept: application/json")

              if [[ -n "''${KRYONIX_BRAIN_KEY:-}" ]]; then
                curl_args+=(-H "X-API-Key: ''${KRYONIX_BRAIN_KEY}")
              fi

              if [[ -n "$data" ]]; then
                curl_args+=(-H "Content-Type: application/json" --data "$data")
              fi

              blue_line "Brain remoto: $method $url$path"
              if curl "''${curl_args[@]}" "$url$path"; then
                status=0
              else
                status=$?
              fi
              printf '\n'
              return "$status"
            }

            parse_brain_mode() {
              brain_mode="auto"
              brain_passthrough=()

              while [[ $# -gt 0 ]]; do
                case "$1" in
                  --local)
                    brain_mode="local"
                    ;;
                  --remote)
                    brain_mode="remote"
                    ;;
                  *)
                    brain_passthrough+=("$1")
                    ;;
                esac
                shift
              done
            }

            kryonix_brain_health() {
              parse_brain_mode "$@"
              if brain_should_use_remote "$brain_mode"; then
                brain_remote_curl GET /health
                return $?
              fi

              local project_dir
              project_dir="$(brain_project_dir)" || return 1
              if [[ -f "/etc/kryonix/brain.env" ]]; then
                set -a
                # shellcheck disable=SC1091
                source "/etc/kryonix/brain.env"
                set +a
              fi
              export KRYONIX_BRAIN_HOME="/home/rocha/.local/share/kryonix/kryonix-vault"
              export LIGHTRAG_VAULT_DIR="/home/rocha/.local/share/kryonix/kryonix-vault/vault"
              export LIGHTRAG_WORKING_DIR="/home/rocha/.local/share/kryonix/kryonix-vault/storage"
              export LD_LIBRARY_PATH="${stdenv.cc.cc.lib}/lib:${zlib}/lib:''${LD_LIBRARY_PATH:-}"
              run_command uv run --project "$project_dir" python -c '
    from kryonix_brain_lightrag import config
    print("Kryonix Brain health")
    print(f"project_dir: {config.PROJECT_DIR}")
    print(f"vault_dir: {config.VAULT_DIR}")
    print(f"working_dir: {config.WORKING_DIR}")
    print("status: OK")
    '
            }

            kryonix_brain_doctor() {
              parse_brain_mode "$@"
              if brain_should_use_remote "$brain_mode"; then
                brain_remote_required || return $?
                if ! brain_remote_curl GET /health; then
                  blue_line "WARN: Brain remoto indisponível; runtime depende do Glacier."
                  return 0
                fi
                if ! brain_remote_curl GET /stats; then
                  blue_line "WARN: Brain remoto respondeu health, mas stats falhou; runtime depende do Glacier."
                  return 0
                fi
                return 0
              fi

              run_brain_cli doctor "''${brain_passthrough[@]}"
            }

            kryonix_brain_stats() {
              parse_brain_mode "$@"
              if brain_should_use_remote "$brain_mode"; then
                brain_remote_curl GET /stats
                return $?
              fi

              run_brain_cli stats "''${brain_passthrough[@]}"
            }

            kryonix_brain_search() {
              local action="$1"
              local query
              local payload

              shift
              parse_brain_mode "$@"
              if brain_should_use_remote "$brain_mode"; then
                if [[ "''${#brain_passthrough[@]}" -eq 0 ]]; then
                  printf 'Uso: kryonix brain %s "pergunta"\n' "$action" >&2
                  return 2
                fi
                query="''${brain_passthrough[*]}"
                payload="$(jq -n --arg query "$query" --arg mode "hybrid" --arg lang "pt-BR" '{query:$query, mode:$mode, lang:$lang}')"
                brain_remote_curl POST /search "$payload"
                return $?
              fi

              run_brain_cli "$action" "''${brain_passthrough[@]}"
            }

            kryonix_graph_stats() {
              parse_brain_mode "$@"
              if brain_should_use_remote "$brain_mode"; then
                if [[ -z "$(brain_api_url)" ]]; then
                  blue_line "WARN: Graph local existe no Glacier. Defina KRYONIX_BRAIN_API ou rode kryonix graph stats --local no servidor."
                  return 0
                fi
                if ! brain_remote_curl GET /stats; then
                  blue_line "WARN: Graph remoto indisponível; runtime depende do Glacier."
                fi
                return 0
              fi

              run_brain_cli stats "''${brain_passthrough[@]}"
            }

            kryonix_graph_top() {
              parse_brain_mode "$@"
              if brain_should_use_remote "$brain_mode"; then
                blue_line "WARN: graph top remoto ainda não possui endpoint público; rode no Glacier com kryonix graph top --local --limit 10."
                return 0
              fi

              graph_limit="$(graph_top_args "''${brain_passthrough[@]}")"
              run_brain_cli top "$graph_limit"
            }

            kryonix_graph_server_only() {
              local action="$1"
              shift

              parse_brain_mode "$@"
              if brain_should_use_remote "$brain_mode"; then
                printf '%s\n' "kryonix graph $action é operação local do Glacier. Use --local no servidor." >&2
                return 2
              fi

              case "$action" in
                heal)
                  run_brain_cli graph heal "''${brain_passthrough[@]}"
                  ;;
                repair)
                  run_brain_cli repair-graph "''${brain_passthrough[@]}"
                  ;;
              esac
            }

            mcp_config_file() {
              local repo_root

              repo_root="$(kryonix_repo_root)" || return 1
              if [[ -f "$repo_root/.mcp.json" ]]; then
                printf '%s\n' "$repo_root/.mcp.json"
              elif [[ -f "$repo_root/.mcp.example.json" ]]; then
                printf '%s\n' "$repo_root/.mcp.example.json"
              else
                printf '%s\n' "kryonix: .mcp.json ou .mcp.example.json não encontrado em $repo_root." >&2
                return 1
              fi
            }

            print_mcp_config() {
              local config_file

              config_file="$(mcp_config_file)" || return 1
              if [[ "$(basename "$config_file")" == ".mcp.example.json" ]]; then
                blue_line "Usando .mcp.example.json; copie para .mcp.json para configurar a instância local."
              fi

              jq '
                def mask:
                  if type == "object" then
                    with_entries(
                      if (.key | test("(?i)(token|key|secret|password)")) then
                        .value = "<redacted>"
                      else
                        .value |= mask
                      end
                    )
                  elif type == "array" then
                    map(mask)
                  else
                    .
                  end;
                .mcpServers | mask
              ' "$config_file"
            }

            kryonix_mcp_check() {
              run_brain_cli mcp-check "$@"
            }

            kryonix_mcp_doctor() {
              local repo_root

              repo_root="$(kryonix_repo_root)" || return 1
              kryonix_mcp_check "$@"
              if [[ -x "$repo_root/scripts/check-mcp.sh" ]]; then
                (
                  cd "$repo_root"
                  KRYONIX_BIN="$0" bash scripts/check-mcp.sh
                )
              else
                printf '%s\n' "kryonix: scripts/check-mcp.sh não encontrado ou não executável." >&2
                return 1
              fi
            }

            graph_top_args() {
              local limit="10"
              local parsed=()

              while [[ $# -gt 0 ]]; do
                case "$1" in
                  --limit)
                    if [[ $# -lt 2 ]]; then
                      printf '%s\n' "kryonix graph top: --limit requer valor." >&2
                      return 2
                    fi
                    limit="$2"
                    shift
                    ;;
                  --limit=*)
                    limit="''${1#--limit=}"
                    ;;
                  *)
                    parsed+=("$1")
                    ;;
                esac
                shift
              done

              if [[ "''${#parsed[@]}" -gt 0 && "''${parsed[0]}" =~ ^[0-9]+$ ]]; then
                limit="''${parsed[0]}"
              fi

              printf '%s\n' "$limit"
            }

            is_kryonix_test_target() {
              case "''${1:-}" in
                all|code|client|server|runtime|brain|mcp|graph)
                  return 0
                  ;;
              esac

              return 1
            }

            run_kryonix_test_target() {
              local target="''${1:-all}"
              local repo_root

              case "$target" in
                all)
                  run_brain_cli test all
                  repo_root="$(kryonix_repo_root)" || return 1
                  run_command nix flake check "path:$repo_root" --keep-going
                  ;;
                code)
                  run_brain_cli test code
                  repo_root="$(kryonix_repo_root)" || return 1
                  run_command nix flake check "path:$repo_root" --keep-going
                  ;;
                client)
                  run_brain_cli test client
                  ;;
                server)
                  run_brain_cli test server
                  ;;
                runtime)
                  run_brain_cli test runtime
                  ;;
                brain)
                  run_brain_cli test brain
                  ;;
                mcp)
                  kryonix_mcp_check
                  repo_root="$(kryonix_repo_root)" || return 1
                  (
                    cd "$repo_root"
                    KRYONIX_BIN="$0" bash scripts/check-mcp.sh
                  )
                  ;;
                graph)
                  run_brain_cli test graph
                  ;;
                *)
                  printf 'Uso: kryonix test <all|code|client|server|runtime|brain|mcp|graph>\n' >&2
                  return 2
                  ;;
              esac
            }

            print_usage() {
              local usage_lines=(
                "Kryonix CLI"
                "Uso:"
                "  kryonix <comando> [opcoes] [-- args extras]"
                "Comandos:"
                "  switch    Aplica o host com nh os switch"
                "  boot      Gera e registra a proxima geracao com nh os boot"
                "  test      Testa a geracao NixOS ou os perfis code/client/server/MCP"
                "  home      Aplica o Home Manager do usuario atual"
                "  update    Atualiza os inputs da flake"
                "  pull      Atualiza /etc/kryonix com git fetch + git pull --rebase"
                "  deploy    Valida a flake e aplica /etc/kryonix no host atual"
                "  sync      Pull + validacao + deploy do checkout /etc/kryonix"
                "  rebuild   Builda o toplevel do host sem ativar"
                "  clean     Limpa geracoes antigas com nh clean all"
                "  diff      Compara /run/current-system com o proximo toplevel"
                "  repl      Abre nix repl na flake"
                "  doctor    Mostra diagnostico rapido do host e do repositorio"
                "  git-status Mostra branch, origin e mudancas locais de /etc/kryonix"
                "  vm        Lista VMs via libvirt"
                "  iso       Builda a ISO publica do Kryonix"
                "  fmt       Roda o formatter da flake"
                "  check     Roda nix flake check --keep-going"
                "  brain     Acessa o Kryonix Brain local ou remoto (health, doctor, stats, search, ask)"
                "  graph     Opera o grafo do Brain (stats, top, heal, repair)"
                "  mcp       Valida e imprime a configuracao MCP"
                "  vault     Opera o vault via Brain (scan, index)"
                "  ollama    Controla o serviço Ollama (start, stop, status, run, vram, pull)"
                "  ai        Interage com a camada de IA (continue, status, checkpoint)"
                "Opcoes globais:"
                "  --host <host>    Forca o alvo da flake (ex.: glacier)"
                "  --user <user>    Usuario para o comando home"
                "  --flake <path>   Caminho ou flake ref a usar"
                "  --update         Atualiza inputs quando suportado"
                "  --no-update      Usa o flake.lock atual"
                "  --verbose        Aumenta verbosidade"
                "  --dry            Dry-run quando suportado"
                "  --help           Mostra esta ajuda"
                "Exemplos:"
                "  kryonix switch"
                "  kryonix switch inspiron"
                "  kryonix switch --update --verbose"
                "  kryonix boot --update"
                "  kryonix home --user rocha"
                "  kryonix rebuild"
                "  kryonix diff"
                "  kryonix doctor"
                "  kryonix git-status"
                "  kryonix brain stats"
                "  kryonix brain doctor --remote"
                "  kryonix brain doctor --local"
                "  kryonix brain search \"Como funciona o pipeline RAG do Kryonix?\""
                "  kryonix graph top --limit 10"
                "  kryonix mcp check"
                "  kryonix test all"
                "  kryonix test client"
                "  kryonix test server"
                "  kryonix iso"
              )
              local line

              for line in "''${usage_lines[@]}"; do
                blue_line "$line"
              done
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
              elif local_root="$(find_local_flake_root)"; then
                use_local_flake "dev-repo" "$local_root"
              elif [[ -e /etc/kryonix/flake.nix ]]; then
                use_local_flake "etc-kryonix" "/etc/kryonix"
              else
                printf '%s\n' 'kryonix: não foi possível resolver uma flake.' >&2
                printf '%s\n' 'Use um destes caminhos:' >&2
                printf '%s\n' '- kryonix <comando> --flake /caminho/para/o/repo' >&2
                printf '%s\n' '- exporte KRYONIX_FLAKE com uma flake válida' >&2
                printf '%s\n' '- execute o comando dentro do checkout Git do projeto' >&2
                printf '%s\n' '- garanta que /etc/kryonix/flake.nix exista na máquina instalada' >&2
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

            kryonix_doctor_full() {
              local repo_path
              repo_path="$(kryonix_git_repo_path)"
              local has_error=0

              blue_line "======================================"
              blue_line "    KRYONIX DOCTOR FULL"
              blue_line "======================================"

              blue_line ""
              blue_line "--- [1] doctor docs ---"
              if [[ -x "$repo_path/scripts/doc-audit.sh" ]]; then
                if ! "$repo_path/scripts/doc-audit.sh"; then
                  has_error=1
                fi
              else
                blue_line "ERRO: scripts/doc-audit.sh não encontrado."
                has_error=1
              fi

              blue_line ""
              blue_line "--- [2] doctor system ---"
              blue_line "  host atual   : $(current_hostname)"
              blue_line "  modo detectado: $flake_mode"
              blue_line "  flake resolvida: $flake_ref"
              
              if command -v systemctl >/dev/null 2>&1; then
                blue_line "  libvirtd     : $(systemctl is-enabled libvirtd 2>/dev/null || printf 'unknown')"
                blue_line "  tailscaled   : $(systemctl is-active tailscaled 2>/dev/null || printf 'inactive')"
              fi

              if ss -ltnp 2>/dev/null | grep -q 11434; then
                  blue_line "  ollama       : ativo"
              else
                  blue_line "  ollama       : inativo"
              fi

              blue_line ""
              blue_line "--- [3] doctor architecture ---"
              for doc in ARCHITECTURE.md ROADMAP.md USAGE.md TESTING.md; do
                if [[ -f "$repo_path/docs/$doc" ]]; then
                  blue_line "  ✓ docs/$doc encontrado."
                else
                  blue_line "  ERRO: docs/$doc ausente."
                  has_error=1
                fi
              done

              blue_line ""
              blue_line "--- [4] doctor brain ---"
              brain_url="$(brain_api_url)"
              if [[ -n "$brain_url" ]]; then
                blue_line "  brain url    : $brain_url"
                if curl -s --connect-timeout 2 "$brain_url/health" >/dev/null; then
                  blue_line '  brain health : OK'
                else
                  blue_line '  brain health : FAIL'
                fi
              elif [[ "$(kryonix_brain_role)" == "client" ]]; then
                blue_line '  brain remoto : WARN: KRYONIX_BRAIN_API ausente'
              else
                blue_line '  brain remoto : inativo (server)'
              fi

              blue_line ""
              blue_line "--- [5] doctor summary ---"
              if [[ "$has_error" -eq 1 ]]; then
                blue_line "ERRO CRÍTICO: kryonix doctor full encontrou falhas."
                return 1
              else
                blue_line "✓ kryonix doctor full concluído sem erros críticos."
                return 0
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
                  if [[ "$subcommand" == "test" ]] && is_kryonix_test_target "$1"; then
                    extra_args+=("$1")
                  elif accepts_positional_host && [[ -z "$host_arg" && "$1" != -* ]]; then
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

              clean|vm|git-status|pull|deploy|sync|brain|graph|mcp|vault)
                needs_flake=0
                ;;

              test)
                if is_kryonix_test_target "''${extra_args[0]:-}"; then
                  needs_flake=0
                else
                  needs_flake=1
                fi
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
              switch|boot)
                update_flake_if_requested
                cmd=(nh os "$subcommand" "$flake_ref" -H "$flake_host")
                cmd+=("''${verbose_args[@]}" "''${dry_args[@]}")
                if [[ "''${#extra_args[@]}" -gt 0 ]]; then
                  cmd+=("--" "''${extra_args[@]}")
                fi
                run_flake_command "''${cmd[@]}"
                ;;

              test)
                if is_kryonix_test_target "''${extra_args[0]:-}"; then
                  run_kryonix_test_target "''${extra_args[0]}"
                else
                  update_flake_if_requested
                  cmd=(nh os test "$flake_ref" -H "$flake_host")
                  cmd+=("''${verbose_args[@]}" "''${dry_args[@]}")
                  if [[ "''${#extra_args[@]}" -gt 0 ]]; then
                    cmd+=("--" "''${extra_args[@]}")
                  fi
                  run_flake_command "''${cmd[@]}"
                fi
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

              pull)
                kryonix_pull_repo
                ;;

              deploy)
                kryonix_deploy_repo
                ;;

              sync)
                kryonix_sync_repo
                ;;

              repl)
                cmd=(nix repl "$flake_ref" "''${extra_args[@]}")
                run_flake_command "''${cmd[@]}"
                ;;

              doctor)
                if [[ "''${extra_args[0]:-}" == "full" ]]; then
                  kryonix_doctor_full
                  exit $?
                fi

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
                fi

                if command -v systemctl >/dev/null 2>&1; then
                  blue_line "  libvirtd     : $(systemctl is-enabled libvirtd 2>/dev/null || printf 'unknown')"
                  blue_line "  tailscaled   : $(systemctl is-active tailscaled 2>/dev/null || printf 'inactive')"
                fi

                brain_url="$(brain_api_url)"
                if [[ -n "$brain_url" ]]; then
                  blue_line "  brain url    : $brain_url"
                  if curl -s --connect-timeout 2 "$brain_url/health" >/dev/null; then
                    blue_line '  brain health : OK'
                  else
                    blue_line '  brain health : FAIL'
                  fi
                elif [[ "$(kryonix_brain_role)" == "client" ]]; then
                  blue_line '  brain remoto : WARN: KRYONIX_BRAIN_API ausente'
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
                if [[ ''${#extra_args[@]} -eq 0 ]]; then
                  brain_sub="help"
                else
                  brain_sub="''${extra_args[0]}"
                  extra_args=("''${extra_args[@]:1}")
                fi

                case "$brain_sub" in
                  health)
                    kryonix_brain_health "''${extra_args[@]}"
                    ;;
                  doctor)
                    kryonix_brain_doctor "''${extra_args[@]}"
                    ;;
                  stats)
                    kryonix_brain_stats "''${extra_args[@]}"
                    ;;
                  search|ask)
                    if [[ ''${#extra_args[@]} -eq 0 ]]; then
                      printf 'Uso: kryonix brain %s "pergunta"\n' "$brain_sub" >&2
                      exit 2
                    fi
                    kryonix_brain_search "$brain_sub" "''${extra_args[@]}"
                    ;;
                  storage-check|ollama-check)
                    run_brain_cli "$brain_sub" "''${extra_args[@]}"
                    ;;
                  sync|watch|diagnostics|index|export)
                    run_brain_cli "$brain_sub" "''${extra_args[@]}"
                    ;;
                  api)
                    run_brain_module kryonix_brain_lightrag.api "''${extra_args[@]}"
                    ;;
                   *)
                     echo "Uso: kryonix brain <health|doctor [--remote|--local]|stats [--remote|--local]|search|ask|storage-check|ollama-check|sync|watch|index|export|diagnostics|api>"
                     exit 1
                     ;;
                esac
                ;;

              graph)
                if [[ ''${#extra_args[@]} -eq 0 ]]; then
                  graph_sub="help"
                else
                  graph_sub="''${extra_args[0]}"
                  extra_args=("''${extra_args[@]:1}")
                fi

                case "$graph_sub" in
                  stats)
                    kryonix_graph_stats "''${extra_args[@]}"
                    ;;
                  top)
                    kryonix_graph_top "''${extra_args[@]}"
                    ;;
                  heal)
                    kryonix_graph_server_only heal "''${extra_args[@]}"
                    ;;
                  repair)
                    kryonix_graph_server_only repair "''${extra_args[@]}"
                    ;;
                  *)
                    printf 'Uso: kryonix graph <stats|top|heal|repair> [--remote|--local]\n' >&2
                    exit 1
                    ;;
                esac
                ;;

              mcp)
                if [[ ''${#extra_args[@]} -eq 0 ]]; then
                  mcp_sub="print-config"
                else
                  mcp_sub="''${extra_args[0]}"
                  extra_args=("''${extra_args[@]:1}")
                fi

                case "$mcp_sub" in
                  check)
                    kryonix_mcp_check "''${extra_args[@]}"
                    ;;
                  doctor)
                    kryonix_mcp_doctor "''${extra_args[@]}"
                    ;;
                  print-config)
                    print_mcp_config
                    ;;
                  *)
                    printf 'Usage: kryonix mcp <check|doctor|print-config>\n' >&2
                    exit 1
                    ;;
                esac
                ;;

              vault)
                if [[ ''${#extra_args[@]} -eq 0 ]]; then
                  printf 'Uso: kryonix vault <scan|index>\n' >&2
                  exit 1
                fi
                run_brain_cli vault "''${extra_args[@]}"
                ;;

              ollama)
                if [[ ''${#extra_args[@]} -eq 0 ]]; then
                  printf 'Uso: kryonix ollama <start|stop|status|run|vram|pull>\n' >&2
                  exit 1
                fi
                ollama_sub="''${extra_args[0]}"
                extra_args=("''${extra_args[@]:1}")

                case "$ollama_sub" in
                  start)
                    printf '🚀 Iniciando Ollama...\n'
                    sudo systemctl start ollama
                    # Polling até porta 11434 responder (max 30s)
                    for _i in $(seq 1 30); do
                      if curl -s -o /dev/null -w "" http://127.0.0.1:11434/ 2>/dev/null; then
                        printf '✅ Ollama ativo na porta 11434\n'
                        # Mostrar VRAM
                        if command -v nvidia-smi &>/dev/null; then
                          nvidia-smi --query-gpu=memory.used,memory.free,memory.total --format=csv,noheader
                        fi
                        exit 0
                      fi
                      sleep 1
                    done
                    printf '⚠️  Ollama não respondeu em 30s. Verifique: journalctl -u ollama --no-pager -n 20\n' >&2
                    exit 1
                    ;;
                  stop)
                    printf '🛑 Parando Ollama...\n'
                    sudo systemctl stop ollama
                    printf '✅ Ollama parado.\n'
                    if command -v nvidia-smi &>/dev/null; then
                      printf 'VRAM livre: '
                      nvidia-smi --query-gpu=memory.free --format=csv,noheader
                    fi
                    ;;
                  status)
                    systemctl status ollama --no-pager 2>/dev/null || printf 'Ollama não está rodando.\n'
                    if command -v nvidia-smi &>/dev/null; then
                      printf '\n── GPU VRAM ──\n'
                      nvidia-smi --query-gpu=memory.used,memory.free,memory.total --format=csv,noheader
                    fi
                    ;;
                  run)
                    model="''${extra_args[0]:-qwen2.5-coder:7b}"
                    # Garante que Ollama está rodando
                    if ! curl -s -o /dev/null http://127.0.0.1:11434/ 2>/dev/null; then
                      printf '🚀 Ollama não está ativo. Iniciando...\n'
                      sudo systemctl start ollama
                      sleep 3
                    fi
                    exec ollama run "$model"
                    ;;
                  vram)
                    if command -v nvidia-smi &>/dev/null; then
                      nvidia-smi --query-gpu=name,memory.used,memory.free,memory.total,temperature.gpu --format=csv,noheader
                    else
                      printf 'nvidia-smi não encontrado.\n' >&2
                      exit 1
                    fi
                    ;;
                  pull)
                    model="''${extra_args[0]:-qwen2.5-coder:7b}"
                    # Garante que Ollama está rodando para pull
                    if ! curl -s -o /dev/null http://127.0.0.1:11434/ 2>/dev/null; then
                      printf '🚀 Ollama não está ativo. Iniciando para pull...\n'
                      sudo systemctl start ollama
                      sleep 3
                    fi
                    ollama pull "$model"
                    ;;
                  *)
                    printf 'Uso: kryonix ollama <start|stop|status|run|vram|pull> [model]\n' >&2
                    exit 1
                    ;;
                esac
                ;;

              ai)
                if [[ ''${#extra_args[@]} -eq 0 ]]; then
                  printf 'Uso: kryonix ai <continue|status|checkpoint>\n' >&2
                  exit 1
                fi
                ai_sub="''${extra_args[0]}"
                extra_args=("''${extra_args[@]:1}")

                state_file="$(kryonix_repo_root)/.ai/STATE.md"
                ai_dir="$(dirname "$state_file")"

                ensure_state_file() {
                  if [[ ! -d "$ai_dir" ]]; then
                    mkdir -p "$ai_dir"
                  fi
                  if [[ ! -f "$state_file" ]]; then
                    printf "Criando arquivo de estado em %s\n" "$state_file"
                    cat <<EOF > "$state_file"
# Kryonix AI State

- **Objetivo atual**: 
- **Último passo concluído**: 
- **Próximos passos**: 
- **Serviços verificados**: 
- **Testes executados**: 
- **Erros pendentes**: 
- **Timestamp da última execução**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
                  fi
                }

                case "$ai_sub" in
                  continue)
                    ensure_state_file
                    # Atualiza o timestamp para a execução atual
                    sed -i "s/^- \*\*Timestamp da última execução\*\*: .*/- \*\*Timestamp da última execução\*\*: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$state_file"
                    cat "$state_file"
                    ;;
                  status)
                    if [[ ! -f "$state_file" ]]; then
                      printf "Nenhum estado ativo. Rode 'kryonix ai continue' para iniciar.\n" >&2
                      exit 1
                    fi
                    printf "=== Estado Atual da IA ===\n"
                    cat "$state_file"
                    ;;
                  checkpoint)
                    ensure_state_file
                    msg="''${extra_args[*]:-Checkpoint manual}"
                    checkpoint_file="$ai_dir/CHECKPOINTS.md"
                    
                    if [[ ! -f "$checkpoint_file" ]]; then
                      cat <<EOF > "$checkpoint_file"
# Kryonix AI Checkpoints
EOF
                    fi
                    
                    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                    printf "\n## [%s] Checkpoint\n\n%s\n" "$timestamp" "$msg" >> "$checkpoint_file"
                    
                    # Tenta atualizar o último passo no STATE.md se existir
                    sed -i "s/^- \*\*Último passo concluído\*\*: .*/- \*\*Último passo concluído\*\*: $msg ($timestamp)/" "$state_file"
                    
                    printf "✅ Checkpoint registrado: %s\n" "$msg"
                    ;;
                  *)
                    printf 'Uso: kryonix ai <continue|status|checkpoint>\n' >&2
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

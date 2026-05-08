current_hostname() {
  cat /proc/sys/kernel/hostname
}

init_colors() {
  reset=""
  bold=""
  dim=""
  blue=""
  magenta=""
  cyan=""
  green=""
  yellow=""
  red=""

  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    reset=$'\033[0m'
    bold=$'\033[1m'
    dim=$'\033[2m'
    blue=$'\033[34m'
    magenta=$'\033[35m'
    cyan=$'\033[36m'
    green=$'\033[32m'
    yellow=$'\033[33m'
    red=$'\033[31m'
  fi
}

kryonix_banner() {
  if [[ "${json_mode:-0}" -eq 1 ]]; then return 0; fi
  printf '%b' "$magenta$bold"
  cat <<'EOF'
   __  __  ____  __  __  _____   _   _  ___ __  __
  |  |/  ||  _ \|  ||  ||     | | \ | ||_ _|\ \/ /
  |     / | |_) |  ||  ||  _  | |  \| | | |  \  / 
  |  |\  \|  _ < \    / | | | | | . ` | | |  /  \ 
  |__| \__||_| \_\ |__|  |_| |_| |_|\_||___|/_/\_\
EOF
  printf '%b\n' "$reset"
  printf '%b\n' "$dim  Modular NixOS Workstation & AI Brain$reset"
  printf '\n'
}

styled_line() {
  local color="$1"
  local icon="$2"
  local text="$3"
  local target="${4:-stdout}"

  if [[ "${json_mode:-0}" -eq 1 ]]; then
    if [[ "$target" == "stderr" ]]; then
       printf '%s %s\n' "$icon" "$text" >&2
    else
       printf '%s %s\n' "$icon" "$text"
    fi
    return 0
  fi

  local out
  if [[ -n "$color" ]]; then
    out="$(printf '%b%s %s%b' "$color" "$icon" "$text" "$reset")"
  else
    out="$(printf '%s %s' "$icon" "$text")"
  fi

  if [[ "$target" == "stderr" ]]; then
    printf '%s\n' "$out" >&2
  else
    printf '%s\n' "$out"
  fi
}

blue_line()    { styled_line "$blue"    "󰀘" "$1"; }
magenta_line() { styled_line "$magenta" "󱄅" "$1"; }
cyan_line()    { styled_line "$cyan"    "󰋙" "$1"; }
success_line() { styled_line "$green"   "󰄬" "$1"; }
warn_line()    { styled_line "$yellow"  "󱈸" "$1"; }
error_line()   { styled_line "$red"     "󰅚" "$1" "stderr"; }
header_line()  { printf '\n%b%s %b%s%b\n' "$bold$cyan" "󰘧" "$reset$bold" "$1" "$reset"; }

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
  # Só imprime o trace de comando se KRYONIX_TRACE estiver definido como 1
  if [[ "${KRYONIX_TRACE:-0}" -ne 1 ]]; then
    return 0
  fi

  # Suprime trace em modo JSON, a menos que verbose seja solicitado
  if [[ "${json_mode:-0}" -eq 1 ]] && [[ "${verbose:-0}" -eq 0 ]]; then
    return 0
  fi

  # Verificação adicional por argumento --json para segurança extra
  for arg in "$@"; do
    if [[ "$arg" == "--json" ]] && [[ "${verbose:-0}" -eq 0 ]]; then
      return 0
    fi
  done

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
  if [[ -n "${KRYONIX_BOOTSTRAP_REPO:-}" ]]; then
    printf '%s\n' "$KRYONIX_BOOTSTRAP_REPO"
    return 0
  fi

  if [[ -n "${KRYONIX_REPO_URL:-}" ]]; then
    printf '%s\n' "$KRYONIX_REPO_URL"
    return 0
  fi

  if [[ -n "${KRYONIX_REPO:-}" ]]; then
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

current_hostname() {
  cat /proc/sys/kernel/hostname
}

init_colors() {
  blue=""
  reset=""

  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    blue=$'\033[34m'
    reset=$'\033[0m'
  fi
}

blue_line() {
  local text="$1"

  if [[ "${json_mode:-0}" -eq 1 ]]; then
    if [[ -n "$blue" ]]; then
      printf '%b%s%b\n' "$blue" "$text" "$reset" >&2
    else
      printf '%s\n' "$text" >&2
    fi
    return 0
  fi

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

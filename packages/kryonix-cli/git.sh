kryonix_git_repo_path() {
  if [[ -n "${KRYONIX_SYSTEM_REPO:-}" ]]; then
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
    printf '%s\n' "ERRO: branch activa '$branch' inválida; esperado 'main'." >&2
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
  cmd+=("${verbose_args[@]}" "${dry_args[@]}" "${extra_args[@]}")
  run_command "${cmd[@]}"
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
  blue_line "  branch          : ${branch:-desconhecida}"
  blue_line "  remoto origin   : ${origin:-ausente}"

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

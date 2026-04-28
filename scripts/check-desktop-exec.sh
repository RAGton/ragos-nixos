#!/usr/bin/env bash
set -euo pipefail

dirs=(
  "$HOME/.local/share/applications"
  "$HOME/.local/share/flatpak/exports/share/applications"
  "$HOME/.nix-profile/share/applications"
  "/etc/profiles/per-user/$USER/share/applications"
  "/run/current-system/sw/share/applications"
  "/var/lib/flatpak/exports/share/applications"
)

for dir in "${dirs[@]}"; do
  [ -d "$dir" ] || continue
  echo "### DIR: $dir"
  find "$dir" -name "*.desktop" -type f | while read -r file; do
    exec_line="$(grep -m1 '^Exec=' "$file" || true)"
    [ -n "$exec_line" ] || continue

    cmd="${exec_line#Exec=}"
    cmd="${cmd%% *}"
    cmd="${cmd//\"/}"

    [ -z "$cmd" ] && continue

    if ! command -v "$cmd" >/dev/null 2>&1 && [ ! -x "$cmd" ]; then
      echo "[BROKEN] $file"
      echo "         $exec_line"
      echo "         missing: $cmd"
    fi
  done
done

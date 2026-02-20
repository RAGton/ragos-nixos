#!/usr/bin/env bash
set -euo pipefail

# Pequena “TUI” em terminal puro, sem dialog.
# Preferimos UX simples e portátil: menus numerados + confirmação.

ui::hr() {
  printf '%s\n' "------------------------------------------------------------"
}

ui::title() {
  ui::hr
  printf '%s\n' "$1"
  ui::hr
}

ui::pause() {
  printf '%s' "\nPressione Enter para continuar..."
  read -r _
}

ui::confirm() {
  local prompt=${1:-"Confirmar?"}
  local reply
  printf '%s [s/N]: ' "$prompt"
  read -r reply
  case "${reply,,}" in
    s|sim|y|yes) return 0;;
    *) return 1;;
  esac
}

ui::prompt() {
  local prompt=${1:-""}
  local var
  printf '%s' "$prompt"
  read -r var
  printf '%s' "$var"
}

ui::menu() {
  # ui::menu "Título" "op1" "op2" ...
  # retorna índice (1-based) em stdout
  local title=$1
  shift

  ui::title "$title"

  local i=1
  for item in "$@"; do
    printf '[%d] %s\n' "$i" "$item"
    i=$((i+1))
  done

  printf '\nEscolha uma opção: '

  local choice
  while true; do
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
      printf '%s' "$choice"
      return 0
    fi
    printf 'Opção inválida. Tente novamente: '
  done
}

sys::list_hosts() {
  # Lista hosts que têm default.nix (independente de estar no flake outputs)
  local hosts_dir=$1
  find "$hosts_dir" -mindepth 1 -maxdepth 1 -type d -print0 \
    | xargs -0 -I{} bash -lc 'test -f "{}/default.nix" && basename "{}"' \
    | sort
}

sys::list_disks_pretty() {
  # Retorna linhas: /dev/<name>|<model>|<size>
  lsblk -d -n -o PATH,MODEL,SIZE,TYPE \
    | awk '$4=="disk" {print $1"|"$2"|"$3}'
}

sys::require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Este instalador precisa rodar como root." >&2
    echo "Dica: use 'sudo -i' no LiveCD e rode novamente." >&2
    exit 1
  fi
}


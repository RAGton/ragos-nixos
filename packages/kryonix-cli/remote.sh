#!/usr/bin/env bash

if ! declare -F blue_line >/dev/null 2>&1; then
  blue_line() { printf '\033[34m%s\033[0m\n' "$*"; }
fi
if ! declare -F yellow_line >/dev/null 2>&1; then
  yellow_line() { printf '\033[33m%s\033[0m\n' "$*"; }
fi
if ! declare -F green_line >/dev/null 2>&1; then
  green_line() { printf '\033[32m%s\033[0m\n' "$*"; }
fi
if ! declare -F red_line >/dev/null 2>&1; then
  red_line() { printf '\033[31m%s\033[0m\n' "$*"; }
fi

kryonix_remote_vnc_status() {
  local tunnel_active=0
  local glacier_wayvnc=0
  local current_host
  current_host=$(hostname)

  blue_line "Kryonix Remote VNC Status (Host: $current_host)"

  if [[ "$current_host" == "RVE-GLACIER" || "$current_host" == "glacier" ]]; then
    if systemctl --user is-active --quiet kryonix-wayvnc; then
      green_line "  Glacier WayVNC  : ATIVO (escutando em 127.0.0.1:5900)"
      blue_line ""
      blue_line "Lembrete: Para conectar, rode 'kryonix remote vnc start' no host que irá acessar (ex: Inspiron)."
    else
      yellow_line "  Glacier WayVNC  : INATIVO"
    fi
  else
    # Comportamento Cliente (Inspiron)
    if systemctl --user is-active --quiet kryonix-glacier-vnc-tunnel; then
      tunnel_active=1
      green_line "  Inspiron Tunnel : ATIVO (escutando em 127.0.0.1:5901)"
    else
      yellow_line "  Inspiron Tunnel : INATIVO"
    fi

    if ssh -o ConnectTimeout=2 glacier-publico systemctl --user is-active --quiet kryonix-wayvnc 2>/dev/null; then
      glacier_wayvnc=1
      green_line "  Glacier WayVNC  : ATIVO (escutando em 127.0.0.1:5900)"
    else
      yellow_line "  Glacier WayVNC  : INATIVO ou INALCANCAVEL"
    fi

    if (( tunnel_active && glacier_wayvnc )); then
      blue_line ""
      green_line "Conexão VNC pronta! Conecte em: 127.0.0.1:5901"
    fi
  fi
}

kryonix_remote_vnc_start() {
  local current_host
  current_host=$(hostname)

  if [[ "$current_host" == "RVE-GLACIER" || "$current_host" == "glacier" ]]; then
    blue_line "Iniciando servidor WayVNC no Glacier..."
    systemctl --user start kryonix-wayvnc
    if systemctl --user is-active --quiet kryonix-wayvnc; then
      green_line "WayVNC iniciado com sucesso no servidor."
      yellow_line ""
      yellow_line "AVISO: O servidor está pronto, mas para acessá-lo você deve rodar"
      yellow_line "o comando de túnel no host CLIENTE (ex: inspiron):"
      yellow_line "  kryonix remote vnc start"
    else
      red_line "Falha ao iniciar WayVNC. Verifique se há uma sessão gráfica ativa."
    fi
  else
    blue_line "Iniciando túnel SSH para o Glacier VNC..."
    systemctl --user start kryonix-glacier-vnc-tunnel
    if systemctl --user is-active --quiet kryonix-glacier-vnc-tunnel; then
      green_line "Túnel iniciado com sucesso."
      kryonix_remote_vnc_status
    else
      red_line "Falha ao iniciar o túnel SSH. Verifique os logs com: journalctl --user -u kryonix-glacier-vnc-tunnel -e"
    fi
  fi
}

kryonix_remote_vnc_stop() {
  local current_host
  current_host=$(hostname)

  if [[ "$current_host" == "RVE-GLACIER" || "$current_host" == "glacier" ]]; then
    blue_line "Parando servidor WayVNC no Glacier..."
    systemctl --user stop kryonix-wayvnc
    green_line "WayVNC parado."
  else
    blue_line "Parando túnel SSH para o Glacier VNC..."
    systemctl --user stop kryonix-glacier-vnc-tunnel
    green_line "Túnel parado."
  fi
}

kryonix_remote_vnc() {
  local sub="${1:-help}"
  shift || true

  case "$sub" in
    status)
      kryonix_remote_vnc_status "$@"
      ;;
    start|tunnel)
      kryonix_remote_vnc_start "$@"
      ;;
    stop)
      kryonix_remote_vnc_stop "$@"
      ;;
    help|*)
      printf "Uso: kryonix remote vnc <status|start|stop|tunnel>\n"
      ;;
  esac
}

kryonix_remote() {
  local sub="${1:-help}"
  shift || true

  case "$sub" in
    vnc)
      kryonix_remote_vnc "$@"
      ;;
    help|*)
      printf "Uso: kryonix remote <vnc>\n"
      ;;
  esac
}

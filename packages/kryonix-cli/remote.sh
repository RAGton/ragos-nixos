#!/usr/bin/env bash

kryonix_remote_vnc_status() {
  local tunnel_active=0
  local glacier_wayvnc=0

  blue_line "Kryonix Remote VNC Status"

  if systemctl --user is-active --quiet kryonix-glacier-vnc-tunnel; then
    tunnel_active=1
    green_line "  Inspiron Tunnel : ATIVO (escutando em 127.0.0.1:5901)"
  else
    yellow_line "  Inspiron Tunnel : INATIVO"
  fi

  # Tenta verificar o status no Glacier, se SSH estiver configurado
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
}

kryonix_remote_vnc_start() {
  blue_line "Iniciando túnel SSH para o Glacier VNC..."
  systemctl --user start kryonix-glacier-vnc-tunnel
  if systemctl --user is-active --quiet kryonix-glacier-vnc-tunnel; then
    green_line "Túnel iniciado com sucesso."
    kryonix_remote_vnc_status
  else
    red_line "Falha ao iniciar o túnel SSH. Verifique os logs com: journalctl --user -u kryonix-glacier-vnc-tunnel -e"
  fi
}

kryonix_remote_vnc_stop() {
  blue_line "Parando túnel SSH para o Glacier VNC..."
  systemctl --user stop kryonix-glacier-vnc-tunnel
  green_line "Túnel parado."
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

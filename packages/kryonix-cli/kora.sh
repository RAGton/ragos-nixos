#!/usr/bin/env bash
# =============================================================================
# Kora CLI Wrapper
#
# Integra a assistente Kora ao wrapper oficial `kryonix`.
# Gerencia auth, URLs e modo local/remoto automaticamente.
# =============================================================================

kora_api_url() {
  local url="${KORA_API_URL:-}"
  if [[ -z "$url" ]]; then
    # Se estamos no Glacier (server), a Kora roda no localhost
    if [[ "$(map_runtime_host)" == "glacier" ]]; then
      url="http://127.0.0.1:8787"
    else
      # Se estamos no Inspiron (client), a Kora é acessada via rede
      # Tenta DNS (Tailscale) primeiro, fallback para IP local
      if timeout 0.5 ping -c 1 rve-glacier >/dev/null 2>&1; then
        url="http://rve-glacier:8787"
      else
        url="http://10.0.0.2:8787"
      fi
    fi
  fi
  printf '%s\n' "${url%/}"
}

export_kora_env() {
  if [[ -f "/etc/kryonix/kora.env" ]] && [[ -r "/etc/kryonix/kora.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "/etc/kryonix/kora.env"
    set +a
  fi
}

kora_is_offline() {
  local url
  url="$(kora_api_url)"
  if ! curl -sS --max-time 2 -o /dev/null "$url/health"; then
    return 0 # Offline
  fi
  return 1 # Online
}

kora_curl() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local url
  local -a curl_args
  local api_key

  export_kora_env
  url="$(kora_api_url)"
  api_key="${KORA_API_KEY:-}"

  curl_args=(--connect-timeout 5 --max-time 120 -X "$method" -H "Accept: application/json")

  if [[ -n "$data" ]] || [[ "$method" == "POST" ]] || [[ "$method" == "PUT" ]]; then
    curl_args+=(-H "Content-Type: application/json")
  fi

  if [[ -n "$api_key" ]]; then
    curl_args+=(-H "X-API-Key: $api_key")
  fi

  if [[ -n "$data" ]]; then
    curl_args+=(--data "$data")
  fi

  if kora_is_offline; then
    if [[ "$(map_runtime_host)" == "glacier" ]]; then
      printf 'ERRO: Kora API local (%s) não está ativa.\n' "$url" >&2
      printf 'Use: systemctl status kora.service\n' >&2
    else
      printf 'WARN: Kora API remota não acessível em %s\n' "$url" >&2
      printf 'Dica: Abra o túnel SSH no Inspiron com:\n' >&2
      printf '      kryonix kora tunnel\n' >&2
    fi
    return 2
  fi

  local tmp_resp http_code status
  tmp_resp=$(mktemp)

  http_code=$(curl -sS -w "%{http_code}" -o "$tmp_resp" "${curl_args[@]}" "$url$path")
  status=$?

  if [[ $status -ne 0 ]]; then
    printf 'ERRO: Falha ao conectar ao servidor Kora (%s)\n' "$status" >&2
    rm -f "$tmp_resp"
    return "$status"
  fi

  if [[ "$http_code" == "401" ]] || [[ "$http_code" == "403" ]]; then
    printf 'ERRO: endpoint protegido. Defina KORA_API_KEY.\n' >&2
    rm -f "$tmp_resp"
    return 1
  elif [[ "$http_code" -ge 400 ]]; then
    printf 'ERRO: A Kora retornou status HTTP %s.\n' "$http_code" >&2
    cat "$tmp_resp" >&2
    printf '\n' >&2
    rm -f "$tmp_resp"
    return 1
  fi

  cat "$tmp_resp"
  printf '\n'
  rm -f "$tmp_resp"
  return 0
}

kora_stream() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local url
  local -a curl_args
  local api_key

  export_kora_env
  url="$(kora_api_url)"
  api_key="${KORA_API_KEY:-}"

  curl_args=(--no-buffer --connect-timeout 5 --max-time 300 -sS -X "$method" -H "Accept: text/event-stream")

  if [[ -n "$data" ]] || [[ "$method" == "POST" ]]; then
    curl_args+=(-H "Content-Type: application/json")
    curl_args+=(--data "$data")
  fi

  if [[ -n "$api_key" ]]; then
    curl_args+=(-H "X-API-Key: $api_key")
  fi

  curl "${curl_args[@]}" "$url$path"
}

kryonix_kora_health() {
  kora_curl GET /health | jq .
}

kryonix_kora_status() {
  kora_curl GET /status | jq .
}

kryonix_kora_capabilities() {
  kora_curl GET /capabilities | jq .
}

kryonix_kora_ask() {
  local mode="auto"
  local query=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        mode="$2"
        shift 2
        ;;
      *)
        query="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$query" ]]; then
    printf 'Uso: kryonix kora ask "pergunta" [--mode direct|rag|auto]\n' >&2
    return 1
  fi

  local payload
  payload="$(jq -n --arg question "$query" '{question:$question}')"

  if [[ "$mode" == "direct" ]]; then
    payload="$(jq -n --arg message "$query" --arg mode "$mode" '{message:$message, mode:$mode}')"
    kora_stream POST /chat/stream "$payload" | python3 -c '
import sys, json
for line in sys.stdin:
    if line.startswith("data: "):
        try:
            data = json.loads(line[6:])
            if "chunk" in data:
                sys.stdout.write(data["chunk"])
                sys.stdout.flush()
        except Exception:
            pass
print()
'
  elif [[ "$mode" != "auto" ]]; then
    payload="$(jq -n --arg message "$query" --arg mode "$mode" '{message:$message, mode:$mode}')"
    local resp
    resp="$(kora_curl POST /chat "$payload")" || return $?
    printf '%s\n' "$resp" | jq -r '.answer // "Erro ao obter resposta."'
  else
    local resp
    resp="$(kora_curl POST /ask "$payload")" || return $?
    printf '%s\n' "$resp" | jq -r '.answer // "Erro ao obter resposta."'
  fi
}

kryonix_kora_chat() {
  printf 'WARN: O modo chat interativo será implementado na Fase 3.\n' >&2
  printf '      Para uma pergunta única, use: kryonix kora ask "sua pergunta"\n' >&2
  return 0
}

kryonix_kora_memory_search() {
  local query="$1"
  if [[ -z "$query" ]]; then
    printf 'Uso: kryonix kora memory search "termo"\n' >&2
    return 1
  fi

  local payload
  payload="$(jq -n --arg query "$query" --arg mode "hybrid" '{query:$query, mode:$mode}')"
  kora_curl POST /memory/search "$payload" | jq .
}

kryonix_kora_login() {
  if [[ "$(map_runtime_host)" == "glacier" ]]; then
    printf 'INFO: Você já está no servidor Glacier.\n'
    return 0
  fi

  local ssh_target="${KRYONIX_GLACIER_SSH_TARGET:-rocha@rve-glacier}"
  local ssh_port="${KRYONIX_GLACIER_SSH_PORT:-2224}"
  local remote_env="/etc/kryonix/kora.env"
  local local_env="/etc/kryonix/kora.env"

  printf 'Sincronizando Kora API Key do Glacier...\n'
  
  local key
  key=$(ssh -p "$ssh_port" "$ssh_target" "sudo grep KORA_API_KEY $remote_env | cut -d= -f2" 2>/dev/null)
  
  if [[ -z "$key" ]]; then
    printf 'ERRO: Não foi possível obter a chave via SSH. Verifique o acesso e se o arquivo existe no servidor.\n' >&2
    return 1
  fi

  printf 'KORA_API_KEY=%s\n' "$key" | sudo tee "$local_env" >/dev/null
  sudo chmod 600 "$local_env"
  printf 'OK: Chave sincronizada e salva em %s\n' "$local_env"
}

kryonix_kora_tunnel() {
  if [[ "$(map_runtime_host)" == "glacier" ]]; then
    printf 'INFO: O túnel não é necessário no Glacier, a Kora roda nativamente no localhost.\n' >&2
    return 0
  fi

  local ssh_target="${KRYONIX_GLACIER_SSH_TARGET:-glacier-public}"
  local ssh_port="${KRYONIX_GLACIER_SSH_PORT:-2224}"

  printf 'Abrindo túnel SSH para a Kora no Glacier...\n'
  printf 'Alvo: %s:%s\n' "$ssh_target" "$ssh_port"
  printf 'Local: http://127.0.0.1:18787\n'
  printf 'Pressione Ctrl+C para encerrar.\n\n'

  ssh -p "$ssh_port" -N -L 18787:127.0.0.1:8787 "$ssh_target"
}

kryonix_kora() {
  local sub="${1:-help}"
  shift || true

  case "$sub" in
    health)
      kryonix_kora_health "$@"
      ;;
    status)
      kryonix_kora_status "$@"
      ;;
    capabilities)
      kryonix_kora_capabilities "$@"
      ;;
    ask)
      kryonix_kora_ask "$@"
      ;;
    chat)
      kryonix_kora_chat "$@"
      ;;
    memory)
      if [[ "$1" == "search" ]]; then
        shift
        kryonix_kora_memory_search "$@"
      else
        printf 'Uso: kryonix kora memory search "termo"\n' >&2
        return 1
      fi
      ;;
    tunnel)
      kryonix_kora_tunnel
      ;;
    login)
      kryonix_kora_login
      ;;
    *)
      printf 'Uso: kryonix kora <health|status|capabilities|ask|chat|memory search|tunnel|login>\n' >&2
      return 1
      ;;
  esac
}

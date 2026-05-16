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
      # Aumentado timeout para 2.0s devido a possíveis latências de wake-up do Tailscale
      if timeout 2.0 ping -c 1 rve-glacier >/dev/null 2>&1; then
        url="http://rve-glacier:8787"
      else
        url="http://10.0.0.2:8787"
      fi
    fi
  fi
  printf '%s\n' "${url%/}"
}

export_kora_env() {
  # 1. Tenta carregar do config local do usuário (preferencial para clientes)
  local user_config="$HOME/.config/kryonix/kora.env"
  if [[ -f "$user_config" ]] && [[ -r "$user_config" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$user_config"
    set +a
  fi

  # 2. Tenta carregar do config global (preferencial para o servidor)
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

# ── Animação de Pensamento ──────────────────────────────────────
# Mostra uma animação minimalista enquanto a Kora processa.
# Uso: show_thinking_animation <start_time> <label>
show_thinking_animation() {
  local start_time="$1"
  local label="${2:-pensando localmente}"
  local frames=("◜" "◠" "◝" "◞" "◡" "◟")
  local i=0
  
  # Garante que a animação pare se o processo pai morrer
  trap "tput el; exit" SIGINT SIGTERM
  
  while true; do
    local now
    now=$(date +%s.%N)
    local elapsed
    elapsed=$(echo "$now - $start_time" | bc 2>/dev/null || echo "0")
    
    # Formata para uma casa decimal
    printf "\r\e[K" # Limpa a linha
    printf "\e[1;36mKORA\e[0m  \e[33m%s\e[0m  %s  \e[2m%.1fs\e[0m" "${frames[$i]}" "$label" "$elapsed" >&2
    
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep 0.1
  done
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
  local profile=0
  local start_time
  start_time=$(date +%s.%N)

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        mode="$2"
        shift 2
        ;;
      --profile)
        profile=1
        shift
        ;;
      *)
        query="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$query" ]]; then
    printf 'Uso: kryonix kora ask "pergunta" [--mode direct|rag|auto] [--profile]\n' >&2
    return 1
  fi

  # Variáveis para profiling
  local first_token_time=""
  local endpoint="/chat"
  
  # Se stdout for TTY, mostra animação
  local anim_pid=""
  if [[ -t 1 ]]; then
    local label="pensando localmente"
    [[ "$mode" == "rag" || "$mode" == "auto" ]] && label="consultando memória"
    show_thinking_animation "$start_time" "$label" &
    anim_pid=$!
  fi

  # Payload base
  local payload
  payload="$(jq -n --arg question "$query" --arg message "$query" --arg mode "$mode" '{question:$question, message:$message, mode:$mode}')"

  # Stream se modo direct e TTY (ou explicitamente solicitado no futuro)
  if [[ "$mode" == "direct" && -t 1 ]]; then
    endpoint="/chat/stream"
    local first=1
    
    # Stream handler
    kora_stream POST "$endpoint" "$payload" | while read -r line; do
      if [[ "$line" == data:\ * ]]; then
        # Limpa animação no primeiro token
        if [[ $first -eq 1 ]]; then
          [[ -n "$anim_pid" ]] && kill "$anim_pid" 2>/dev/null && wait "$anim_pid" 2>/dev/null
          printf "\r\e[K" >&2
          printf "\e[1;36mKora:\e[0m\n"
          first=0
          first_token_time=$(date +%s.%N)
        fi
        
        local chunk
        chunk=$(echo "$line" | sed 's/^data: //')
        # Tenta extrair o chunk do JSON
        local text
        text=$(echo "$chunk" | jq -r '.chunk // empty')
        [[ -n "$text" ]] && printf "%s" "$text"
      fi
    done
    printf "\n"
  else
    # Fallback ou modo non-direct (RAG/Auto por enquanto via block chat)
    local resp
    resp="$(kora_curl POST "$endpoint" "$payload")"
    local status=$?
    
    # Limpa animação
    [[ -n "$anim_pid" ]] && kill "$anim_pid" 2>/dev/null && wait "$anim_pid" 2>/dev/null
    printf "\r\e[K" >&2

    if [[ $status -ne 0 ]]; then
      return $status
    fi

    printf "\e[1;36mKora:\e[0m\n"
    printf "%s\n" "$resp" | jq -r '.answer // "Erro ao obter resposta."'
  fi

  if [[ $profile -eq 1 ]]; then
    local end_time
    end_time=$(date +%s.%N)
    local total_elapsed
    total_elapsed=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
    
    printf "\n\e[2m--- Kora Profile ---\e[0m\n"
    printf "\e[2m- total:      %.2fs\e[0m\n" "$total_elapsed"
    if [[ -n "$first_token_time" ]]; then
      local ft_elapsed
      ft_elapsed=$(echo "$first_token_time - $start_time" | bc 2>/dev/null || echo "0")
      printf "\e[2m- first_token: %.2fs\e[0m\n" "$ft_elapsed"
    fi
    printf "\e[2m- mode:       %s\e[0m\n" "$mode"
    printf "\e[2m- endpoint:   %s\e[0m\n" "$endpoint"
    printf "\e[2m--------------------\e[0m\n"
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
    printf 'INFO: Você já está no servidor Glacier. A chave em /etc/kryonix/kora.env será usada.\n'
    return 0
  fi

  local ssh_target="${KRYONIX_GLACIER_SSH_TARGET:-rocha@rve-glacier}"
  local ssh_port="${KRYONIX_GLACIER_SSH_PORT:-2224}"
  local remote_env="/etc/kryonix/kora.env"
  local local_config_dir="$HOME/.config/kryonix"
  local local_env="$local_config_dir/kora.env"

  mkdir -p "$local_config_dir"
  chmod 700 "$local_config_dir"

  printf 'Sincronizando Kora API Key do Glacier (%s)...\n' "$ssh_target"
  
  # Busca a chave via SSH e salva direto no arquivo local com permissão restrita
  # Redireciona a saída do SSH para o arquivo local diretamente para evitar prints no terminal
  if ! ssh -p "$ssh_port" "$ssh_target" "sudo grep '^KORA_API_KEY=' $remote_env" > "$local_env" 2>/dev/null; then
    printf 'ERRO: Não foi possível obter a chave via SSH. Verifique o acesso.\n' >&2
    rm -f "$local_env"
    return 1
  fi

  chmod 600 "$local_env"
  
  # Valida se a chave foi capturada (sem mostrar o valor)
  if ! grep -q "KORA_API_KEY=" "$local_env"; then
    printf 'ERRO: Arquivo de chave obtido está vazio ou inválido.\n' >&2
    rm -f "$local_env"
    return 1
  fi

  local key_len fingerprint
  key_len=$(grep "KORA_API_KEY=" "$local_env" | cut -d= -f2 | tr -d '\n' | wc -c)
  fingerprint=$(grep "KORA_API_KEY=" "$local_env" | cut -d= -f2 | head -c 8)

  printf 'OK: Chave sincronizada e salva em %s\n' "$local_env"
  printf '    Fingerprint: %s... (tamanho: %s)\n' "$fingerprint" "$key_len"
  printf '    Permissões: %s\n' "$(stat -c "%a" "$local_env")"
}

kryonix_kora_latency() {
  printf 'Executando diagnóstico de latência da Kora...\n'
  
  printf '\n1. Health Check:\n'
  time kora_curl GET /health >/dev/null
  
  printf '\n2. Chat Direct (Curto):\n'
  time kora_curl POST /chat '{"message":"oi","mode":"direct"}' >/dev/null
  
  printf '\n3. Chat Direct (Médio):\n'
  time kora_curl POST /chat '{"message":"Me explique o que é NixOS em 1 parágrafo.","mode":"direct"}' >/dev/null
  
  printf '\nDiagnóstico concluído.\n'
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
    latency|doctor-latency)
      kryonix_kora_latency
      ;;
    *)
      printf 'Uso: kryonix kora <health|status|capabilities|ask|chat|memory search|tunnel|login|latency>\n' >&2
      return 1
      ;;
  esac
}

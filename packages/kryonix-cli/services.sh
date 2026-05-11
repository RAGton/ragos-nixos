kryonix_rgb() {
  if [[ $# -eq 0 ]]; then
    printf 'Uso: kryonix rgb <off|list|set>\n' >&2
    return 1
  fi
  local rgb_sub="$1"
  shift

  # Detecção de host para roteamento remoto
  local host; host="$(map_runtime_host)"
  if [[ "$(hostname)" != "RVE-GLACIER" && "$host" == "glacier" ]]; then
    printf '🌐 Encaminhando comando RGB para o Glacier...\n'
    ssh -p 2224 rocha@10.0.0.2 "kryonix rgb $rgb_sub $*"
    return $?
  fi

  case "$rgb_sub" in
    off)
      printf '🌑 Desligando todos os LEDs...\n'
      openrgb --mode static --color 000000
      ;;
    list)
      openrgb --list-devices
      ;;
    set)
      local color="${1:-000000}"
      printf '🎨 Definindo cor %s...\n' "$color"
      openrgb --mode static --color "$color"
      ;;
    *)
      printf 'Uso: kryonix rgb <off|list|set> [cor]\n' >&2
      return 1
      ;;
  esac
}

kryonix_ollama() {
  if [[ $# -eq 0 ]]; then
    printf 'Uso: kryonix ollama <start|stop|status|run|vram|pull>\n' >&2
    return 1
  fi
  local ollama_sub="$1"
  shift

  local host; host="$(map_runtime_host)"

  if [[ "$host" == "glacier" ]]; then
    # Local Ollama service on Glacier
    case "$ollama_sub" in
      start)
        printf '🚀 Iniciando Ollama local no Glacier...\n'
        sudo systemctl start ollama
        # Polling até porta 11434 responder (max 30s)
        for _i in $(seq 1 30); do
          if curl -s -o /dev/null -w "" http://127.0.0.1:11434/ 2>/dev/null; then
            printf '✅ Ollama ativo na porta 11434\n'
            # Mostrar VRAM
            if command -v nvidia-smi &>/dev/null; then
              nvidia-smi --query-gpu=memory.used,memory.free,memory.total --format=csv,noheader
            fi
            return 0
          fi
          sleep 1
        done
        printf '⚠️  Ollama não respondeu em 30s. Verifique: journalctl -u ollama --no-pager -n 20\n' >&2
        return 1
        ;;
      stop)
        printf '🛑 Parando Ollama local no Glacier...\n'
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
        local model="${1:-qwen2.5-coder:7b}"
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
          return 1
        fi
        ;;
      pull)
        local model="${1:-qwen2.5-coder:7b}"
        if ! curl -s -o /dev/null http://127.0.0.1:11434/ 2>/dev/null; then
          printf '🚀 Ollama não está ativo. Iniciando para pull...\n'
          sudo systemctl start ollama
          sleep 3
        fi
        ollama pull "$model"
        ;;
      *)
        printf 'Uso: kryonix ollama <start|stop|status|run|vram|pull> [model]\n' >&2
        return 1
        ;;
    esac
  else
    # Remote Ollama client on Inspiron/Other clients via SSH tunnel to Glacier
    case "$ollama_sub" in
      start)
        printf '🚀 Iniciando túnel SSH para o Ollama remoto no Glacier...\n'
        systemctl --user start kryonix-ollama-tunnel
        # Polling até porta 11434 responder (max 30s)
        for _i in $(seq 1 30); do
          if curl -s -o /dev/null -w "" http://127.0.0.1:11434/ 2>/dev/null; then
            printf '✅ Túnel ativo! Ollama remoto pronto na porta local 11434\n'
            return 0
          fi
          sleep 1
        done
        printf '⚠️  Túnel/Ollama remoto não respondeu na porta local 11434 em 30s.\n' >&2
        printf 'Verifique com: systemctl --user status kryonix-ollama-tunnel\n' >&2
        return 1
        ;;
      stop)
        printf '🛑 Parando túnel SSH do Ollama remoto...\n'
        systemctl --user stop kryonix-ollama-tunnel
        printf '✅ Túnel parado.\n'
        ;;
      status)
        systemctl --user status kryonix-ollama-tunnel --no-pager 2>/dev/null || printf 'Túnel do Ollama não está rodando.\n'
        if curl -s -o /dev/null http://127.0.0.1:11434/ 2>/dev/null; then
          printf '✅ Ollama remoto está RESPONDENDO via túnel na porta local 11434\n'
        else
          printf '❌ Ollama remoto NÃO está respondendo na porta local 11434\n'
        fi
        ;;
      run)
        local model="${1:-qwen2.5-coder:7b}"
        if ! curl -s -o /dev/null http://127.0.0.1:11434/ 2>/dev/null; then
          printf '🚀 Túnel Ollama remoto não está ativo. Iniciando...\n'
          systemctl --user start kryonix-ollama-tunnel
          sleep 3
        fi
        exec ollama run "$model"
        ;;
      vram)
        printf 'Verificando GPU VRAM no Glacier remoto via SSH...\n'
        ssh glacier-public nvidia-smi --query-gpu=name,memory.used,memory.free,memory.total,temperature.gpu --format=csv,noheader 2>/dev/null || printf 'Não foi possível conectar ao Glacier via SSH.\n'
        ;;
      pull)
        local model="${1:-qwen2.5-coder:7b}"
        if ! curl -s -o /dev/null http://127.0.0.1:11434/ 2>/dev/null; then
          printf '🚀 Túnel Ollama remoto não está ativo. Iniciando para pull...\n'
          systemctl --user start kryonix-ollama-tunnel
          sleep 3
        fi
        ollama pull "$model"
        ;;
      *)
        printf 'Uso: kryonix ollama <start|stop|status|run|vram|pull> [model]\n' >&2
        return 1
        ;;
    esac
  fi
}

kryonix_ai() {
  if [[ $# -eq 0 ]]; then
    printf 'Uso: kryonix ai <continue|status|checkpoint>\n' >&2
    return 1
  fi
  local ai_sub="$1"
  shift

  local state_file
  state_file="$(kryonix_repo_root)/.ai/STATE.md"
  local ai_dir
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
        return 1
      fi
      printf "=== Estado Atual da IA ===\n"
      cat "$state_file"
      ;;
    checkpoint)
      ensure_state_file
      local msg="${*:-Checkpoint manual}"
      local checkpoint_file="$ai_dir/CHECKPOINTS.md"

      if [[ ! -f "$checkpoint_file" ]]; then
        cat <<EOF > "$checkpoint_file"
# Kryonix AI Checkpoints
EOF
      fi

      local timestamp
      timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      printf "\n## [%s] Checkpoint\n\n%s\n" "$timestamp" "$msg" >> "$checkpoint_file"

      # Tenta atualizar o último passo no STATE.md se existir
      sed -i "s/^- \*\*Último passo concluído\*\*: .*/- \*\*Último passo concluído\*\*: $msg ($timestamp)/" "$state_file"

      printf "✅ Checkpoint registrado: %s\n" "$msg"
      ;;
    *)
      printf 'Uso: kryonix ai <continue|status|checkpoint>\n' >&2
      return 1
      ;;
  esac
}

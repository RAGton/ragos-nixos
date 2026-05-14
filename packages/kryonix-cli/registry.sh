# Kryonix CLI Registry — Single Source of Truth
# Este arquivo define todos os comandos, subcomandos e metadados da CLI.

# Estrutura interna: uma lista de strings formatadas para fácil parse sem jq
# "grupo|comando|subcomando|descrição|flags"
KRYONIX_REGISTRY=(
  # --- Sistema ---
  "system|switch||Aplica configuração NixOS|--update --dry --host --flake"
  "system|boot||Gera próxima ativação no boot|--update --dry --host --flake"
  "system|test||Testa a configuração sem persistir|--host --flake"
  "system|rebuild||Compila o sistema sem ativar|--host --flake"
  "system|clean||Limpa gerações antigas|--verbose"
  "system|diff||Compara mudanças de sistema|--host --flake"
  "system|iso||Gera imagem ISO instalável|--flake"
  "system|install||Instalador Kryonix (Fase 1)|"
  "system|hardware||Diagnóstico e scan de hardware|--json"
  "system|disk||Gestão e planejamento de discos|"
  "system|doctor||Diagnóstico e saúde do sistema|full"

  # --- Home ---
  "home|home||Gestão de Home Manager e Brain Scan|--update --dry --host --flake"
  "home|update||Sincroniza inputs do flake.lock|--verbose"
  "home|check||Valida integridade do projeto|--flake"
  "home|fmt||Auto-formatação de código Nix|--flake"
  "home|git-status||Status do git do repositório|"

  # --- Brain ---
  "brain|brain||Busca e diagnósticos RAG|"
  "brain|brain|health|Status da API Brain|--local --remote"
  "brain|brain|doctor|Diagnóstico completo do Brain|--local --remote"
  "brain|brain|stats|Estatísticas do índice/RAG|--local --remote"
  "brain|brain|search|Busca semântica no RAG|--explain --local --remote"
  "brain|brain|ask|Pergunta ao Brain usando contexto|--explain --local --remote"
  "brain|brain|vault-scan|Escaneia o Vault/Obsidian|"
  "brain|brain|index|Indexa conteúdo no Brain|"
  "brain|brain|api-key|Gestão da chave de acesso|status validate"
  "brain|brain|vram-audit|Auditoria de GPU/VRAM (Glacier)|"
  "brain|brain|vram-profile|Altera perfil de VRAM runtime|ai balanced gaming"
  "brain|brain|remote|Operações remotas do Brain|status"

  # --- Graph ---
  "graph|graph||Operações no Grafo de Conhecimento|"
  "graph|graph|status|Conexão com Neo4j|--local --remote"
  "graph|graph|stats|Estatísticas do grafo|--local --remote"
  "graph|graph|query|Consulta Cypher direta|--cypher"
  "graph|graph|repair|Repara inconsistências no grafo|--local --remote"

  # --- MCP ---
  "mcp|mcp||Interface Model Context Protocol|"
  "mcp|mcp|check|Valida servidores MCP|"
  "mcp|mcp|doctor|Valida conectividade JSON-RPC|"
  "mcp|mcp|print-config|Mostra configuração MCP atual|"

  # --- Vault ---
  "vault|vault||Gestão do Obsidian Vault|"
  "vault|vault|scan|Escaneia o vault por mudanças|"
  "vault|vault|index|Reindexa o vault no Brain|"

  # --- Utilidades ---
  "utils|ollama||Gerencia LLMs locais|"
  "utils|ollama|status|Status do serviço Ollama|"
  "utils|ollama|list|Lista modelos carregados|"
  "utils|ollama|run|Inicia chat interativo|"
  "utils|ollama|pull|Baixa novo modelo|"
  "utils|ai||Estado da camada de IA|"
  "utils|remote||VNC, SSH e Túneis|"
  "utils|rgb||Customização visual OpenRGB|on off color mode"
  "utils|all||Unificação total: OS + Home|--update --dry --flake"
  "utils|repl||Nix REPL no contexto da flake|--flake"
)

# Funções de consulta rápidas para autocomplete e help

kryonix_get_groups() {
  printf "system\nhome\nbrain\ngraph\nmcp\nvault\nutils\n"
}

kryonix_get_commands() {
  local line cmd
  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r _ cmd sub _ _ <<< "$line"
    if [[ -z "$sub" ]]; then
      printf "%s\n" "$cmd"
    fi
  done | sort -u
}

kryonix_get_subcommands() {
  local parent="$1"
  local line cmd sub
  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r _ cmd sub _ _ <<< "$line"
    if [[ "$cmd" == "$parent" && -n "$sub" ]]; then
      printf "%s\n" "$sub"
    fi
  done | sort -u
}

kryonix_get_flags() {
  local cmd_match="$1"
  local sub_match="${2:-}"
  local line cmd sub _ flags
  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r _ cmd sub _ flags <<< "$line"
    if [[ "$cmd" == "$cmd_match" && "$sub" == "$sub_match" ]]; then
      printf "%s\n" "$flags" | tr ' ' '\n'
      return 0
    fi
  done
}

kryonix_get_description() {
  local cmd_match="$1"
  local sub_match="${2:-}"
  local line cmd sub desc
  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r _ cmd sub desc _ <<< "$line"
    if [[ "$cmd" == "$cmd_match" && "$sub" == "$sub_match" ]]; then
      printf "%s\n" "$desc"
      return 0
    fi
  done
}

kryonix_get_registry_json() {
  # Gera JSON derivado usando jq se disponível, ou fallback manual simples
  if ! command -v jq >/dev/null 2>&1; then
    printf '{"error": "jq not found"}\n'
    return 1
  fi

  local line group cmd sub desc flags
  local json='{"commands": []}'

  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r group cmd sub desc flags <<< "$line"
    json=$(printf '%s' "$json" | jq -M \
      --arg g "$group" \
      --arg c "$cmd" \
      --arg s "$sub" \
      --arg d "$desc" \
      --arg f "$flags" \
      '.commands += [{group: $g, name: $c, subcommand: $s, description: $d, flags: ($f | split(" "))}]')
  done
  printf '%s\n' "$json"
}

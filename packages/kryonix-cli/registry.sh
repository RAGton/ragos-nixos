# Kryonix CLI Registry — Single Source of Truth v2
# Este arquivo define todos os comandos, subcomandos e metadados da CLI.

# Estrutura interna (v2): 12 campos
# "grupo|comando|subcomando|descrição|flags|examples|risk_level|requires_host|requires_runtime|requires_sudo|category|status"
KRYONIX_REGISTRY=(
  # --- Sistema ---
  "system|switch||Aplica configuração NixOS|--update --dry --host --flake|kryonix switch --update|medium|all|none|true|system|stable"
  "system|boot||Gera próxima ativação no boot|--update --dry --host --flake|kryonix boot --update|medium|all|none|true|system|stable"
  "system|test||Testa a configuração sem persistir|--host --flake|kryonix test --host glacier|low|all|none|false|system|stable"
  "system|rebuild||Compila o sistema sem ativar|--host --flake||low|all|none|false|system|stable"
  "system|clean||Limpa gerações antigas|--verbose||low|all|none|false|system|stable"
  "system|diff||Compara mudanças de sistema|--host --flake||low|all|none|false|system|stable"
  "system|iso||Gera imagem ISO instalável|--flake||low|all|none|false|system|stable"
  "system|install||Instalador Kryonix (Fase 1)|||low|all|none|false|system|stable"
  "system|hardware||Diagnóstico e scan de hardware|--json||low|all|none|false|system|stable"
  "system|disk||Gestão e planejamento de discos|||low|all|none|false|system|stable"
  "system|doctor||Diagnóstico e saúde do sistema|full||low|all|none|false|system|stable"

  # --- Home ---
  "home|home||Gestão de Home Manager e Brain Scan|--update --dry --host --flake||low|all|none|false|home|stable"
  "home|update||Sincroniza inputs do flake.lock|--verbose||low|all|none|false|home|stable"
  "home|check||Valida integridade do projeto|--flake||low|all|none|false|home|stable"
  "home|fmt||Auto-formatação de código Nix|--flake||low|all|none|false|home|stable"
  "home|git-status||Status do git do repositório|||low|all|none|false|home|stable"

  # --- Brain ---
  "brain|brain||Busca e diagnósticos RAG||kryonix brain --help|low|glacier|brain-api|false|ai|stable"
  "brain|brain|health|Status da API Brain|--local --remote|kryonix brain health|low|glacier|brain-api|false|ai|stable"
  "brain|brain|doctor|Diagnóstico completo do Brain|--local --remote|kryonix brain doctor|low|glacier|brain-api|false|ai|stable"
  "brain|brain|stats|Estatísticas do índice/RAG|--local --remote|kryonix brain stats|low|glacier|brain-api|false|ai|stable"
  "brain|brain|search|Busca semântica no RAG|--explain --local --remote|kryonix brain search|low|glacier|brain-api|false|ai|stable"
  "brain|brain|ask|Pergunta ao Brain usando contexto|--explain --local --remote|kryonix brain ask|low|glacier|brain-api|false|ai|stable"
  "brain|brain|vault-scan|Escaneia o Vault/Obsidian||kryonix brain vault-scan|low|glacier|brain-api|false|ai|stable"
  "brain|brain|index|Indexa conteúdo no Brain||kryonix brain index|low|glacier|brain-api|false|ai|stable"
  "brain|brain|api-key|Gestão da chave de acesso|status validate|kryonix brain api-key|low|glacier|brain-api|true|ai|stable"
  "brain|brain|vram-audit|Auditoria de GPU/VRAM (Glacier)||kryonix brain vram-audit|low|glacier|brain-api|false|ai|stable"
  "brain|brain|vram-profile|Altera perfil de VRAM runtime|ai balanced gaming|kryonix brain vram-profile|low|glacier|brain-api|false|ai|stable"
  "brain|brain|remote|Operações remotas do Brain|status|kryonix brain remote|low|glacier|brain-api|false|ai|stable"

  # --- Graph ---
  "graph|graph||Operações no Grafo de Conhecimento||kryonix graph --help|low|glacier|neo4j|false|ai|stable"
  "graph|graph|status|Conexão com Neo4j|--local --remote|kryonix graph status|low|glacier|neo4j|false|ai|stable"
  "graph|graph|stats|Estatísticas do grafo|--local --remote|kryonix graph stats|low|glacier|neo4j|false|ai|stable"
  "graph|graph|query|Consulta Cypher direta|--cypher|kryonix graph query|low|glacier|neo4j|false|ai|stable"
  "graph|graph|repair|Repara inconsistências no grafo|--local --remote|kryonix graph repair|high|glacier|neo4j|true|ai|stable"

  # --- MCP ---
  "mcp|mcp||Interface Model Context Protocol||kryonix mcp --help|low|all|none|false|ai|stable"
  "mcp|mcp|check|Valida servidores MCP||kryonix mcp check|low|all|none|false|ai|stable"
  "mcp|mcp|doctor|Valida conectividade JSON-RPC||kryonix mcp doctor|low|all|none|false|ai|stable"
  "mcp|mcp|print-config|Mostra configuração MCP atual||kryonix mcp print-config|low|all|none|false|ai|stable"

  # --- Vault ---
  "vault|vault||Gestão do Obsidian Vault|||low|all|none|false|vault|stable"
  "vault|vault|scan|Escaneia o vault por mudanças|||low|all|none|false|vault|stable"
  "vault|vault|index|Reindexa o vault no Brain|||low|all|none|false|vault|stable"

  # --- Utilidades ---
  "utils|ollama||Gerencia LLMs locais||kryonix ollama list|low|glacier|ollama|false|ai|stable"
  "utils|ollama|status|Status do serviço Ollama||kryonix ollama list|low|glacier|ollama|false|ai|stable"
  "utils|ollama|list|Lista modelos carregados||kryonix ollama list|low|glacier|ollama|false|ai|stable"
  "utils|ollama|run|Inicia chat interativo||kryonix ollama list|low|glacier|ollama|false|ai|stable"
  "utils|ollama|pull|Baixa novo modelo||kryonix ollama list|low|glacier|ollama|false|ai|stable"
  "utils|ai||Estado da camada de IA|||low|all|none|false|utils|stable"
  "utils|remote||VNC, SSH e Túneis||kryonix remote vnc start|low|all|none|false|utils|stable"
  "utils|rgb||Customização visual OpenRGB|on off color mode||low|all|none|false|utils|stable"
  "utils|all||Unificação total: OS + Home|--update --dry --flake|kryonix all --update|medium|all|none|true|utils|stable"
  "utils|repl||Nix REPL no contexto da flake|--flake||low|all|none|false|utils|stable"
)

# Funções de consulta rápidas para autocomplete e help

kryonix_get_groups() {
  printf "system\nhome\nbrain\ngraph\nmcp\nvault\nutils\n"
}

kryonix_get_commands() {
  local line cmd sub
  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r _ cmd sub _ <<< "$line"
    if [[ -z "$sub" ]]; then
      printf "%s\n" "$cmd"
    fi
  done | sort -u
}

kryonix_get_subcommands() {
  local parent="$1"
  local line cmd sub
  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r _ cmd sub _ <<< "$line"
    if [[ "$cmd" == "$parent" && -n "$sub" ]]; then
      printf "%s\n" "$sub"
    fi
  done | sort -u
}

kryonix_get_flags() {
  local cmd_match="$1"
  local sub_match="${2:-}"
  local line cmd sub desc flags
  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r _ cmd sub desc flags _ <<< "$line"
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

  local line group cmd sub desc flags examples risk host runtime sudo cat status
  local json='{"commands": []}'

  for line in "${KRYONIX_REGISTRY[@]}"; do
    IFS='|' read -r group cmd sub desc flags examples risk host runtime sudo cat status <<< "$line"
    json=$(printf '%s' "$json" | jq -M \
      --arg g "$group" \
      --arg c "$cmd" \
      --arg s "$sub" \
      --arg d "$desc" \
      --arg f "$flags" \
      --arg ex "$examples" \
      --arg r "$risk" \
      --arg h "$host" \
      --arg rt "$runtime" \
      --arg sd "$sudo" \
      --arg cat "$cat" \
      --arg st "$status" \
      '.commands += [{
        group: $g, 
        name: $c, 
        subcommand: $s, 
        description: $d, 
        flags: ($f | split(" ") | map(select(length > 0))),
        examples: ($ex | split(";") | map(select(length > 0))),
        risk_level: $r,
        requires_host: $h,
        requires_runtime: $rt,
        requires_sudo: ($sd == "true"),
        category: $cat,
        status: $st
      }]')
  done
  printf '%s\n' "$json"
}

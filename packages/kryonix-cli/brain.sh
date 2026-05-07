brain_project_dir() {
  local repo_root project_dir

  repo_root="$(kryonix_repo_root)" || return 1
  project_dir="$repo_root/packages/kryonix-brain-lightrag"

  if [[ ! -f "$project_dir/pyproject.toml" ]]; then
    printf '%s\n' "kryonix: Brain não encontrado em $project_dir." >&2
    return 1
  fi

  printf '%s\n' "$project_dir"
}

kryonix_brain_role() {
  local explicit lower

  explicit="${KRYONIX_ROLE:-${KRYONIX_BRAIN_ROLE:-}}"
  lower="$(printf '%s' "$explicit" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    client|server)
      printf '%s\n' "$lower"
      return 0
      ;;
  esac

  case "$(map_runtime_host)" in
    glacier)
      printf '%s\n' "server"
      ;;
    *)
      printf '%s\n' "client"
      ;;
  esac
}

export_brain_env() {
  if [[ -f "/etc/kryonix/brain.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "/etc/kryonix/brain.env"
    set +a
  fi
  local role
  role="$(kryonix_brain_role)"
  export KRYONIX_ROLE="${KRYONIX_ROLE:-$role}"
  export KRYONIX_PROJECT_DIR="${KRYONIX_PROJECT_DIR:-/etc/kryonix}"
  export KRYONIX_STATE_ROOT="${KRYONIX_STATE_ROOT:-/var/lib/kryonix}"
  export KRYONIX_BRAIN_ROOT="${KRYONIX_BRAIN_ROOT:-/var/lib/kryonix/brain}"
  export KRYONIX_VAULT_DIR="${KRYONIX_VAULT_DIR:-/var/lib/kryonix/vault}"
  export LIGHTRAG_VAULT_DIR="${LIGHTRAG_VAULT_DIR:-/var/lib/kryonix/vault}"
  export LIGHTRAG_WORKING_DIR="${LIGHTRAG_WORKING_DIR:-/var/lib/kryonix/brain/storage}"
  export KRYONIX_BRAIN_STORAGE="${KRYONIX_BRAIN_STORAGE:-/var/lib/kryonix/brain/storage}"
  export LIGHTRAG_CAG_DIR="${LIGHTRAG_CAG_DIR:-/var/lib/kryonix/brain/cag}"
  export KRYONIX_CAG_DIR="${KRYONIX_CAG_DIR:-/var/lib/kryonix/brain/cag}"
  export KRYONIX_RAG_MANIFEST_DIR="${KRYONIX_RAG_MANIFEST_DIR:-/var/lib/kryonix/brain/rag/manifests}"
  export LD_LIBRARY_PATH="${runtimeLibPath}:${LD_LIBRARY_PATH:-}"
}

run_brain_cli() {
  local project_dir
  project_dir="$(brain_project_dir)" || return 1

  if [[ "$(kryonix_brain_role)" == "client" ]] && [[ "${KRYONIX_LOCAL_RAG_ENABLE:-}" != "true" ]]; then
    printf 'ERRO: O RAG local está desabilitado por padrão no cliente (Inspiron) para evitar duplicação de índices pesados.\n' >&2
    printf 'Para forçar a execução local, defina a variável: export KRYONIX_LOCAL_RAG_ENABLE=true\n' >&2
    return 1
  fi

  export_brain_env
  run_command uv run --project "$project_dir" python -m kryonix_brain_lightrag.cli "$@"
}

run_brain_rust_tool() {
  local tool_name="$1"
  shift
  local project_dir
  project_dir="$(brain_project_dir)" || return 1
  local bin_path="$project_dir/rust-core/target/debug/$tool_name"

  if [[ -x "$bin_path" ]]; then
    export LD_LIBRARY_PATH="${runtimeLibPath}:${LD_LIBRARY_PATH:-}"
    "$bin_path" "$@"
  else
    printf 'ERRO: Ferramenta Rust %s não encontrada ou não compilada.\n' "$tool_name" >&2
    printf 'Tente: nix-shell %s/shell.nix --run "cargo build --manifest-path %s/rust-core/Cargo.toml"\n' "$project_dir" "$project_dir" >&2
    return 1
  fi
}

run_brain_module() {
  local module project_dir
  module="$1"
  shift
  project_dir="$(brain_project_dir)" || return 1

  if [[ "$(kryonix_brain_role)" == "client" ]] && [[ "${KRYONIX_LOCAL_RAG_ENABLE:-}" != "true" ]]; then
    printf 'ERRO: Execução local do cérebro desabilitada no cliente (Inspiron).\n' >&2
    printf 'Para forçar a execução local, defina: export KRYONIX_LOCAL_RAG_ENABLE=true\n' >&2
    return 1
  fi

  export_brain_env
  run_command uv run --project "$project_dir" python -m "$module" "$@"
}

brain_api_url() {
  local url
  url="${KRYONIX_REMOTE_BRAIN_URL:-${KRYONIX_BRAIN_URL:-${KRYONIX_BRAIN_API:-}}}"
  if [[ -z "$url" ]] && [[ "$(kryonix_brain_role)" == "client" ]]; then
    url="http://glacier-publico:8000"
  fi
  printf '%s\n' "${url%/}"
}

brain_remote_required() {
  if [[ -z "$(brain_api_url)" ]]; then
    printf '%s\n' "Brain remoto não configurado. Defina KRYONIX_BRAIN_API." >&2
    return 2
  fi
}

brain_should_use_remote() {
  local mode="$1"

  case "$mode" in
    remote)
      return 0
      ;;
    local)
      return 1
      ;;
  esac

  if [[ "${KRYONIX_BRAIN_MODE:-}" == "remote" ]] || [[ "${KRYONIX_ROLE:-}" == "client" ]]; then
    return 0
  fi

  [[ -n "$(brain_api_url)" ]] && return 0
  [[ "$(kryonix_brain_role)" == "client" ]]
}

brain_remote_curl() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local url
  local status
  local -a curl_args
  local api_key

  export_brain_env
  brain_remote_required || return $?
  url="$(brain_api_url)"
  api_key="${KRYONIX_BRAIN_API_KEY:-${KRYONIX_BRAIN_KEY:-}}"

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

  blue_line "Brain remoto: $method $url$path" >&2

  local tmp_resp http_code
  tmp_resp=$(mktemp)

  http_code=$(curl -sS -w "%{http_code}" -o "$tmp_resp" "${curl_args[@]}" "$url$path")
  status=$?

  if [[ $status -ne 0 ]]; then
    printf 'ERRO: Falha ao conectar ao servidor remoto (%s)\n' "$status" >&2
    rm -f "$tmp_resp"
    return "$status"
  fi

  if [[ "$http_code" == "403" ]]; then
    if [[ -z "$api_key" ]]; then
      printf 'ERRO: endpoint remoto protegido. Defina KRYONIX_BRAIN_API_KEY.\n' >&2
    else
      printf 'ERRO: endpoint remoto protegido. A chave fornecida em KRYONIX_BRAIN_API_KEY é inválida ou expirou.\n' >&2
    fi
    rm -f "$tmp_resp"
    return 1
  elif [[ "$http_code" -ge 400 ]]; then
    printf 'ERRO: O servidor remoto retornou status HTTP %s.\n' "$http_code" >&2
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

parse_brain_mode() {
  brain_mode="auto"
  brain_passthrough=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local)
        brain_mode="local"
        ;;
      --remote)
        brain_mode="remote"
        ;;
      *)
        brain_passthrough+=("$1")
        ;;
    esac
    shift
  done
}

kryonix_brain_health() {
  parse_brain_mode "$@"
  if brain_should_use_remote "$brain_mode"; then
    if [[ "${KRYONIX_JSON_MODE:-}" == "1" ]]; then
      brain_remote_curl GET /health
      return $?
    else
      printf 'Brain remoto: GET %s/health\n' "$(brain_api_url)"
      brain_remote_curl GET /health
      return $?
    fi
  fi

  if [[ "$(kryonix_brain_role)" == "client" ]] && [[ "${KRYONIX_LOCAL_RAG_ENABLE:-}" != "true" ]]; then
    if [[ "${KRYONIX_JSON_MODE:-}" == "1" ]]; then
      printf '{"status": "LOCAL_DISABLED", "role": "client", "note": "RAG local desabilitado"}\n'
    else
      printf 'Kryonix Brain health (Local)\n'
      printf '  role:    client\n'
      printf '  status:  LOCAL_DISABLED\n'
      printf '  nota:    RAG local desabilitado para evitar duplicação do índice pesado.\n'
      printf '           Use --remote para consultar o Glacier, ou export KRYONIX_LOCAL_RAG_ENABLE=true para habilitar local.\n'
    fi
    return 0
  fi

  local project_dir
  project_dir="$(brain_project_dir)" || return 1
  export_brain_env

  run_command uv run --project "$project_dir" python -c "
import json
import os
from kryonix_brain_lightrag import config

health = {
    \"status\": \"OK\",
    \"project_dir\": str(config.PROJECT_DIR),
    \"vault_dir\": str(config.VAULT_DIR),
    \"working_dir\": str(config.WORKING_DIR),
    \"role\": os.environ.get(\"KRYONIX_ROLE\", \"server\")
}

if os.environ.get(\"KRYONIX_JSON_MODE\") == \"1\":
    print(json.dumps(health))
else:
    print(\"Kryonix Brain health (Local)\")
    print(f\"  project: {health['project_dir']}\")
    print(f\"  vault:   {health['vault_dir']}\")
    print(f\"  storage: {health['working_dir']}\")
    print(f\"  role:    {health['role']}\")
    print(f\"  status:  {health['status']}\")
"
}

kryonix_brain_doctor() {
  parse_brain_mode "$@"
  if brain_should_use_remote "$brain_mode"; then
    brain_remote_required || return $?
    if ! brain_remote_curl GET /health; then
      blue_line "WARN: Brain remoto indisponível; runtime depende do Glacier."
      return 0
    fi
    if ! brain_remote_curl GET /stats; then
      blue_line "WARN: Brain remoto respondeu health, mas stats falhou; runtime depende do Glacier."
      return 0
    fi
    return 0
  fi

  run_brain_cli doctor "${brain_passthrough[@]}"
}

kryonix_brain_stats() {
  parse_brain_mode "$@"
  if brain_should_use_remote "$brain_mode"; then
    if [[ "${KRYONIX_JSON_MODE:-}" == "1" ]]; then
      brain_remote_curl GET /stats
      return $?
    else
      local response
      response="$(brain_remote_curl GET /stats)" || return $?
      local project_dir
      project_dir="$(brain_project_dir)" || return 1
      printf '%s' "$response" | uv run --project "$project_dir" python -c '
import sys, json
from rich.console import Console
from rich.table import Table

try:
    data = json.load(sys.stdin)
except Exception:
    print("Erro ao decodificar a resposta remota.")
    sys.exit(1)

console = Console()
console.print("\n[bold magenta][/bold magenta][black on magenta]BRAIN REMOTE STATS[/black on magenta][bold magenta][/bold magenta]")
t = Table(show_header=True, header_style="bold magenta")
t.add_column("Métrica", style="cyan")
t.add_column("Contagem", style="green")
t.add_column("Detalhe / Status", style="dim")

t.add_row("Entidades", str(data.get("entities", 0)), "Mapeadas no Grafo")
t.add_row("Relações", str(data.get("relations", 0)), "Conexões semânticas")
t.add_row("Documentos", str(data.get("docs", 0)), "Arquivos indexados")
t.add_row("Consistência", str(data.get("consistency_status", "OK")), "Status do RAG")
t.add_row("Diretório Remoto", str(data.get("working_dir", "N/A")), "Storage no Glacier")

console.print(t)
'
      return $?
    fi
  fi

  run_brain_cli stats "${brain_passthrough[@]}"
}

kryonix_brain_vault_scan() {
  local vault_dir
  vault_dir="/home/rocha/.local/share/kryonix/kryonix-vault/vault"

  # Tenta rodar a ferramenta Rust se compilada
  if [[ -x "$(brain_project_dir)/rust-core/target/debug/kryonix-vault-scan" ]]; then
    run_brain_rust_tool kryonix-vault-scan "$vault_dir" "$@"
  else
    # Fallback para Python
    run_brain_cli vault scan "$@"
  fi
}

kryonix_brain_search() {
  local action="$1"
  local query
  local payload

  shift
  parse_brain_mode "$@"
  if brain_should_use_remote "$brain_mode"; then
    if [[ "${#brain_passthrough[@]}" -eq 0 ]]; then
      printf 'Uso: kryonix brain %s "pergunta"\n' "$action" >&2
      return 2
    fi
    query="${brain_passthrough[*]}"
    payload="$(jq -n --arg query "$query" --arg mode "hybrid" --arg lang "pt-BR" '{query:$query, mode:$mode, lang:$lang}')"

    if [[ "${KRYONIX_JSON_MODE:-}" == "1" ]]; then
      brain_remote_curl POST /search "$payload"
      return $?
    else
      local response
      response="$(brain_remote_curl POST /search "$payload")" || return $?
      local project_dir
      project_dir="$(brain_project_dir)" || return 1
      printf '%s' "$response" | uv run --project "$project_dir" python -c '
import sys, json
from rich.console import Console
from rich.markdown import Markdown
from rich.panel import Panel

try:
    data = json.load(sys.stdin)
except Exception:
    print("Erro ao decodificar a resposta remota.")
    sys.exit(1)

if data.get("status") == "success":
    console = Console()
    answer = data.get("answer", "")
    sources = data.get("sources", [])
    grounding = data.get("grounding", {})
    confidence = grounding.get("confidence", "Normal")
    latency = grounding.get("latency_sec", 0.0)

    console.print(f"\n[bold magenta][/bold magenta][black on magenta]BRAIN REMOTE RESPONSE[/black on magenta][bold magenta][/bold magenta] [dim]Grounding: {confidence} ({latency}s)[/dim]")
    console.print(Panel(Markdown(answer), border_style="magenta", title="[bold magenta]Kryonix RAG (Remote)[/bold magenta]", title_align="left"))

    if sources:
        console.print("\n[bold cyan]Fontes usadas (Glacier RAG):[/bold cyan]")
        for i, src in enumerate(sources[:5]):
            title = src.get("file") or src.get("title") or src.get("path") or "fonte desconhecida"
            score = src.get("score", "n/a")
            mode_used = src.get("mode") or "hybrid"
            console.print(f"  {i+1}. [bold white]{title}[/bold white] | score: {score} | modo: {mode_used}")
else:
    print(data.get("answer", "Erro desconhecido"))
'
      return $?
    fi
  fi

  run_brain_cli "$action" "${brain_passthrough[@]}"
}

kryonix_graph_stats() {
  parse_brain_mode "$@"
  if brain_should_use_remote "$brain_mode"; then
    if [[ -z "$(brain_api_url)" ]]; then
      blue_line "WARN: Graph local existe no Glacier. Defina KRYONIX_BRAIN_API ou rode kryonix graph stats --local no servidor."
      return 0
    fi
    if ! brain_remote_curl GET /stats; then
      blue_line "WARN: Graph remoto indisponível; runtime depende do Glacier."
    fi
    return 0
  fi

  run_brain_cli stats "${brain_passthrough[@]}"
}

kryonix_graph_top() {
  parse_brain_mode "$@"
  if brain_should_use_remote "$brain_mode"; then
    blue_line "WARN: graph top remoto ainda não possui endpoint público; rode no Glacier com kryonix graph top --local --limit 10."
    return 0
  fi

  graph_limit="$(graph_top_args "${brain_passthrough[@]}")"
  run_brain_cli top "$graph_limit"
}

kryonix_graph_server_only() {
  local action="$1"
  shift

  parse_brain_mode "$@"
  if brain_should_use_remote "$brain_mode"; then
    printf '%s\n' "kryonix graph $action é operação local do Glacier. Use --local no servidor." >&2
    return 2
  fi

  case "$action" in
    heal)
      run_brain_cli graph heal "${brain_passthrough[@]}"
      ;;
    repair)
      run_brain_cli repair-graph "${brain_passthrough[@]}"
      ;;
  esac
}

mcp_config_file() {
  local repo_root

  repo_root="$(kryonix_repo_root)" || return 1
  if [[ -f "$repo_root/.mcp.json" ]]; then
    printf '%s\n' "$repo_root/.mcp.json"
  elif [[ -f "$repo_root/.mcp.example.json" ]]; then
    printf '%s\n' "$repo_root/.mcp.example.json"
  else
    printf '%s\n' "kryonix: .mcp.json ou .mcp.example.json não encontrado em $repo_root." >&2
    return 1
  fi
}

print_mcp_config() {
  local config_file

  config_file="$(mcp_config_file)" || return 1
  if [[ "$(basename "$config_file")" == ".mcp.example.json" ]]; then
    blue_line "Usando .mcp.example.json; copie para .mcp.json para configurar a instância local."
  fi

  jq '
    def mask:
      if type == "object" then
        with_entries(
          if (.key | test("(?i)(token|key|secret|password)")) then
            .value = "<redacted>"
          else
            .value |= mask
          end
        )
      elif type == "array" then
        map(mask)
      else
        .
      end;
    .mcpServers | mask
  ' "$config_file"
}

kryonix_mcp_check() {
  run_brain_cli mcp-check "$@"
}

kryonix_mcp_doctor() {
  local repo_root

  repo_root="$(kryonix_repo_root)" || return 1
  kryonix_mcp_check "$@"
  if [[ -x "$repo_root/scripts/check-mcp.sh" ]]; then
    (
      cd "$repo_root"
      KRYONIX_BIN="$0" bash scripts/check-mcp.sh
    )
  else
    printf '%s\n' "kryonix: scripts/check-mcp.sh não encontrado ou não executável." >&2
    return 1
  fi
}

graph_top_args() {
  local limit="10"
  local parsed=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit)
        if [[ $# -lt 2 ]]; then
          printf '%s\n' "kryonix graph top: --limit requer valor." >&2
          return 2
        fi
        limit="$2"
        shift
        ;;
      --limit=*)
        limit="${1#--limit=}"
        ;;
      *)
        parsed+=("$1")
        ;;
    esac
    shift
  done

  if [[ "${#parsed[@]}" -gt 0 && "${parsed[0]}" =~ ^[0-9]+$ ]]; then
    limit="${parsed[0]}"
  fi

  printf '%s\n' "$limit"
}

kryonix_brain_cag() {
  local sub_action="${1:-}"
  shift || true

  # Parse --local or --remote
  parse_brain_mode "$@"
  
  if brain_should_use_remote "$brain_mode"; then
    if [[ -z "$sub_action" ]]; then
      sub_action="status"
    fi

    case "$sub_action" in
      status)
        if [[ "${KRYONIX_JSON_MODE:-}" == "1" ]]; then
          brain_remote_curl GET /cag/status
          return $?
        else
          local response
          response="$(brain_remote_curl GET /cag/status)" || return $?
          local project_dir
          project_dir="$(brain_project_dir)" || return 1
          printf '%s' "$response" | uv run --project "$project_dir" python -c '
import sys, json
from rich.console import Console

try:
    data = json.load(sys.stdin)
except Exception:
    print("Erro ao decodificar a resposta remota.")
    sys.exit(1)

console = Console()
console.print("\n[bold green][/bold green][black on green]CAG REMOTE STATUS[/black on green][bold green][/bold green]")
if data.get("status") == "success" or "num_files" in data:
    console.print(f"  [cyan]Status:[/cyan]      [bold green]Ativo[/bold green]")
    console.print(f"  [cyan]Ficheiros:[/cyan]   {data.get(\"num_files\", 0)}")
    console.print(f"  [cyan]Tamanho:[/cyan]     {data.get(\"size_bytes\", 0)} bytes")
    console.print(f"  [cyan]Gerado em:[/cyan]   {data.get(\"created_at\", \"n/a\")}")
else:
    console.print(f"  [cyan]Status:[/cyan]      [bold red]Inativo / Não Encontrado[/bold red]")
    console.print("[dim]Use \"kryonix brain cag build\" no servidor para inicializar o CAG.[/dim]")
'
          return $?
        fi
        ;;
      ask|route)
        if [[ "${#brain_passthrough[@]}" -eq 0 ]]; then
          printf 'Uso: kryonix brain cag %s "pergunta"\n' "$sub_action" >&2
          return 2
        fi
        local query="${brain_passthrough[*]}"
        local payload
        payload="$(jq -n --arg query "$query" --argjson top_k 5 '{query:$query, top_k:$top_k}')"

        if [[ "${KRYONIX_JSON_MODE:-}" == "1" ]]; then
          brain_remote_curl POST "/cag/$sub_action" "$payload"
          return $?
        else
          local response
          response="$(brain_remote_curl POST "/cag/$sub_action" "$payload")" || return $?
          local project_dir
          project_dir="$(brain_project_dir)" || return 1
          printf '%s' "$response" | uv run --project "$project_dir" python -c '
import sys, json
from rich.console import Console
from rich.markdown import Markdown
from rich.panel import Panel
from rich.table import Table

try:
    data = json.load(sys.stdin)
except Exception:
    print("Erro ao decodificar a resposta remota.")
    sys.exit(1)

console = Console()
if "answer" in data:
    console.print("\n[bold green][/bold green][black on green]CAG REMOTE ASK[/black on green][bold green][/bold green]")
    console.print(Panel(Markdown(data["answer"]), border_style="green", title="[bold green]Kryonix CAG (Remote)[/bold green]", title_align="left"))
    
    sources = data.get("sources", [])
    if sources:
        console.print("\n[bold cyan]Ficheiros usados:[/bold cyan]")
        for i, src in enumerate(sources):
            console.print(f"  {i+1}. [bold white]{src}[/bold white]")
elif "files" in data:
    console.print("\n[bold green][/bold green][black on green]CAG REMOTE ROUTING[/black on green][bold green][/bold green]")
    t = Table(show_header=True, header_style="bold green")
    t.add_column("Ficheiro", style="cyan")
    t.add_column("Score", justify="right", style="green")
    
    for f in data.get("files", []):
        t.add_row(f.get("path", "n/a"), f"{f.get(\"score\", 0.0):.3f}")
    console.print(t)
else:
    print(json.dumps(data, indent=2))
'
          return $?
        fi
        ;;
      build|clear-cache)
        printf 'ERRO: O subcomando "cag %s" modifica arquivos no servidor e deve ser executado localmente no Glacier.\n' "$sub_action" >&2
        printf 'Execute: ssh glacier e rode: kryonix brain cag %s\n' "$sub_action" >&2
        return 1
        ;;
      *)
        printf 'Subcomando CAG desconhecido: %s\n' "$sub_action" >&2
        printf 'Subcomandos válidos: status, ask, route, build, clear-cache\n' >&2
        return 1
        ;;
    esac
  else
    run_brain_cli cag "$sub_action" "${brain_passthrough[@]}"
  fi
}


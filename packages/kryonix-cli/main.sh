print_usage() {
  kryonix_banner

  header_line "Uso"
  blue_line "  kryonix <comando> [opcoes] [-- args extras]"

  header_line "Operacao do Sistema"
  blue_line "  switch      Aplica a configuracao (switch [all] inclui Home)"
  blue_line "  boot        Gera e registra a proxima geracao (nh os boot)"
  blue_line "  test        Testa a geracao NixOS ou perfis (client/server/MCP)"
  blue_line "  rebuild     Builda o toplevel sem ativar"
  blue_line "  diff        Compara sistema atual com o proximo build"
  blue_line "  update      Atualiza os inputs da flake (flake.lock)"
  blue_line "  clean       Limpa geracoes antigas (nh clean all)"

  header_line "Kryonix Home Brain"
  blue_line "  home        Scanner e auditor da Home (scan, report, duplicates, plan)"

  header_line "Kryonix AI Brain & Graph"
  blue_line "  brain       Acessa o Brain (health, stats, search, ask, cag, api-key)"
  blue_line "  graph       Opera o grafo (status, query, ingest, doctor, stats)"
  blue_line "  vault       Opera o vault (scan, index)"
  blue_line "  ollama      Gerencia o serviço Ollama (status, run, vram, pull)"
  blue_line "  ai          Camada de interacao IA (continue, checkpoint)"

  header_line "Infraestrutura & Git"
  blue_line "  sync        Pull + Validacao + Deploy completo"
  blue_line "  deploy      Aplica o estado do checkout local no host"
  blue_line "  pull        Git fetch + Pull rebase (/etc/kryonix)"
  blue_line "  git-status  Status detalhado do repositorio Kryonix"
  blue_line "  doctor      Diagnostico de integridade do sistema"
  blue_line "  check       Validacao estrutural (nix flake check)"

  header_line "Recursos & Ferramentas"
  blue_line "  remote      Acesso remoto e tunelamento (vnc, tunnel)"
  blue_line "  rgb         Controle de iluminação (OpenRGB)"
  blue_line "  vm          Gestao de maquinas virtuais (libvirt)"
  blue_line "  iso         Geração de midia de instalação Kryonix"
  blue_line "  fmt         Formatador de código Nix"
  blue_line "  repl        Nix REPL no contexto da flake"

  header_line "Opcoes Globais"
  blue_line "  --host <h>  Forca o host alvo (ex: glacier)"
  blue_line "  --user <u>  Usuário para operações na Home"
  blue_line "  --flake <p> Caminho da flake personalizada"
  blue_line "  --update    Forca atualizacao de inputs"
  blue_line "  --dry       Simulação de execucao (Dry-run)"
  blue_line "  --verbose   Log detalhado e debug"

  printf '\n'
  magenta_line "Dica: Use 'kryonix <comando> --help' para detalhes especificos."
}

show_command_usage() {
  local target_cmd="$1"
  case "$target_cmd" in
    switch|boot)
      header_line "Ajuda: kryonix $target_cmd"
      magenta_line "Aplica ou registra a configuracao do host atual ou de um host específico."
      printf '\n'
      blue_line "Uso:"
      blue_line "  kryonix $target_cmd [host] [all] [opcoes]"
      printf '\n'
      blue_line "Argumentos:"
      blue_line "  host      Nome do host alvo (ex: inspiron, glacier)"
      blue_line "  all       Aplica também a configuracao do Home Manager"
      printf '\n'
      blue_line "Opcoes:"
      blue_line "  --update  Atualiza os inputs da flake antes de aplicar"
      blue_line "  --dry     Simula a operação sem realizar mudanças"
      blue_line "  --verbose Mostra logs detalhados do build"
      printf '\n'
      blue_line "Exemplos:"
      blue_line "  kryonix $target_cmd all"
      blue_line "  kryonix $target_cmd glacier --update"
      ;;
    home)
      header_line "Ajuda: kryonix home"
      magenta_line "Scanner determinístico e organizador inteligente da Home (Home Brain)."
      printf '\n'
      blue_line "Subcomandos:"
      blue_line "  scan        Escaneia a Home e gera um snapshot JSON"
      blue_line "  report      Exibe o relatório do último escaneamento"
      blue_line "  duplicates  Lista arquivos com conteúdo SHA256 idêntico"
      blue_line "  plan        Gera um plano de organização sugerido (dry-run)"
      printf '\n'
      blue_line "Opcoes:"
      blue_line "  --user <user>  Especifica o usuario (default: rocha)"
      printf '\n'
      blue_line "Exemplos:"
      blue_line "  kryonix home scan"
      blue_line "  kryonix home duplicates"
      ;;
    brain)
      header_line "Ajuda: kryonix brain"
      magenta_line "Interface de interacao com o Kryonix AI Brain (RAG & Knowledge)."
      printf '\n'
      blue_line "Subcomandos:"
      blue_line "  health      Verifica a saude e conectividade da API"
      blue_line "  stats       Estatisticas de entidades, relacoes e documentos"
      blue_line "  search      Busca semantica fundamentada no grafo (RAG)"
      blue_line "  ask         Pergunta direta ao cerebro"
      blue_line "  cag         Opera o Context-Aware Graph (status, build, query)"
      blue_line "  api-key     Gestao da chave de acesso (status, generate, rotate)"
      blue_line "  doctor      Diagnostico completo do ambiente de IA"
      blue_line "  remote      Configura o endereco do servidor remoto"
      printf '\n'
      blue_line "Opcoes:"
      blue_line "  --remote    Forca consulta ao servidor (Glacier)"
      blue_line "  --local     Forca execucao no host local (se disponivel)"
      printf '\n'
      blue_line "Exemplos:"
      blue_line "  kryonix brain search \"Como funciona o pipeline RAG?\""
      blue_line "  kryonix brain stats --remote"
      ;;
    graph)
      header_line "Ajuda: kryonix graph"
      magenta_line "Operações estruturais no grafo de conhecimento técnico."
      printf '\n'
      blue_line "Subcomandos:"
      blue_line "  status      Estado da base de dados e conectividade"
      blue_line "  schema      Visualiza o esquema de nós e relacoes"
      blue_line "  query       Executa consultas Cypher (read-only)"
      blue_line "  ingest      Processa manifestos para o grafo (--dry-run, --apply)"
      blue_line "  stats       Métricas detalhadas de entidades"
      blue_line "  top         Nós com maior centralidade no grafo"
      blue_line "  doctor      Verifica inconsistências estruturais"
      blue_line "  repair      Repara o grafo em caso de corrupção (Server-only)"
      printf '\n'
      blue_line "Exemplos:"
      blue_line "  kryonix graph query --cypher \"MATCH (n:Host) RETURN n LIMIT 5\""
      blue_line "  kryonix graph ingest --dry-run"
      ;;
    test)
      header_line "Ajuda: kryonix test"
      magenta_line "Conjunto de testes de validacao para o ecossistema Kryonix."
      printf '\n'
      blue_line "Alvos:"
      blue_line "  all         Roda todos os testes disponiveis"
      blue_line "  client      Valida o perfil Inspiron/Workstation"
      blue_line "  server      Valida o perfil Glacier/Server"
      blue_line "  mcp         Valida a configuracao e servidores MCP"
      blue_line "  brain       Valida a integracao com o Brain API"
      printf '\n'
      blue_line "Exemplos:"
      blue_line "  kryonix test all"
      blue_line "  kryonix test mcp"
      ;;
    mcp)
      header_line "Ajuda: kryonix mcp"
      magenta_line "Gerenciamento de servidores e clientes MCP (Model Context Protocol)."
      printf '\n'
      blue_line "Subcomandos:"
      blue_line "  check       Valida se os servidores respondem corretamente"
      blue_line "  doctor      Diagnostico de configuracao e dependencias"
      blue_line "  list        Lista servidores ativos e capacidades"
      blue_line "  logs        Exibe logs de erro dos servidores"
      printf '\n'
      blue_line "Exemplos:"
      blue_line "  kryonix mcp check"
      blue_line "  kryonix mcp doctor"
      ;;
    vault)
      header_line "Ajuda: kryonix vault"
      magenta_line "Operacoes no vault de conhecimento (Obsidian)."
      printf '\n'
      blue_line "Subcomandos:"
      blue_line "  scan        Detecta novas notas e mudancas estruturais"
      blue_line "  index       Forca a reindexacao no LightRAG"
      blue_line "  stats       Metricas de tamanho e cobertura do vault"
      printf '\n'
      blue_line "Exemplos:"
      blue_line "  kryonix vault scan"
      blue_line "  kryonix vault stats"
      ;;
    ollama)
      header_line "Ajuda: kryonix ollama"
      magenta_line "Interface de controle para o backend Ollama (Server-only)."
      printf '\n'
      blue_line "Subcomandos:"
      blue_line "  status      Estado do serviço e GPU/VRAM"
      blue_line "  run         Executa um modelo interativamente"
      blue_line "  pull        Baixa um novo modelo"
      blue_line "  vram        Exibe uso de VRAM em tempo real"
      blue_line "  list        Modelos instalados localmente"
      printf '\n'
      blue_line "Exemplos:"
      blue_line "  kryonix ollama status"
      blue_line "  kryonix ollama run deepseek-coder:6.7b"
      ;;
    *)
      # Fallback para o help global se não houver um focado
      print_usage
      ;;
  esac
}

# --- Inicialização ---
init_colors

# --- Parsing de Argumentos ---
subcommand="${1:-}"
if [[ -n "$subcommand" ]]; then
  shift
fi

host_arg=""
user_arg="rocha"
flake_arg=""
verbose=0
json_mode=0
dry=0
update=0
extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update|-u)
      update=1
      ;;
    --no-update)
      update=0
      ;;
    --verbose|-v)
      verbose=$((verbose + 1))
      ;;
    --json)
      json_mode=1
      export KRYONIX_JSON_MODE=1
      extra_args+=("$1")
      ;;
    --dry|-n)
      dry=1
      ;;
    --host|-H)
      if [[ $# -lt 2 ]]; then
        printf '%s\n' 'kryonix: --host requer um valor.' >&2
        exit 2
      fi
      host_arg="$2"
      shift
      ;;
    --user)
      if [[ $# -lt 2 ]]; then
        printf '%s\n' 'kryonix: --user requer um valor.' >&2
        exit 2
      fi
      user_arg="$2"
      shift
      ;;
    --flake)
      if [[ $# -lt 2 ]]; then
        printf '%s\n' 'kryonix: --flake requer um valor.' >&2
        exit 2
      fi
      flake_arg="$2"
      shift
      ;;
    --help|-h)
      if [[ -n "$subcommand" ]]; then
        extra_args+=("$1")
      else
        print_usage
        exit 0
      fi
      ;;
    --)
      shift
      extra_args+=("$@")
      break
      ;;
    *)
      if [[ "$1" == ".#"* ]] || [[ "$1" == ". #"* ]]; then
        printf 'ERRO: Sintaxe ".#host" ou ". #host" não permitida.\n' >&2
        printf 'Use: kryonix %s --host <host>\n' "$subcommand" >&2
        exit 1
      fi

      if [[ "$subcommand" == "test" ]] && is_kryonix_test_target "$1"; then
        extra_args+=("$1")
      elif accepts_positional_host && [[ -z "$host_arg" && "$1" != -* ]]; then
        if [[ "$subcommand" == "home" ]] && [[ "$1" == "scan" || "$1" == "report" || "$1" == "duplicates" || "$1" == "plan" ]]; then
          extra_args+=("$1")
        elif [[ "$subcommand" == "switch" || "$subcommand" == "boot" ]] && [[ "$1" == "all" ]]; then
          extra_args+=("$1")
        else
          host_arg="$1"
        fi
      else
        extra_args+=("$1")
      fi
      ;;
  esac
  shift
done

if [[ "$subcommand" == "test" ]] && [[ "$EUID" -eq 0 ]]; then
   printf 'ERRO: "kryonix test" não deve ser executado com sudo.\n' >&2
   exit 1
fi

flake_host="${host_arg:-$(map_runtime_host)}"

case "$subcommand" in
  help|--help|-h|"")
    print_usage
    exit 0
    ;;

  clean|vm|git-status|pull|deploy|sync|brain|graph|mcp|vault|rgb|ollama|ai|remote)
    needs_flake=0
    ;;

  test)
    if is_kryonix_test_target "${extra_args[0]:-}"; then
      needs_flake=0
    else
      needs_flake=1
    fi
    ;;

  home)
    if [[ "${#extra_args[@]}" -gt 0 ]] && [[ "${extra_args[0]}" == "scan" || "${extra_args[0]}" == "report" || "${extra_args[0]}" == "duplicates" || "${extra_args[0]}" == "plan" ]]; then
      needs_flake=0
    else
      needs_flake=1
    fi
    ;;

  *)
    needs_flake=1
    ;;
esac

if (( needs_flake )); then
  resolve_flake "$flake_arg"
else
  flake_mode="none"
  flake_root=""
  flake_workdir=""
  flake_ref=""
fi

home_target="${user_arg}@${flake_host}"
verbose_args=()
dry_args=()

verbose_count="$verbose"
while (( verbose_count > 0 )); do
  verbose_args+=("-v")
  verbose_count=$((verbose_count - 1))
done

if (( needs_flake )); then
  print_flake_resolution
fi

if (( dry )); then
  dry_args+=("--dry")
fi

case "$subcommand" in
  switch|boot)
    if [[ "${extra_args[0]:-}" == "--help" || "${extra_args[0]:-}" == "-h" ]]; then
       show_command_usage "$subcommand"
       exit 0
    fi

    target_all=0
    if [[ "${extra_args[0]:-}" == "all" ]]; then
       target_all=1
       extra_args=("${extra_args[@]:1}")
    fi

    update_flake_if_requested

    # NixOS switch/boot
    cmd=(nh os "$subcommand" "$flake_ref" -H "$flake_host")
    cmd+=("${verbose_args[@]}" "${dry_args[@]}")
    if [[ "${#extra_args[@]}" -gt 0 ]]; then
      cmd+=("--" "${extra_args[@]}")
    fi
    run_flake_command "${cmd[@]}" || exit $?

    if (( target_all )); then
       blue_line "Aplicando Home Manager para $home_target..."
       cmd=(nh home switch "$flake_ref" -c "$home_target")
       cmd+=("${verbose_args[@]}" "${dry_args[@]}")
       run_flake_command "${cmd[@]}"
    fi
    ;;

  test)
    if [[ "${extra_args[0]:-}" == "--help" || "${extra_args[0]:-}" == "-h" ]]; then
       show_command_usage test
       exit 0
    fi

    if is_kryonix_test_target "${extra_args[0]:-}"; then
      run_kryonix_test_target "${extra_args[0]}"
    else
      update_flake_if_requested
      cmd=(nh os test "$flake_ref" -H "$flake_host")
      cmd+=("${verbose_args[@]}" "${dry_args[@]}")
      if [[ "${#extra_args[@]}" -gt 0 ]]; then
        cmd+=("--" "${extra_args[@]}")
      fi
      run_flake_command "${cmd[@]}"
    fi
    ;;

  home)
    if [[ "${extra_args[0]:-}" == "--help" || "${extra_args[0]:-}" == "-h" ]]; then
       show_command_usage home
       exit 0
    fi

    # Verifica se o primeiro argumento é um dos subcomandos do Rust kryonix-home (Home Brain)
    if [[ "${#extra_args[@]}" -gt 0 ]]; then
      case "${extra_args[0]}" in
        scan|report|duplicates|plan|help|--help|-h)
          kryonix_home "${extra_args[@]}"
          exit $?
          ;;
      esac
    fi

    # Comportamento legado: Home Manager switch via nh
    update_flake_if_requested
    cmd=(nh home switch "$flake_ref" -c "$home_target")
    cmd+=("${verbose_args[@]}" "${dry_args[@]}")
    if [[ "${#extra_args[@]}" -gt 0 ]]; then
      cmd+=("--" "${extra_args[@]}")
    fi
    run_flake_command "${cmd[@]}"
    ;;

  rebuild)
    update_flake_if_requested
    cmd=(nix build "${flake_ref}#nixosConfigurations.${flake_host}.config.system.build.toplevel")
    cmd+=("${verbose_args[@]}" "${extra_args[@]}")
    run_flake_command "${cmd[@]}"
    ;;

  update)
    update_flake_lock 1
    ;;

  clean)
    cmd=(nh clean all "${verbose_args[@]}" "${extra_args[@]}")
    run_command "${cmd[@]}"
    ;;

  diff)
    target_path="$(capture_flake_command nix build --no-link --print-out-paths "${flake_ref}#nixosConfigurations.${flake_host}.config.system.build.toplevel" "${extra_args[@]}")"
    run_command nvd diff /run/current-system "$target_path"
    ;;

  pull)
    kryonix_pull_repo
    ;;

  deploy)
    kryonix_deploy_repo
    ;;

  sync)
    kryonix_sync_repo
    ;;

  repl)
    cmd=(nix repl "$flake_ref" "${extra_args[@]}")
    run_flake_command "${cmd[@]}"
    ;;

  doctor)
    if [[ "${extra_args[0]:-}" == "full" ]]; then
      kryonix_doctor_full
      exit $?
    fi

    blue_line 'Kryonix doctor'
    blue_line "  host atual   : $(current_hostname)"
    blue_line "  modo detectado: $flake_mode"
    blue_line "  flake resolvida: $flake_ref"
    blue_line "  flake host   : $flake_host"
    blue_line "  home target  : $home_target"
    blue_line "  flake root   : $flake_root"
    blue_line "  exec dir     : $flake_workdir"
    blue_line "  user         : $user_arg"

    if [[ -n "$flake_root" && -e "$flake_root/flake.nix" ]]; then
      blue_line '  flake        : ok'
    elif [[ -n "$flake_root" ]]; then
      blue_line "  flake        : ausente em $flake_root"
    else
      blue_line '  flake        : origem remota ou raiz nao local'
    fi

    if mount_info="$(findmnt -no SOURCE,TARGET /srv/ragenterprise 2>/dev/null)"; then
      blue_line "  storage      : $mount_info"
    fi

    if command -v systemctl >/dev/null 2>&1; then
      blue_line "  libvirtd     : $(systemctl is-enabled libvirtd 2>/dev/null || printf 'unknown')"
      blue_line "  tailscaled   : $(systemctl is-active tailscaled 2>/dev/null || printf 'inactive')"
    fi

    brain_url="$(brain_api_url)"
    if [[ -n "$brain_url" ]]; then
      blue_line "  brain url    : $brain_url"
      if curl -s --connect-timeout 2 "$brain_url/health" >/dev/null; then
        blue_line '  brain health : OK'
      else
        blue_line '  brain health : FAIL'
      fi
    elif [[ "$(kryonix_brain_role)" == "client" ]]; then
      blue_line '  brain remoto : WARN: KRYONIX_BRAIN_API ausente'
    fi

    if drv_path="$(capture_flake_command nix eval "${flake_ref}#nixosConfigurations.${flake_host}.config.system.build.toplevel.drvPath" --raw 2>/dev/null)"; then
      blue_line "  toplevel drv : $drv_path"
    else
      blue_line '  toplevel drv : falhou na avaliacao'
    fi
    ;;

  git-status)
    print_kryonix_git_status
    ;;

  vm)
    run_command virsh list --all
    ;;

  iso)
    cmd=(nix build "${flake_ref}#nixosConfigurations.iso.config.system.build.isoImage" "${verbose_args[@]}" "${extra_args[@]}")
    run_flake_command "${cmd[@]}"
    ;;

  fmt)
    cmd=(nix fmt "$flake_ref" "${verbose_args[@]}" "${extra_args[@]}")
    run_flake_command "${cmd[@]}"
    ;;

  check)
    cmd=(nix flake check "$flake_ref" --keep-going "${verbose_args[@]}" "${extra_args[@]}")
    run_flake_command "${cmd[@]}"
    ;;

  rgb)
    kryonix_rgb "${extra_args[@]}"
    ;;

  brain)
    if [[ "${extra_args[0]:-}" == "--help" || "${extra_args[0]:-}" == "-h" ]]; then
       show_command_usage brain
       exit 0
    fi

    if [[ "${#extra_args[@]}" -eq 0 ]]; then
      brain_sub="help"
    else
      brain_sub="${extra_args[0]}"
      extra_args=("${extra_args[@]:1}")
    fi

    case "$brain_sub" in
      health)
        kryonix_brain_health "${extra_args[@]}"
        ;;
      doctor)
        kryonix_brain_doctor "${extra_args[@]}"
        ;;
      stats)
        kryonix_brain_stats "${extra_args[@]}"
        ;;
      vault-scan)
        kryonix_brain_vault_scan "${extra_args[@]}"
        ;;
      search|ask)
        if [[ "${#extra_args[@]}" -eq 0 ]]; then
          printf 'Uso: kryonix brain %s "pergunta" [--explain] [--remote|--local]\n' "$brain_sub" >&2
          exit 2
        fi
        kryonix_brain_search "$brain_sub" "${extra_args[@]}"
        ;;
      storage-check|ollama-check)
        run_brain_cli "$brain_sub" "${extra_args[@]}"
        ;;
      sync|watch|diagnostics|index|export)
        run_brain_cli "$brain_sub" "${extra_args[@]}"
        ;;
      api)
        run_brain_module kryonix_brain_lightrag.api "${extra_args[@]}"
        ;;
      cag)
        kryonix_brain_cag "${extra_args[@]}"
        ;;
      api-key)
        kryonix_brain_api_key "${extra_args[@]}"
        ;;
      remote)
        kryonix_brain_remote "${extra_args[@]}"
        ;;
       *)
         echo "Uso: kryonix brain <health|doctor|stats|vault-scan|search|ask|storage-check|ollama-check|sync|watch|index|export|diagnostics|api|cag|api-key|remote>"
         exit 1
         ;;
    esac
    ;;

  graph)
    if [[ "${extra_args[0]:-}" == "--help" || "${extra_args[0]:-}" == "-h" ]]; then
       show_command_usage graph
       exit 0
    fi

    if [[ "${#extra_args[@]}" -eq 0 ]]; then
      graph_sub="help"
    else
      graph_sub="${extra_args[0]}"
      extra_args=("${extra_args[@]:1}")
    fi

    case "$graph_sub" in
      status)
        kryonix_graph_status "${extra_args[@]}"
        ;;
      schema)
        kryonix_graph_schema "${extra_args[@]}"
        ;;
      ingest)
        kryonix_graph_ingest "${extra_args[@]}"
        ;;
      query)
        if [[ "${#extra_args[@]}" -eq 0 ]]; then
          kryonix_graph_query_usage
          exit 2
        fi
        kryonix_graph_query "${extra_args[@]}"
        ;;
      examples)
        kryonix_graph_examples
        ;;
      doctor)
        kryonix_graph_doctor "${extra_args[@]}"
        ;;
      stats)
        kryonix_graph_stats "${extra_args[@]}"
        ;;
      top)
        kryonix_graph_top "${extra_args[@]}"
        ;;
      heal)
        kryonix_graph_server_only heal "${extra_args[@]}"
        ;;
      repair)
        kryonix_graph_server_only repair "${extra_args[@]}"
        ;;
      *)
        printf 'Uso: kryonix graph <status|schema|ingest|query|examples|doctor|stats|top|heal|repair> [--remote|--local]\n' >&2
        exit 1
        ;;
    esac
    ;;

  mcp)
    if [[ "${extra_args[0]:-}" == "--help" || "${extra_args[0]:-}" == "-h" ]]; then
       show_command_usage mcp
       exit 0
    fi

    if [[ "${#extra_args[@]}" -eq 0 ]]; then
      mcp_sub="print-config"
    else
      mcp_sub="${extra_args[0]}"
      extra_args=("${extra_args[@]:1}")
    fi

    case "$mcp_sub" in
      check)
        kryonix_mcp_check "${extra_args[@]}"
        ;;
      doctor)
        kryonix_mcp_doctor "${extra_args[@]}"
        ;;
      print-config)
        print_mcp_config
        ;;
      *)
        printf 'Usage: kryonix mcp <check|doctor|print-config>\n' >&2
        exit 1
        ;;
    esac
    ;;

  vault)
    if [[ "${extra_args[0]:-}" == "--help" || "${extra_args[0]:-}" == "-h" ]]; then
       show_command_usage vault
       exit 0
    fi

    if [[ "${#extra_args[@]}" -eq 0 ]]; then
      show_command_usage vault
      exit 1
    fi
    vault_sub="${extra_args[0]}"
    extra_args=("${extra_args[@]:1}")

    case "$vault_sub" in
      scan)
        kryonix_brain_vault_scan "${extra_args[@]}"
        ;;
      index|curate|sync-docs)
        run_brain_cli vault "$vault_sub" "${extra_args[@]}"
        ;;
      *)
        printf 'Uso: kryonix vault <scan|index|curate|sync-docs>\n' >&2
        exit 1
        ;;
    esac
    ;;

  ollama)
    if [[ "${extra_args[0]:-}" == "--help" || "${extra_args[0]:-}" == "-h" ]]; then
       show_command_usage ollama
       exit 0
    fi
    kryonix_ollama "${extra_args[@]}"
    ;;

  ai)
    kryonix_ai "${extra_args[@]}"
    ;;

  remote)
    kryonix_remote "${extra_args[@]}"
    ;;

  *)
    printf 'Comando desconhecido: %s\n\n' "$subcommand" >&2
    print_usage >&2
    exit 1
    ;;
esac

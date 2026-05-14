_kryonix_completions() {
  local cur prev words cword
  _get_comp_words_by_ref -n : cur prev words cword

  local commands subcommands flags hosts
  hosts="glacier inspiron inspiron-nina iso"

  # Completa hosts após --host ou -H
  if [[ "$prev" == "--host" || "$prev" == "-H" ]]; then
    COMPREPLY=( $(compgen -W "$hosts" -- "$cur") )
    return 0
  fi

  # Comandos de nível superior
  if [[ "$cword" -eq 1 ]]; then
    commands=$(kryonix commands)
    COMPREPLY=( $(compgen -W "$commands --help --host --flake --update --dry --json" -- "$cur") )
    return 0
  fi

  # Subcomandos e Flags
  local cmd="${words[1]}"
  if [[ "$cword" -eq 2 ]]; then
    if [[ "$cmd" == -* ]]; then
       # Se o primeiro argumento for uma flag, volta a completar comandos ou flags
       commands=$(kryonix commands)
       COMPREPLY=( $(compgen -W "$commands --help --host --flake --update --dry --json" -- "$cur") )
    else
       subcommands=$(kryonix commands --subcommands "$cmd")
       flags=$(kryonix commands --flags "$cmd")
       COMPREPLY=( $(compgen -W "$subcommands $flags --help" -- "$cur") )
    fi
    return 0
  fi

  if [[ "$cword" -eq 3 ]]; then
    local sub="${words[2]}"
    flags=$(kryonix commands --flags "$cmd" "$sub")
    COMPREPLY=( $(compgen -W "$flags --help" -- "$cur") )
    return 0
  fi

  # Fallback para flags globais
  COMPREPLY=( $(compgen -W "--help --host --flake --update --dry --json" -- "$cur") )
}

complete -F _kryonix_completions kryonix

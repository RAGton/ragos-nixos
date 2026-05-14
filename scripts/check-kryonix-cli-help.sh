#!/usr/bin/env bash
set -euo pipefail

# Scripts de validação da Kryonix CLI
# Garante que help, registry e implementação não divergem.

# Garante que estamos na raiz do repo
if [[ ! -f "flake.nix" ]]; then
  echo "ERRO: Este script deve ser executado na raiz do repositório Kryonix." >&2
  exit 1
fi

# 1. Verifica se kryonix --help funciona e não chama runtime remoto
# Mockar URLs para garantir que falhe se houver chamada real bloqueante
export KRYONIX_BRAIN_API="http://invalid-runtime-dependency"
export KRYONIX_JSON_MODE=0

echo "Validando kryonix --help..."
nix run .#kryonix -- --help > /dev/null

echo "Validando kryonix commands --json..."
JSON=$(nix run .#kryonix -- commands --json)
if ! echo "$JSON" | jq . > /dev/null; then
  echo "ERRO: 'kryonix commands --json' não retornou um JSON válido." >&2
  exit 1
fi

# 2. Cross-check: Registry vs Implementação (main.sh)
echo "Validando consistência Registry vs main.sh..."
REG_COMMANDS=$(nix run .#kryonix -- commands)

# Pega os comandos do case statement do main.sh e filtra os conhecidos
IMPL_COMMANDS=$(grep -E '^[[:space:]]+[a-z0-9-]+)\b' packages/kryonix-cli/main.sh | sed 's/^[[:space:]]*//; s/).*//' | grep -vE 'help|--help|__complete|commands|clean|vm|git-status|pull|deploy|sync|brain|graph|mcp|vault|rgb|ollama|ai|remote|install|hardware|disk|test|home|rebuild|update|all|diff|repl|doctor|iso|fmt|check' || true)

# Nota: A lista acima de grep -vE deve conter comandos que EU JÁ SEI que estão no main.sh.
# Na verdade, o ideal é comparar se cada comando do registry está no case do main.sh.

for cmd in $REG_COMMANDS; do
  if ! grep -qE "^[[:space:]]+([^)]*\|)?$cmd(\|[^)]*)?)" packages/kryonix-cli/main.sh; then
     echo "ERRO: Comando '$cmd' está no registry mas não foi encontrado no case principal do main.sh" >&2
     exit 1
  fi
done

echo "Validando ajuda por grupo..."
for group in $(nix run .#kryonix -- commands --groups); do
  # Pega o primeiro comando do grupo para testar help
  cmd=$(echo "$JSON" | jq -r --arg g "$group" '.commands | map(select(.group == $g)) | .[0].name')
  if [[ "$cmd" != "null" ]]; then
    nix run .#kryonix -- "$cmd" --help > /dev/null
  fi
done

echo "✓ Validação de CLI concluída com sucesso."

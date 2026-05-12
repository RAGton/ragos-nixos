#!/usr/bin/env bash
# scripts/validate-home-brain-phase3c.sh
# Validação da Fase 3C do Kryonix Home Brain: Projetos e UX

set -euo pipefail

# Configuração
REPO_ROOT=$(pwd)
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

echo "=== [1/5] Preparando Sandbox em $SANDBOX ==="
mkdir -p "$SANDBOX/Downloads"
mkdir -p "$SANDBOX/Documentos/Projetos"

# 1. Projeto Kryonix (simulado)
mkdir -p "$SANDBOX/Downloads/kryonix-core/.git"
touch "$SANDBOX/Downloads/kryonix-core/flake.nix"
touch "$SANDBOX/Downloads/kryonix-core/README.md"
mkdir -p "$SANDBOX/Downloads/kryonix-core/target"
touch "$SANDBOX/Downloads/kryonix-core/target/binary"

# 2. Projeto Genérico (simulado)
mkdir -p "$SANDBOX/Downloads/meu-projeto-python"
touch "$SANDBOX/Downloads/meu-projeto-python/pyproject.toml"
mkdir -p "$SANDBOX/Downloads/meu-projeto-python/.venv"
touch "$SANDBOX/Downloads/meu-projeto-python/.venv/python"

# 3. Arquivo solto (não projeto)
touch "$SANDBOX/Downloads/documento_importante.pdf"

# Override do HOME para o sandbox
export HOME="$SANDBOX"
mkdir -p "$HOME/.local/state/kryonix/home-brain"

# Navegar para o pacote
cd "$REPO_ROOT/packages/kryonix-home"

echo "=== [2/5] Executando Scan ==="
cargo run -- scan

echo "=== [3/5] Validando Detecção de Projetos ==="
# Deve encontrar 2 projetos
PROJECT_COUNT=$(cargo run -- projects | grep -c "▶")
if [ "$PROJECT_COUNT" -ne 2 ]; then
    echo "❌ Erro: Deveria detectar 2 projetos, detectou $PROJECT_COUNT"
    exit 1
fi
echo "✅ Projetos detectados corretamente."

echo "=== [4/5] Validando Planejamento (Dashboard) ==="
# O dashboard deve mostrar 2 projetos e 1 arquivo
PLAN_SUMMARY=$(cargo run -- plan --summary)
echo "$PLAN_SUMMARY"

if ! echo "$PLAN_SUMMARY" | grep -q "Projetos a mover:   2"; then
    echo "❌ Erro: Dashboard não reportou 2 projetos."
    exit 1
fi
echo "✅ Dashboard reportou 2 projetos corretamente."

echo "=== [5/5] Validando Apply e Rollback de Projetos ==="
# Manifest
cargo run -- manifest create

# Apply
cargo run -- apply --confirm

if [ ! -d "$SANDBOX/Documentos/Projetos/Kryonix/kryonix-core" ]; then
    echo "❌ Erro: Projeto Kryonix não foi movido corretamente."
    exit 1
fi
echo "✅ Apply de projeto funcionou."

# Rollback
cargo run -- rollback

if [ ! -d "$SANDBOX/Downloads/kryonix-core" ]; then
    echo "❌ Erro: Rollback de projeto não funcionou."
    exit 1
fi
echo "✅ Rollback de projeto funcionou."

echo "=== ✨ FASE 3C VALIDADA COM SUCESSO! ==="

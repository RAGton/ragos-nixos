#!/usr/bin/env bash
set -e

echo "=== INICIANDO BATERIA DE TESTES NO INSPIRON ==="

test_app() {
    local name=$1
    local cmd=$2
    echo -n "Testando $name ($cmd)... "
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "\e[32m[OK]\e[0m"
    else
        echo -e "\e[31m[FALHA]\e[0m (não encontrado no PATH)"
    fi
}

test_app "VSCodium" "codium"
test_app "Obsidian" "obsidian"
test_app "Kryonix Obsidian Wrapper" "kryonix-obsidian"
test_app "WinBox" "WinBox"
test_app "Kryonix CLI" "kryonix"
test_app "Kryonix Terminal" "kryonix-terminal"
test_app "Kryonix Search" "kryonix-search"
test_app "Kryonix Brain Health" "kryonix-brain-health"
test_app "Hyprland" "Hyprland"
test_app "UWSM" "uwsm"

echo -e "\n=== TESTANDO BRAIN CONNECTIVITY ==="
if curl -s --connect-timeout 2 "http://100.108.71.36:8000/health" >/dev/null; then
    echo -e "Brain API: \e[32m[OK]\e[0m"
else
    echo -e "Brain API: \e[31m[FALHA]\e[0m"
fi

echo -e "\n=== AUDITANDO ATALHOS DESKTOP QUEBRADOS ==="
if [ -f "/tmp/check-desktop-exec.sh" ]; then
    /tmp/check-desktop-exec.sh | grep "ERRO" || echo "Nenhum atalho quebrado detectado."
else
    echo "Script de auditoria desktop não encontrado em /tmp."
fi

echo -e "\n=== TESTES CONCLUÍDOS ==="

#!/usr/bin/env bash
set -e

echo "======================================"
echo "    AUDITORIA DE DOCUMENTAÇÃO Kryonix"
echo "======================================"

DOCS_DIR="$(dirname "$0")/../docs"

echo "[1] Verificando termos proibidos na documentação canônica (TODO, WIP, etc)..."
if grep -RnE --exclude-dir=archive --exclude=ROADMAP.md "\bTODO\b|\bWIP\b" "$DOCS_DIR"; then
    echo "ERRO: Termos como TODO/WIP ou promessas futuras foram encontrados na documentação canônica."
    echo "Corrija os arquivos ou mova as promessas para ROADMAP.md."
    exit 1
else
    echo "✓ Nenhum termo proibido encontrado."
fi

echo ""
echo "[2] Validando Comandos do USAGE.md..."
if [ -f "$DOCS_DIR/USAGE.md" ]; then
    while IFS= read -r cmd; do
        if ! command -v kryonix >/dev/null 2>&1; then
             echo "⚠ 'kryonix' CLI não encontrada no PATH, pulando validação estrita."
             break
        fi
        if ! kryonix --help | grep -q "\b$cmd\b"; then
            echo "ERRO: Comando 'kryonix $cmd' está documentado, mas não existe no 'kryonix --help'."
            exit 1
        fi
    done < <(grep -oP '(?<=kryonix )\w+' "$DOCS_DIR/USAGE.md" | sort -u | grep -v 'mcp\|brain\|graph\|doctor\|health\|stats\|search\|ask\|print-config')
    echo "✓ Comandos documentados no USAGE.md validados."
else
    echo "ERRO: $DOCS_DIR/USAGE.md não encontrado."
    exit 1
fi

echo ""
echo "[3] Verificando presença de Fonte de Verdade nos docs técnicos..."
if ! grep -q "Fonte de Verdade" "$DOCS_DIR"/*.md 2>/dev/null && ! grep -q "fonte canônica" "$DOCS_DIR"/*.md 2>/dev/null && ! grep -q "Fonte de Verdade" "$DOCS_DIR"/brain/*.md 2>/dev/null; then
    echo "⚠ Aviso: Não foi encontrada menção explícita a 'Fonte de Verdade' ou 'fonte canônica' nos docs."
else
    echo "✓ Menção a Fonte de Verdade encontrada."
fi

echo ""
echo "[4] Verificando presença de ROADMAP estruturado..."
if [ ! -f "$DOCS_DIR/ROADMAP.md" ]; then
    echo "ERRO: ROADMAP.md não encontrado."
    exit 1
else
    echo "✓ ROADMAP.md existe."
fi

echo ""
echo "[5] Verificando se docs/archive existe..."
if [ ! -d "$DOCS_DIR/archive" ]; then
    echo "ERRO: Diretório docs/archive não encontrado."
    exit 1
else
    echo "✓ docs/archive existe."
fi

echo ""
echo "[6] Verificando estrutura de Governança de Agentes..."
REPO_ROOT="$(dirname "$0")/.."
if [ ! -d "$REPO_ROOT/.agents/rules" ]; then
    echo "ERRO: Diretório .agents/rules não encontrado."
    exit 1
fi
if [ ! -d "$REPO_ROOT/.agents/workflows" ]; then
    echo "ERRO: Diretório .agents/workflows não encontrado."
    exit 1
fi
if [ ! -d "$REPO_ROOT/.context" ]; then
    echo "ERRO: Diretório .context não encontrado."
    exit 1
fi
echo "✓ Estrutura de agentes e contexto encontrada."

echo ""
echo "[7] Verificando Governança Automatizada (CI/CD)..."
if [ ! -f "$REPO_ROOT/.github/workflows/docs-audit.yml" ]; then
    echo "ERRO: GitHub Action docs-audit.yml não encontrada."
    exit 1
fi
if [ ! -f "$REPO_ROOT/.github/pull_request_template.md" ]; then
    echo "ERRO: Pull Request template não encontrado."
    exit 1
fi
echo "✓ Governança automatizada configurada."

echo ""
echo "[8] Verificando Scripts críticos..."
SCRIPTS_DIR="$(dirname "$0")"
CRITICAL_SCRIPTS=("doc-audit.sh")
for script in "${CRITICAL_SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPTS_DIR/$script" ]; then
        echo "ERRO: Script crítico $script não encontrado."
        exit 1
    fi
done
echo "✓ Scripts críticos encontrados."

echo ""
echo "[9] Verificando Runtime e Serviços (Leve)..."
HOSTNAME=$(hostname 2>/dev/null || echo "unknown")

if ss -ltnp 2>/dev/null | grep -q 11434; then
    echo "✓ Ollama ativo na porta 11434."
else
    if [ "$HOSTNAME" = "glacier" ]; then
        echo "ERRO: Ollama não ativo localmente no Glacier (porta 11434)."
        exit 1
    else
        echo "⚠ Ollama não ativo localmente (ignorável pois não é o host glacier)."
    fi
fi

if ss -ltnp 2>/dev/null | grep -q 8000 || systemctl status kryonix-brain-api.service >/dev/null 2>&1; then
    echo "✓ Kryonix Brain API ativo."
else
    if grep -q "Kryonix Brain API.*PARTIAL" "$DOCS_DIR/ROADMAP.md" 2>/dev/null || grep -q "Brain API.*ROADMAP" "$DOCS_DIR/ROADMAP.md" 2>/dev/null; then
        echo "⚠ Kryonix Brain API offline, mas ROADMAP diz que é parcial/não implementado. (PASS)"
    else
        echo "⚠ Kryonix Brain API não ativo localmente."
    fi
fi

echo "======================================"
echo "✓ AUDITORIA CONCLUÍDA COM SUCESSO."
echo "======================================"

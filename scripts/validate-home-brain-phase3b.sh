#!/usr/bin/env bash
#
# scripts/validate-home-brain-phase3b.sh
# Validation script for Kryonix Home Brain Phase 3B deterministic taxonomy & renaming
#
set -euo pipefail

# Setup colors for gorgeous output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    printf "${BLUE}[INFO] %s${NC}\n" "$1"
}

log_success() {
    printf "${GREEN}[SUCCESS] %s${NC}\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN] %s${NC}\n" "$1"
}

log_error() {
    printf "${RED}[ERROR] %s${NC}\n" "$1"
}

# Pre-flight checks
log_info "Running pre-flight checks..."
for cmd in nix jq grep diff; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required dependency '$cmd' is not installed."
        exit 1
    fi
done

# Build kryonix-home binary path
log_info "Building kryonix-home package via Nix..."
KRYONIX_HOME_OUT="$(nix build .#kryonix-home --no-link --print-out-paths)"
export PATH="$KRYONIX_HOME_OUT/bin:$PATH"

if ! command -v kryonix-home &>/dev/null; then
    log_error "kryonix-home binary is not accessible in PATH."
    exit 1
fi
log_success "Pre-flight checks passed."

# Sandbox directories tracking
SANDBOX_DIRS=()
cleanup() {
    log_info "Cleaning up temporary sandbox environments..."
    for dir in "${SANDBOX_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
        fi
    done
}
trap cleanup EXIT

# Sandbox preparation helper
prepare_sandbox() {
    local target_dir="$1"
    mkdir -p "$target_dir/Downloads" \
             "$target_dir/Documentos" \
             "$target_dir/Imagens" \
             "$target_dir/Videos" \
             "$target_dir/Musicas" \
             "$target_dir/.config/kryonix"

    # Create the custom taxonomy file
    cat << 'EOF' > "$target_dir/.config/kryonix/home-taxonomy.toml"
[profile]
name = "kryonix-home-taxonomy-test"
fallback_dir = "Documentos/00_Inbox/Revisar"

[[category]]
id = "teste.custom"
label = "Teste Customizado"
dir = "Documentos/Teste_Customizado"
keywords = ["custom", "test", "valida"]
extensions = ["txt", "pdf"]
risk = "low"

[[category]]
id = "admin.identificacao"
label = "Identificação"
dir = "Documentos/Administrativo/Identificacao"
keywords = ["rg", "cpf", "cnh", "identidade", "titulo eleitor", "certidao", "nascimento", "casamento"]
extensions = ["pdf", "jpg", "png"]
risk = "medium"

[[category]]
id = "admin.contratos"
label = "Contratos"
dir = "Documentos/Administrativo/Contratos"
keywords = ["contrato", "termo", "acordo", "locacao", "aluguel", "assinatura"]
extensions = ["pdf", "docx", "odt"]
risk = "medium"

[[category]]
id = "financeiro.boletos"
label = "Boletos"
dir = "Documentos/Financeiro/Boletos"
keywords = ["boleto", "pagamento", "vencimento"]
extensions = ["pdf"]
risk = "medium"

[[category]]
id = "financeiro.faturas"
label = "Faturas"
dir = "Documentos/Financeiro/Faturas"
keywords = ["fatura", "cartao", "cartão", "nubank", "inter", "mercado pago", "energia", "agua", "água", "internet"]
extensions = ["pdf"]
risk = "medium"

[[category]]
id = "financeiro.notas_fiscais"
label = "Notas Fiscais"
dir = "Documentos/Financeiro/Notas_Fiscais"
keywords = ["nota fiscal", "nf", "nfe", "danfe", "cupom fiscal"]
extensions = ["pdf", "xml"]
risk = "low"

[[category]]
id = "financeiro.bancos"
label = "Bancos"
dir = "Documentos/Financeiro/Bancos"
keywords = ["banco", "pix", "extrato", "conta", "agencia", "transferencia"]
extensions = ["pdf", "csv", "xlsx", "txt"]
risk = "medium"

[[category]]
id = "estudos.nixos"
label = "NixOS"
dir = "Documentos/Estudos/NixOS"
keywords = ["nixos", "nix", "flake", "home-manager"]
extensions = ["md", "nix", "txt"]
risk = "low"

[[category]]
id = "imagens.screenshots"
label = "Screenshots"
dir = "Imagens/Screenshots"
keywords = ["screenshot", "captura", "print", "screen"]
extensions = ["png", "jpg"]
risk = "low"
EOF

    # Create dummy user files
    printf "pix content\n" > "$target_dir/Downloads/comprovante pix banco.pdf"
    printf "study content\n" > "$target_dir/Downloads/nixos flake estudo.txt"
    printf "screenshot content\n" > "$target_dir/Downloads/screenshot erro.png"
    printf "custom content\n" > "$target_dir/Downloads/teste customizado valida.txt"
    printf "invoice content\n" > "$target_dir/Downloads/nota fiscal compra pc.pdf"
    # This triggers an empate (tie) because it contains keywords from boletos, contratos and identificacao
    printf "conflict content\n" > "$target_dir/Downloads/boleto cnh contrato.pdf"
}

# ==============================================================================
# PART A: Testing Direct Binary (kryonix-home)
# ==============================================================================
log_info "=== PART A: Testing Direct Binary (kryonix-home) ==="
SANDBOX_A=$(mktemp -d)
SANDBOX_DIRS+=("$SANDBOX_A")
prepare_sandbox "$SANDBOX_A"

export HOME="$SANDBOX_A"

# 1. scan
log_info "Running: kryonix-home scan"
kryonix-home scan

LATEST_SCAN=$(find "$SANDBOX_A/.local/state/kryonix/home-brain" -name "scan.json" | head -n 1)
if [[ -z "$LATEST_SCAN" ]]; then
    log_error "scan.json was not generated."
    exit 1
fi
jq . "$LATEST_SCAN" > /dev/null
log_success "Scan completed successfully."

# 2. categories
log_info "Running: kryonix-home categories"
kryonix-home categories
kryonix-home categories --json > "$SANDBOX_A/categories.json"
jq . "$SANDBOX_A/categories.json" > /dev/null
if ! jq -e '.categories[] | select(.id == "teste.custom")' "$SANDBOX_A/categories.json" > /dev/null; then
    log_error "Custom category 'teste.custom' was not found in categories output."
    exit 1
fi
log_success "Categories output validated."

# 3. explain
log_info "Running: kryonix-home explain"
kryonix-home explain "$SANDBOX_A/Downloads/comprovante pix banco.pdf"
log_success "Explain command executed."

# 4. plan
log_info "Running: kryonix-home plan"
kryonix-home plan --taxonomy-suggestions --rename-suggestions --why
kryonix-home plan --taxonomy-suggestions --rename-suggestions --json > "$SANDBOX_A/plan.json"
jq . "$SANDBOX_A/plan.json" > /dev/null

if ! jq -e '.proposals[] | select(.category_id == "teste.custom")' "$SANDBOX_A/plan.json" > /dev/null; then
    log_error "Custom category propoal not found in plan JSON."
    exit 1
fi
if ! jq -e '.proposals[] | select(.taxonomy_profile == "kryonix-home-taxonomy-test")' "$SANDBOX_A/plan.json" > /dev/null; then
    log_error "Custom taxonomy profile name not found in plan."
    exit 1
fi
log_success "Custom TOML profile and category_id verified in plan."

# 5. manifest create
log_info "Running: kryonix-home manifest create"
kryonix-home manifest create --taxonomy-suggestions --rename-suggestions
LATEST_MANIFEST=$(find "$SANDBOX_A/.local/state/kryonix/home-brain/manifests" -name "*.json" | head -n 1)
if [[ -z "$LATEST_MANIFEST" ]]; then
    log_error "Manifest file not found."
    exit 1
fi
jq . "$LATEST_MANIFEST" > /dev/null
log_success "Manifest created successfully."

# 6. apply dry-run
log_info "Running: kryonix-home apply --dry-run"
kryonix-home apply --dry-run
log_success "Apply dry-run passed."

# 7. record file list before apply
find "$SANDBOX_A/Downloads" "$SANDBOX_A/Documentos" "$SANDBOX_A/Imagens" "$SANDBOX_A/Videos" "$SANDBOX_A/Musicas" -type f 2>/dev/null | sort > "$SANDBOX_A/before_apply.txt"

# 8. apply confirm
log_info "Running: kryonix-home apply --confirm"
kryonix-home apply --confirm

# Verify the destinations are correct via find
find "$SANDBOX_A/Downloads" "$SANDBOX_A/Documentos" "$SANDBOX_A/Imagens" "$SANDBOX_A/Videos" "$SANDBOX_A/Musicas" -type f 2>/dev/null | sort > "$SANDBOX_A/after_apply.txt"

# Verify files moved to custom taxonomy folders
if ! grep -q "Documentos/Teste_Customizado/" "$SANDBOX_A/after_apply.txt"; then
    log_error "File did not move to custom taxonomy category directory Documentos/Teste_Customizado/"
    exit 1
fi

# Verify tie-breaking files moved to Conflitos
if ! grep -q "Documentos/00_Inbox/Conflitos/" "$SANDBOX_A/after_apply.txt"; then
    log_error "Tie-breaking file did not move to Conflitos directory Documentos/00_Inbox/Conflitos/"
    exit 1
fi
log_success "Files successfully moved to their deterministic folders."

# 9. rollback
log_info "Running: kryonix-home rollback"
kryonix-home rollback

# Record file list after rollback
find "$SANDBOX_A/Downloads" "$SANDBOX_A/Documentos" "$SANDBOX_A/Imagens" "$SANDBOX_A/Videos" "$SANDBOX_A/Musicas" -type f 2>/dev/null | sort > "$SANDBOX_A/after_rollback.txt"

# Compare before and after with diff
if ! diff -u "$SANDBOX_A/before_apply.txt" "$SANDBOX_A/after_rollback.txt"; then
    log_error "Rollback did not restore original state perfectly!"
    exit 1
fi
log_success "Direct binary tests and perfect rollback verified."

# ==============================================================================
# PART B: Testing CLI Wrapper (nix run .#kryonix)
# ==============================================================================
log_info "=== PART B: Testing CLI Wrapper (nix run .#kryonix) ==="
SANDBOX_B=$(mktemp -d)
SANDBOX_DIRS+=("$SANDBOX_B")
prepare_sandbox "$SANDBOX_B"

export HOME="$SANDBOX_B"

# 1. scan
log_info "Running: nix run .#kryonix -- home scan"
nix run .#kryonix -- home scan

LATEST_SCAN=$(find "$SANDBOX_B/.local/state/kryonix/home-brain" -name "scan.json" | head -n 1)
if [[ -z "$LATEST_SCAN" ]]; then
    log_error "scan.json was not generated via CLI."
    exit 1
fi
jq . "$LATEST_SCAN" > /dev/null
log_success "CLI Scan completed successfully."

# 2. categories
log_info "Running: nix run .#kryonix -- home categories --json"
nix run .#kryonix -- home categories --json > "$SANDBOX_B/categories.json"
jq . "$SANDBOX_B/categories.json" > /dev/null
if ! jq -e '.categories[] | select(.id == "teste.custom")' "$SANDBOX_B/categories.json" > /dev/null; then
    log_error "Custom category 'teste.custom' was not found in CLI categories output."
    exit 1
fi
log_success "CLI Categories output validated."

# 3. explain
log_info "Running: nix run .#kryonix -- home explain"
nix run .#kryonix -- home explain "$SANDBOX_B/Downloads/comprovante pix banco.pdf"
log_success "CLI Explain command executed."

# 4. plan
log_info "Running: nix run .#kryonix -- home plan --json"
nix run .#kryonix -- home plan --json --taxonomy-suggestions --rename-suggestions > "$SANDBOX_B/plan.json"
jq . "$SANDBOX_B/plan.json" > /dev/null

if ! jq -e '.proposals[] | select(.category_id == "teste.custom")' "$SANDBOX_B/plan.json" > /dev/null; then
    log_error "Custom category propoal not found in CLI plan JSON."
    exit 1
fi
if ! jq -e '.proposals[] | select(.taxonomy_profile == "kryonix-home-taxonomy-test")' "$SANDBOX_B/plan.json" > /dev/null; then
    log_error "Custom taxonomy profile name not found in CLI plan."
    exit 1
fi
log_success "CLI Custom TOML profile and category_id verified in plan."

# 5. manifest create
log_info "Running: nix run .#kryonix -- home manifest create"
nix run .#kryonix -- home manifest create --taxonomy-suggestions --rename-suggestions
LATEST_MANIFEST=$(find "$SANDBOX_B/.local/state/kryonix/home-brain/manifests" -name "*.json" | head -n 1)
if [[ -z "$LATEST_MANIFEST" ]]; then
    log_error "CLI Manifest file not found."
    exit 1
fi
jq . "$LATEST_MANIFEST" > /dev/null
log_success "CLI Manifest created successfully."

# 6. apply dry-run
log_info "Running: nix run .#kryonix -- home apply --dry-run"
nix run .#kryonix -- home apply --dry-run
log_success "CLI Apply dry-run passed."

# 7. record file list before apply
find "$SANDBOX_B/Downloads" "$SANDBOX_B/Documentos" "$SANDBOX_B/Imagens" "$SANDBOX_B/Videos" "$SANDBOX_B/Musicas" -type f 2>/dev/null | sort > "$SANDBOX_B/before_apply.txt"

# 8. apply confirm
log_info "Running: nix run .#kryonix -- home apply --confirm"
nix run .#kryonix -- home apply --confirm

# Verify the destinations are correct via find
find "$SANDBOX_B/Downloads" "$SANDBOX_B/Documentos" "$SANDBOX_B/Imagens" "$SANDBOX_B/Videos" "$SANDBOX_B/Musicas" -type f 2>/dev/null | sort > "$SANDBOX_B/after_apply.txt"

# Verify files moved to custom taxonomy folders
if ! grep -q "Documentos/Teste_Customizado/" "$SANDBOX_B/after_apply.txt"; then
    log_error "CLI: File did not move to custom taxonomy category directory Documentos/Teste_Customizado/"
    exit 1
fi

# Verify tie-breaking files moved to Conflitos
if ! grep -q "Documentos/00_Inbox/Conflitos/" "$SANDBOX_B/after_apply.txt"; then
    log_error "CLI: Tie-breaking file did not move to Conflitos directory Documentos/00_Inbox/Conflitos/"
    exit 1
fi
log_success "CLI: Files successfully moved to their deterministic folders."

# 9. rollback
log_info "Running: nix run .#kryonix -- home rollback"
nix run .#kryonix -- home rollback

# Record file list after rollback
find "$SANDBOX_B/Downloads" "$SANDBOX_B/Documentos" "$SANDBOX_B/Imagens" "$SANDBOX_B/Videos" "$SANDBOX_B/Musicas" -type f 2>/dev/null | sort > "$SANDBOX_B/after_rollback.txt"

# Compare before and after with diff
if ! diff -u "$SANDBOX_B/before_apply.txt" "$SANDBOX_B/after_rollback.txt"; then
    log_error "CLI: Rollback did not restore original state perfectly!"
    exit 1
fi
log_success "CLI: tests and perfect rollback verified."

# ==============================================================================
# PART E: Testing Anti-Overwrite Safety Mode
# ==============================================================================
log_info "=== PART E: Testing Anti-Overwrite Safety Mode ==="
SANDBOX_C=$(mktemp -d)
SANDBOX_DIRS+=("$SANDBOX_C")
prepare_sandbox "$SANDBOX_C"

export HOME="$SANDBOX_C"

kryonix-home scan
kryonix-home manifest create --taxonomy-suggestions --rename-suggestions

# Initialize a pre-existing destination file with DIFFERENT content AFTER manifest creation
mkdir -p "$SANDBOX_C/Documentos/Financeiro/Bancos"
DEST_FILE="$SANDBOX_C/Documentos/Financeiro/Bancos/$(date +%F)_Comprovante_Pix_Banco_v1.pdf"
printf "EXISTING DESTINATION FILE CONTENT\n" > "$DEST_FILE"

log_info "Executing apply --confirm with conflicting destination file..."
# Run apply. It should return exit code due to blocked collision, which we handle gracefully.
kryonix-home apply --confirm || log_warn "Apply returned non-zero due to blocked collision (expected behavior)."

# Assert that the destination file has its original content preserved!
if ! grep -q "EXISTING DESTINATION FILE CONTENT" "$DEST_FILE"; then
    log_error "CRITICAL: The existing destination file was OVERWRITTEN!"
    exit 1
fi

# Assert that the original file in Downloads is still there
if [[ ! -f "$SANDBOX_C/Downloads/comprovante pix banco.pdf" ]]; then
    log_error "CRITICAL: The original source file in Downloads was deleted even though apply was blocked!"
    exit 1
fi

log_success "Anti-Overwrite Safety validated perfectly. Original content preserved, source file kept."

# ==============================================================================
# SUCCESS SUMMARY
# ==============================================================================
echo ""
log_success "======================================================================"
log_success "ALL TEST SUITES IN SANDBOX ENVIRONMENTS EXECUTED AND PASSED PERFECTLY!"
log_success "Deterministic Taxonomy, Tie-Breaking, Rollback & Anti-Overwrite are STABLE."
log_success "======================================================================"

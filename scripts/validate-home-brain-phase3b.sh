#!/usr/bin/env bash
#
# scripts/validate-home-brain-phase3b.sh
# Final Validation Suite for Kryonix Home Brain Phase 3B
#
set -euo pipefail

# Setup colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { printf "${BLUE}[INFO] %s${NC}\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS] %s${NC}\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN] %s${NC}\n" "$1"; }
log_error() { printf "${RED}[ERROR] %s${NC}\n" "$1"; }

# Pre-flight
log_info "Building kryonix-home binary..."
KRYONIX_HOME_OUT="$(nix build .#kryonix-home --no-link --print-out-paths)"
export PATH="$KRYONIX_HOME_OUT/bin:$PATH"

SANDBOX_DIRS=()
cleanup() {
    log_info "Cleaning up..."
    for dir in "${SANDBOX_DIRS[@]}"; do
        [[ -d "$dir" ]] && rm -rf "$dir"
    done
}
trap cleanup EXIT

create_sandbox() {
    local dir
    dir=$(mktemp -d)
    SANDBOX_DIRS+=("$dir")
    mkdir -p "$dir/Downloads" "$dir/Documentos" "$dir/Imagens" "$dir/Videos" "$dir/.config/kryonix"
    echo "$dir"
}

write_normal_taxonomy() {
    local dir="$1"
    cat << 'TOML' > "$dir/.config/kryonix/home-taxonomy.toml"
[profile]
name = "kryonix-test-normal"
fallback_dir = "Documentos/00_Inbox/Revisar"

[[category]]
id = "financeiro.bancos"
label = "Bancos"
dir = "Documentos/Financeiro/Bancos"
keywords = ["pix", "banco", "extrato"]
extensions = ["pdf"]
risk = "medium"

[[category]]
id = "estudos.nixos"
label = "NixOS"
dir = "Documentos/Estudos/NixOS"
keywords = ["nixos", "flake"]
extensions = ["txt", "nix"]
risk = "low"
TOML
}

write_conflict_taxonomy() {
    local dir="$1"
    cat << 'TOML' > "$dir/.config/kryonix/home-taxonomy.toml"
[profile]
name = "kryonix-test-conflict"
fallback_dir = "Documentos/00_Inbox/Revisar"

[[category]]
id = "conflict.a"
label = "Conflict A"
dir = "Documentos/Conflict_A"
keywords = ["conflito"]
extensions = ["pdf"]

[[category]]
id = "conflict.b"
label = "Conflict B"
dir = "Documentos/Conflict_B"
keywords = ["conflito"]
extensions = ["pdf"]
TOML
}

# ------------------------------------------------------------------------------
# 1. Binary Flow & Taxonomy Match
# ------------------------------------------------------------------------------
test_binary_normal() {
    log_info "Testing Binary Flow (Normal Taxonomy)..."
    local sb
    sb=$(create_sandbox)
    write_normal_taxonomy "$sb"
    printf "pix content" > "$sb/Downloads/extrato_banco.pdf"
    
    HOME="$sb" kryonix-home scan
    HOME="$sb" kryonix-home plan --taxonomy-suggestions --rename-suggestions --json > "$sb/plan.json"
    
    if ! jq -e '.proposals[] | select(.category_id == "financeiro.bancos")' "$sb/plan.json" > /dev/null; then
        log_error "Failed to match financeiro.bancos"
        exit 1
    fi
    log_success "Binary Normal Taxonomy matched."
}

# ------------------------------------------------------------------------------
# 2. CLI Flow & Wrapper Routing
# ------------------------------------------------------------------------------
test_cli_wrapper() {
    log_info "Testing CLI Wrapper (nix run .#kryonix)..."
    local sb
    sb=$(create_sandbox)
    write_normal_taxonomy "$sb"
    printf "nixos flake" > "$sb/Downloads/estudo.txt"
    
    HOME="$sb" nix run .#kryonix -- home scan
    HOME="$sb" nix run .#kryonix -- home categories --json > "$sb/cats.json"
    
    if ! jq -e '.categories[] | select(.id == "estudos.nixos")' "$sb/cats.json" > /dev/null; then
        log_error "CLI wrapper failed to load categories"
        exit 1
    fi
    log_success "CLI Wrapper routing confirmed."
}

# ------------------------------------------------------------------------------
# 3. Conflict / Tie-Breaking
# ------------------------------------------------------------------------------
test_conflict_taxonomy() {
    log_info "Testing Conflict/Tie-Breaking..."
    local sb
    sb=$(create_sandbox)
    write_conflict_taxonomy "$sb"
    printf "conflito content" > "$sb/Downloads/arquivo_conflito.pdf"
    
    HOME="$sb" kryonix-home scan
    HOME="$sb" kryonix-home manifest create --taxonomy-suggestions --rename-suggestions
    HOME="$sb" kryonix-home apply --confirm
    
    if ! find "$sb/Documentos/00_Inbox/Conflitos" -type f | grep -q "."; then
        log_error "File did not move to Conflitos on tie."
        exit 1
    fi
    log_success "Conflict/Tie-breaking verified."
}

# ------------------------------------------------------------------------------
# 4. Anti-Overwrite (No Masking)
# ------------------------------------------------------------------------------
test_anti_overwrite() {
    log_info "Testing Anti-Overwrite (No Masking)..."
    local sb
    sb=$(create_sandbox)
    write_normal_taxonomy "$sb"
    printf "source" > "$sb/Downloads/pix.pdf"
    
    # Pre-calculate destination name (today's date)
    local today
    today=$(date +%Y-%m-%d)
    local dest_dir="$sb/Documentos/Financeiro/Bancos"
    local dest_file="$dest_dir/${today}_Pix_v1.pdf"
    
    mkdir -p "$dest_dir"
    printf "existing" > "$dest_file"
    
    HOME="$sb" kryonix-home scan
    HOME="$sb" kryonix-home manifest create --taxonomy-suggestions --rename-suggestions
    
    # Should fail apply due to collision
    if HOME="$sb" kryonix-home apply --confirm 2>/dev/null; then
        log_warn "Apply succeeded unexpectedly? Checking content..."
    fi
    
    if ! grep -q "existing" "$dest_file"; then
        log_error "CRITICAL: Destination file was overwritten!"
        exit 1
    fi
    if [[ ! -f "$sb/Downloads/pix.pdf" ]]; then
        log_error "Source file was deleted even though move failed."
        exit 1
    fi
    log_success "Anti-Overwrite verified without masking."
}

# ------------------------------------------------------------------------------
# 5. Rollback Integrity (Diff-based)
# ------------------------------------------------------------------------------
test_rollback_integrity() {
    log_info "Testing Rollback Integrity (Diff-based)..."
    local sb
    sb=$(create_sandbox)
    write_normal_taxonomy "$sb"
    printf "a" > "$sb/Downloads/a.pdf" # Matches bancos (due to .pdf and fallback or match?)
    # Let's make it match bancos
    printf "pix" > "$sb/Downloads/bancos.pdf"
    
    find "$sb" -type f | sort > "$sb/before.txt"
    
    HOME="$sb" kryonix-home scan
    HOME="$sb" kryonix-home manifest create --taxonomy-suggestions --rename-suggestions
    HOME="$sb" kryonix-home apply --confirm
    
    HOME="$sb" kryonix-home rollback
    
    find "$sb" -type f | sort > "$sb/after.txt"
    
    # Filter out state/logs and test artifacts which change/appear during the run
    grep -vE "\.local/state/kryonix/home-brain|before.*\.txt|after.*\.txt" "$sb/before.txt" > "$sb/before_clean.txt"
    grep -vE "\.local/state/kryonix/home-brain|before.*\.txt|after.*\.txt" "$sb/after.txt" > "$sb/after_clean.txt"
    
    if ! diff -u "$sb/before_clean.txt" "$sb/after_clean.txt"; then
        log_error "Rollback did not restore file system state perfectly."
        exit 1
    fi
    log_success "Rollback integrity verified via diff."
}

# Main
log_info "Starting Phase 3B Validation Suite..."
test_binary_normal
test_cli_wrapper
test_conflict_taxonomy
test_anti_overwrite
test_rollback_integrity

echo ""
log_success "===================================================="
log_success "PHASE 3B VALIDATION COMPLETE: ALL SYSTEMS NOMINAL"
log_success "===================================================="

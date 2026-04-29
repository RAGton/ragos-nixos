#!/usr/bin/env bash
# ==============================================================================
# Script: restore-brain-nixos.sh
# Objetivo: Restaurar ecossistema Brain no Glacier (NixOS)
# ==============================================================================

BACKUP_SOURCE=$1
VAULT_TARGET="/var/lib/kryonix/vault"
BRAIN_STORAGE_TARGET="/var/lib/kryonix/brain/storage"

if [ -z "$BACKUP_SOURCE" ]; then
    echo "Erro: Forneça o caminho do backup."
    echo "Uso: ./restore-brain-nixos.sh /path/to/backup"
    exit 1
fi

echo "Iniciando restauração de: $BACKUP_SOURCE"

# 1. Preparar diretórios
sudo mkdir -p "$VAULT_TARGET"
sudo mkdir -p "$BRAIN_STORAGE_TARGET"

# 2. Restaurar Vault
echo "Restaurando Vault..."
sudo cp -r "$BACKUP_SOURCE/vault/"* "$VAULT_TARGET/"

# 3. Restaurar Storage
echo "Restaurando Storage..."
sudo cp -r "$BACKUP_SOURCE/storage/"* "$BRAIN_STORAGE_TARGET/"

# 4. Ajustar Permissões
echo "Ajustando permissões para kryonix-brain..."
sudo chown -R kryonix-brain:kryonix-brain "/var/lib/kryonix/brain"
sudo chmod -R 750 "/var/lib/kryonix/brain"

# 5. Validar
echo "Validação básica..."
if [ -d "$BRAIN_STORAGE_TARGET/index" ] || [ -f "$BRAIN_STORAGE_TARGET/vdb_entities.json" ]; then
    echo "Restauração parece OK."
else
    echo "Aviso: Estrutura de storage não encontrada no destino."
fi

echo "Pronto. Lembre-se de configurar /etc/kryonix/brain.env com a KRYONIX_BRAIN_KEY."

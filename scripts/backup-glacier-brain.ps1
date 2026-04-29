# ==============================================================================
# Script: backup-glacier-brain.ps1
# Objetivo: Backup preventivo do ecossistema Brain no Glacier (Windows)
# ==============================================================================

$BackupDir = "C:\Users\aguia\Documents\kryonix-backups\$(Get-Date -Format 'yyyy-MM-dd_HH-mm')"
$VaultDir = "C:\Users\aguia\Documents\kryonix-vault"
$StorageDir = "C:\Users\aguia\Documents\kryonix-vault\11-LightRAG\rag_storage"
$ConfigDir = "C:\Users\aguia\Documents\kryonix"

Write-Host "Iniciando backup em: $BackupDir" -ForegroundColor Cyan

# Criar estrutura de backup
New-Item -ItemType Directory -Force -Path "$BackupDir\vault"
New-Item -ItemType Directory -Force -Path "$BackupDir\storage"
New-Item -ItemType Directory -Force -Path "$BackupDir\config"

# 1. Backup do Vault (Obsidian)
Write-Host "Backup do Vault..."
Copy-Item -Path "$VaultDir\*" -Destination "$BackupDir\vault" -Recurse -Force -Exclude ".git", ".obsidian"

# 2. Backup do rag_storage (LightRAG)
Write-Host "Backup do rag_storage..."
Copy-Item -Path "$StorageDir\*" -Destination "$BackupDir\storage" -Recurse -Force

# 3. Backup de Config e Env (sem secrets brutos)
Write-Host "Backup de Configurações..."
Copy-Item -Path "$ConfigDir\brain.env.example" -Destination "$BackupDir\config\brain.env.example" -Force
# Nota: KRYONIX_BRAIN_KEY deve ser salvo manualmente em local seguro (Bitwarden/Vault)

# 4. Gerar Checksum
Write-Host "Gerando Checksums..."
Get-ChildItem -Path $BackupDir -Recurse | Get-FileHash | Export-Csv -Path "$BackupDir\manifest.csv" -NoTypeInformation

Write-Host "Backup concluído com sucesso em: $BackupDir" -ForegroundColor Green

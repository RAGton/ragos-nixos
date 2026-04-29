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
if (Test-Path $VaultDir) {
    Copy-Item -Path "$VaultDir\*" -Destination "$BackupDir\vault" -Recurse -Force -Exclude ".git", ".obsidian"
} else {
    Write-Warning "Vault directory not found: $VaultDir"
}

# 2. Backup do rag_storage (LightRAG)
Write-Host "Backup do rag_storage..."
if (Test-Path $StorageDir) {
    Copy-Item -Path "$StorageDir\*" -Destination "$BackupDir\storage" -Recurse -Force
} else {
    Write-Warning "Storage directory not found: $StorageDir"
}

# 3. Backup de Config e Env (sem secrets brutos)
Write-Host "Backup de Configurações..."
if (Test-Path "$ConfigDir\brain.env.example") {
    Copy-Item -Path "$ConfigDir\brain.env.example" -Destination "$BackupDir\config\brain.env.example" -Force
}
# Backup de modelos Ollama (lista)
ollama list > "$BackupDir\config\ollama-models.txt"

# 4. Gerar Checksum (excluindo o próprio manifest)
Write-Host "Gerando Checksums..."
$ManifestPath = "$BackupDir\manifest.csv"
Get-ChildItem -Path $BackupDir -Recurse -File | Where-Object { $_.FullName -ne $ManifestPath } | Get-FileHash | Export-Csv -Path $ManifestPath -NoTypeInformation

Write-Host "Backup concluído com sucesso em: $BackupDir" -ForegroundColor Green

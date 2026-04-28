# Script para configurar exposição pública segura do Kryonix (Glacier)
# EXECUTE COMO ADMINISTRADOR

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRO: Este script PRECISA ser executado como ADMINISTRADOR." -ForegroundColor Red
    Write-Host "Por favor, clique com o botão direito no PowerShell e selecione 'Executar como Administrador'."
    exit
}

Write-Host "--- Configurando Kryonix para Acesso Público Seguro ---" -ForegroundColor Cyan

# 1. Variáveis de Ambiente do Sistema
Write-Host "[1/4] Configurando Variáveis de Ambiente..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
[Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "*", "Machine")
[Environment]::SetEnvironmentVariable("KRYONIX_BRAIN_KEY", "200520", "Machine")

# 2. Firewall do Windows (Abertura Seletiva)
Write-Host "[2/4] Configurando Firewall do Windows..." -ForegroundColor Yellow

# Limpar regras antigas para evitar duplicatas
netsh advfirewall firewall delete rule name="Kryonix_Ollama_Public" > $null
netsh advfirewall firewall delete rule name="Kryonix_Brain_API_Public" > $null
netsh advfirewall firewall delete rule name="Kryonix_SSH" > $null
netsh advfirewall firewall delete rule name="Kryonix_RustDesk" > $null

# Criar Novas Regras
netsh advfirewall firewall add rule name="Kryonix_Ollama_Public" dir=in action=allow protocol=TCP localport=11434 profile=any
netsh advfirewall firewall add rule name="Kryonix_Brain_API_Public" dir=in action=allow protocol=TCP localport=8000 profile=any
netsh advfirewall firewall add rule name="Kryonix_SSH" dir=in action=allow protocol=TCP localport=22 profile=any
netsh advfirewall firewall add rule name="Kryonix_RustDesk" dir=in action=allow protocol=TCP localport=21115-21119 profile=any
netsh advfirewall firewall add rule name="Kryonix_RustDesk_UDP" dir=in action=allow protocol=UDP localport=21116 profile=any

# 3. Informações para o Roteador
Write-Host "`n[3/4] PORTAS PARA LIBERAR NO ROTEADOR (Port Forwarding):" -ForegroundColor Magenta
Write-Host "Aponte estas portas para o IP Local: 10.0.0.2"
Write-Host "- Ollama: 11434 (TCP)"
Write-Host "- Brain API: 8000 (TCP)"
Write-Host "- SSH: 22 (TCP)"
Write-Host "- RustDesk ID/Relay: 21115-21119 (TCP) e 21116 (UDP)"

# 4. Status e Próximos Passos
Write-Host "`n[4/4] Resumo e Status" -ForegroundColor Cyan
Write-Host "KRYONIX_BRAIN_KEY configurada como: 200520"
Write-Host "Seu IP Público: $(Invoke-RestMethod https://ifconfig.me)"
Write-Host "`nConfiguração concluída! REINICIE o Ollama agora (feche no tray e abra de novo)." -ForegroundColor Green

# Script para configurar exposição pública do Ollama e Kryonix Brain
# EXECUTE COMO ADMINISTRADOR

Write-Host "--- Configurando Kryonix para Acesso Público ---" -ForegroundColor Cyan

# 1. Variáveis de Ambiente do Sistema
Write-Host "[1/3] Configurando Variáveis de Ambiente do Ollama..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
[Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "*", "Machine")
$env:OLLAMA_HOST = "0.0.0.0:11434"
$env:OLLAMA_ORIGINS = "*"

# 2. Firewall do Windows
Write-Host "[2/3] Abrindo portas no Firewall do Windows..." -ForegroundColor Yellow
# Ollama
netsh advfirewall firewall add rule name="Kryonix_Ollama_Public" dir=in action=allow protocol=TCP localport=11434 profile=any
# Brain API
netsh advfirewall firewall add rule name="Kryonix_Brain_API_Public" dir=in action=allow protocol=TCP localport=8000 profile=any

# 3. Sugestão de Segurança
Write-Host "[3/3] RECOMENDAÇÃO DE SEGURANÇA" -ForegroundColor Magenta
Write-Host "Expor o Ollama diretamente é perigoso. Defina uma API Key para a Brain API:"
Write-Host "Execute: [Environment]::SetEnvironmentVariable('KRYONIX_BRAIN_KEY', 'SUA_SENHA_AQUI', 'Machine')" -ForegroundColor Green

Write-Host "`nConfiguração concluída! Reinicie o Ollama (feche no tray e abra de novo)." -ForegroundColor Cyan
Write-Host "Seu IP Público atual é: $(curl -s https://ifconfig.me)"
Write-Host "Certifique-se de que o Port Forwarding no roteador aponta para este PC (10.0.0.2)."

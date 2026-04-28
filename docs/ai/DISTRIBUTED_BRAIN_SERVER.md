# Kryonix Brain Distributed Server (Glacier)

Este documento descreve como manter e operar o servidor central do Kryonix Brain no host **Glacier**.

## Serviços Expostos

- **Ollama**: Porta `11434` (Modelos de IA)
- **Brain API**: Porta `8000` (FastAPI wrapper para LightRAG)

## Como Iniciar os Serviços

### 1. Ollama
Certifique-se de que o Ollama está rodando no Windows. 
A variável de ambiente `OLLAMA_HOST=0.0.0.0` deve estar configurada para permitir acesso na LAN.

### 2. Brain API
Para iniciar a API manualmente ou via automação:
```powershell
.\scripts\start-brain-api.ps1
```
Ou via `rag.bat`:
```powershell
.\rag.bat kg-api
```

## Persistência
Para que a API inicie com o Windows, execute como Administrador:
```powershell
SchTasks /Create /SC ONLOGON /TN "KryonixBrainAPI" /TR "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Users\aguia\Documents\kryonix\scripts\start-brain-api.ps1"
```

Ou use o atalho de inicialização do Windows (Win+R > shell:startup) e coloque um atalho para o script.

## Firewall
O Inspiron (ou qualquer cliente na LAN) precisa de acesso às portas 11434 e 8000.
Comandos de Administrador:
```powershell
netsh advfirewall firewall add rule name="Kryonix_Ollama" dir=in action=allow protocol=TCP localport=11434
netsh advfirewall firewall add rule name="Kryonix_Brain_API" dir=in action=allow protocol=TCP localport=8000
```

## Logs
A API emite logs estruturados no console onde for iniciada.
Storage em: `C:\Users\aguia\Documents\kryonix-vault\11-LightRAG\rag_storage`

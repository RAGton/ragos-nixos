# Kryonix Brain Distributed Server (Glacier)

Este documento descreve como manter e operar o servidor central do Kryonix Brain no host **Glacier** usando a rede privada **Tailscale**.

## Arquitetura Recomendada (Segura)

- **Glacier (Server)**:
  - Tailscale IP: `100.108.71.36`
  - Ollama: `http://100.108.71.36:11434`
  - Brain API: `http://100.108.71.36:8000`

- **Inspiron (Client)**:
  - OLLAMA_HOST: `http://100.108.71.36:11434`
  - KRYONIX_BRAIN_URL: `http://100.108.71.36:8000`

## Como Iniciar os Serviços no Glacier

### 1. Ollama
O Ollama deve estar configurado para ouvir em `0.0.0.0` (acessível via interface Tailscale).
O acesso é protegido pelo Firewall do Windows, permitindo apenas conexões da rede Tailscale.

### 2. Brain API
Inicie a API via script:
```powershell
.\scripts\start-brain-api.ps1
```
A API faz o bind automático no IP `100.108.71.36`.

## Configuração de Acesso (Firewall)
Para configurar as permissões restritas ao Tailscale, execute como **Administrador**:
```powershell
.\scripts\setup-tailscale-access.ps1
```

## Segurança (API Key)
A Brain API exige autenticação para `/stats` e `/search`.

### No Glacier (Server)
Defina sua chave de forma persistente como Administrador:
```powershell
$Key = [guid]::NewGuid().ToString("N")
[Environment]::SetEnvironmentVariable("KRYONIX_BRAIN_KEY", $Key, "Machine")
Write-Host "Sua nova chave é: $Key"
```

### No Inspiron (Client)
A chave **NÃO** deve ser colocada no código Nix.
Armazene a chave no arquivo `/etc/kryonix/brain.env`:
```env
KRYONIX_BRAIN_KEY=sua-chave-aqui
```
Permissões recomendadas: `sudo chmod 600 /etc/kryonix/brain.env`.
Os comandos `kryonix brain` lerão automaticamente deste arquivo ou da variável de ambiente `KRYONIX_BRAIN_KEY`.

---
⚠️ **NUNCA** exponha o Ollama ou a Brain API via Port Forwarding público no roteador. Use sempre Tailscale ou VPN.

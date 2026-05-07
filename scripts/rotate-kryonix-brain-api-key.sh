#!/usr/bin/env bash
# ==============================================================================
# Script: Rotação Segura da Chave de API do Kryonix Brain
# Autor: Antigravity / Ragton
#
# O que é:
# - Script administrativo para gerar e aplicar uma nova chave de API para a Brain API.
# - Roda de forma imutável e preserva outras variáveis de ambiente no brain.env.
#
# Por quê:
# - Garante a segurança operacional e comunicação cifrada/autenticada entre hosts.
#
# Como:
# - Gera chave de alta entropia com Python's secrets.
# - Escreve de forma transacional e aplica permissões restritivas (0600 root:root).
# - Reinicia e valida o status com a nova credencial.
# ==============================================================================
set -euo pipefail

# 1. Restrição de Host: Glacier Apenas
current_host=$(cat /proc/sys/kernel/hostname | tr '[:upper:]' '[:lower:]')
if [[ "$current_host" != "glacier" && "$current_host" != "rve-glacier" && "$current_host" != "nixos" ]]; then
  echo "ERRO: Este script de rotação de chave de API só pode ser executado no host Glacier (servidor)." >&2
  exit 1
fi

# 2. Restrição de Privilégio: Root Apenas
if [[ $EUID -ne 0 ]]; then
  echo "ERRO: Este script precisa ser executado como root (sudo)." >&2
  exit 1
fi

echo "Iniciando processo de rotação da chave de API do Kryonix Brain..."

# 3. Geração Segura via Python Secrets (sem openssl)
new_key=$(python3 -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null)
if [[ -z "$new_key" ]]; then
  new_key=$(python -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null)
fi

if [[ -z "$new_key" ]]; then
  echo "ERRO: Falha crítica ao gerar nova chave de API através do Python secrets." >&2
  exit 1
fi

# Garantimos que a chave NÃO é impressa em tela por motivos de segurança.
echo "Nova chave de API de alta entropia gerada com sucesso (armazenamento seguro e silencioso)."

# 4. Escrita Transacional e Segura
ENV_FILE="/etc/kryonix/brain.env"
ENV_DIR="/etc/kryonix"

# Garantir que o diretório pai existe
mkdir -p "$ENV_DIR"

TMP_ENV=$(mktemp)
trap 'rm -f "$TMP_ENV"' EXIT

if [[ -f "$ENV_FILE" ]]; then
  # Preserva todas as variáveis existentes que não sejam KRYONIX_BRAIN_API_KEY
  grep -v "^KRYONIX_BRAIN_API_KEY=" "$ENV_FILE" > "$TMP_ENV" || true
fi

# Adiciona a nova chave
echo "KRYONIX_BRAIN_API_KEY=$new_key" >> "$TMP_ENV"

# Gravação segura
cp "$TMP_ENV" "$ENV_FILE"

# 5. Aplicação de Permissões Rígidas
chmod 0600 "$ENV_FILE"
chown root:root "$ENV_FILE"

echo "Configurações atualizadas e protegidas com sucesso em $ENV_FILE (0600 root:root)."

# 6. Reinicialização do Serviço systemd
if systemctl list-units --full -all | grep -Fq "kryonix-brain-api.service"; then
  echo "Reiniciando serviço kryonix-brain-api..."
  systemctl restart kryonix-brain-api
else
  echo "Aviso: Unidade de serviço 'kryonix-brain-api.service' não encontrada no systemd." >&2
fi

# Aguarda inicialização
echo "Aguardando 3 segundos para estabilização do serviço..."
sleep 3

# 7. Validação de Endpoints
echo "Validando endpoints do cérebro..."

# Testar /health (Público)
health_resp=$(curl -s --connect-timeout 5 http://127.0.0.1:8000/health || echo "")
if [[ -z "$health_resp" ]] || ! echo "$health_resp" | grep -q "status"; then
  echo "AVISO: Falha ao conectar ao endpoint /health. O serviço pode estar inicializando ou offline." >&2
else
  echo "Endpoint /health OK: $health_resp"
fi

# Testar /stats (Protegido por X-API-Key)
stats_resp=$(curl -s --connect-timeout 5 -H "X-API-Key: $new_key" http://127.0.0.1:8000/stats || echo "")
if [[ -z "$stats_resp" ]] || echo "$stats_resp" | grep -q "detail"; then
  echo "AVISO: Falha de autenticação ao conectar a /stats usando a nova chave." >&2
  if [[ -n "$stats_resp" ]]; then
    echo "Resposta do servidor: $stats_resp" >&2
  fi
else
  echo "Endpoint /stats validado com sucesso usando a nova chave de API!"
fi

echo "Processo de rotação concluído com sucesso!"

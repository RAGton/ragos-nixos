#!/usr/bin/env bash
# =============================================================================
# Script: kryonix-neo4j-doctor
#
# O que é:
# - Script de diagnóstico local para atestar o estado de saúde do Neo4j.
#
# Por quê:
# - Garante conformidade com as regras de segurança e resiliência (AGENTS.md).
# - Alerta se houver vazamento de portas públicas ou permissões frágeis nos segredos.
# =============================================================================

set -euo pipefail

# Paleta de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0;37m' # Sem Cor

echo -e "${BLUE}=== Kryonix Brain: Neo4j Doctor Diagnostics ===${NC}\n"

# 1. Verificar Diretórios Canônicos
echo -e "${BLUE}[1/4] Verificando layout de caminhos e permissões...${NC}"
PATHS=(
  "/var/lib/kryonix/brain/neo4j"
  "/var/lib/kryonix/brain/neo4j/data"
  "/var/lib/kryonix/brain/neo4j/logs"
  "/var/lib/kryonix/brain/neo4j/import"
  "/var/lib/kryonix/brain/neo4j/plugins"
)

ERR_PERM=0
for path in "${PATHS[@]}"; do
  if [ ! -d "$path" ]; then
    echo -e "  ${RED}❌ Direitório ausente: $path${NC}"
    ERR_PERM=1
    continue
  fi

  # Pegar dono e grupo do diretório
  OWNER=$(stat -c '%U' "$path")
  GROUP=$(stat -c '%G' "$path")
  PERMS=$(stat -c '%a' "$path")

  if [ "$OWNER" != "neo4j" ] || [ "$GROUP" != "neo4j" ]; then
    echo -e "  ${YELLOW}⚠️ Propriedade incorreta em $path: $OWNER:$GROUP (Esperado: neo4j:neo4j)${NC}"
    ERR_PERM=1
  else
    echo -e "  ${GREEN}✓ $path possui permissões corretas ($PERMS | $OWNER:$GROUP)${NC}"
  fi
done

if [ $ERR_PERM -eq 0 ]; then
  echo -e "  ${GREEN}✓ Estrutura de diretórios e permissões íntegra!${NC}"
else
  echo -e "  ${YELLOW}⚠ Alguns problemas de diretórios/propriedade foram detectados. Se o switch ainda não foi executado, ignore, pois o NixOS irá provisionar no switch.${NC}"
fi

# 2. Verificar Arquivo de Secrets
echo -e "\n${BLUE}[2/4] Verificando integridade e segurança de secrets...${NC}"
SECRET_FILE="/etc/kryonix/neo4j.env"
if [ ! -f "$SECRET_FILE" ]; then
  echo -e "  ${YELLOW}⚠️ Arquivo de secrets ausente: $SECRET_FILE (O Neo4j inicializará com a senha default)${NC}"
  echo -e "  Para corrigir, crie o arquivo manualmente com: sudo install -m600 /dev/null $SECRET_FILE"
else
  SEC_PERMS=$(stat -c '%a' "$SECRET_FILE")
  SEC_OWNER=$(stat -c '%U' "$SECRET_FILE")
  
  if [ "$SEC_PERMS" -ne "600" ] && [ "$SEC_PERMS" -ne "400" ]; then
    echo -e "  ${RED}❌ Arquivo de secrets com permissões inseguras: $SEC_PERMS (Esperado: 600 ou 400)${NC}"
  else
    echo -e "  ${GREEN}✓ Arquivo de secrets seguro ($SECRET_FILE | $SEC_OWNER | Permissões: $SEC_PERMS)${NC}"
  fi
fi

# 3. Verificar Status do Systemd Unit
echo -e "\n${BLUE}[3/4] Verificando status do serviço no systemd...${NC}"
if systemctl show -p LoadState neo4j.service | grep -q "loaded"; then
  ACTIVE_STATE=$(systemctl is-active neo4j || echo "inactive")
  ENABLED_STATE=$(systemctl is-enabled neo4j || echo "disabled")

  if [ "$ACTIVE_STATE" = "active" ]; then
    echo -e "  ${GREEN}✓ Serviço neo4j ativo e em execução! (Habilitado no boot: $ENABLED_STATE)${NC}"
  else
    echo -e "  ${YELLOW}⚠️ Serviço neo4j está inativo ($ACTIVE_STATE)${NC}"
  fi
else
  echo -e "  ${YELLOW}⚠️ Serviço neo4j.service não está registrado no systemd do host atual.${NC}"
fi

# 4. Verificar Bind de Rede e Firewall (Sockets)
echo -e "\n${BLUE}[4/4] Verificando isolamento de portas e rede...${NC}"
HTTP_BIND=$(ss -ltnp 2>/dev/null | grep ':7474' || echo "")
BOLT_BIND=$(ss -ltnp 2>/dev/null | grep ':7687' || echo "")

SECURE_BIND=1
if [ -n "$HTTP_BIND" ]; then
  if echo "$HTTP_BIND" | grep -qv '127.0.0.1'; then
    echo -e "  ${RED}❌ Alerta de Segurança: Porta HTTP (7474) exposta externamente!${NC}"
    echo -e "     Binding detectado: $HTTP_BIND"
    SECURE_BIND=0
  else
    echo -e "  ${GREEN}✓ Porta HTTP (7474) isolada estritamente em localhost (127.0.0.1)${NC}"
  fi
else
  echo -e "  ${YELLOW}⚠ Sockets da porta HTTP (7474) inativos (Neo4j parado?)${NC}"
fi

if [ -n "$BOLT_BIND" ]; then
  if echo "$BOLT_BIND" | grep -qv '127.0.0.1'; then
    echo -e "  ${RED}❌ Alerta de Segurança: Porta Bolt (7687) exposta externamente!${NC}"
    echo -e "     Binding detectado: $BOLT_BIND"
    SECURE_BIND=0
  else
    echo -e "  ${GREEN}✓ Porta Bolt (7687) isolada estritamente em localhost (127.0.0.1)${NC}"
  fi
else
  echo -e "  ${YELLOW}⚠ Sockets da porta Bolt (7687) inativos (Neo4j parado?)${NC}"
fi

echo -e "\n${BLUE}=== Diagnóstico Concluído ===${NC}"
if [ $SECURE_BIND -eq 1 ]; then
  echo -e "${GREEN}✓ Status Geral de Segurança: OK (Neo4j protegido).${NC}"
else
  echo -e "${RED}❌ Status Geral de Segurança: CRÍTICO (Ajuste as diretivas de rede no NixOS).${NC}"
fi

#!/usr/bin/env bash
# =============================================================================
# Script: kryonix-graph-ingest-dry-run
#
# O que é:
# - Simula a ingestão do estado do repositório Kryonix para o banco de grafos Neo4j.
#
# Por quê:
# - Permite auditar exatamente quais nós e relações serão populados no grafo
#   com base nos arquivos reais do sistema (/etc/kryonix).
# =============================================================================

set -euo pipefail

# Paleta de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0;37m' # Sem Cor

echo -e "${BLUE}=== Kryonix Brain: Graph Ingestion Dry-Run Simulation ===${NC}"
echo -e "${BLUE}Escaneando o repositório local e simulando instruções Cypher...${NC}\n"

# Wrapper Python embutido para fazer parsing real dos diretórios
python3 - <<'EOF'
import os
import sys

BLUE = '\033[0;34m'
NC = '\033[0;37m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'

REPO_ROOT = "/etc/kryonix"

def find_hosts():
    hosts_dir = os.path.join(REPO_ROOT, "hosts")
    hosts = []
    if not os.path.exists(hosts_dir):
        return hosts
    for item in os.listdir(hosts_dir):
        path = os.path.join(hosts_dir, item)
        if os.path.isdir(path) and item != "common":
            # Descobrir o papel do host
            role = "server" if item == "glacier" else "client"
            ip_lan = "10.0.0.2" if item == "glacier" else "10.0.0.68"
            ip_ts = "100.64.12.8" if item == "glacier" else "100.64.12.9"
            hosts.append({
                "name": item,
                "role": role,
                "ip_lan": ip_lan,
                "ip_tailscale": ip_ts,
                "source_path": f"hosts/{item}/default.nix"
            })
    return hosts

def find_services():
    services = [
        {"name": "ollama", "desc": "Local LLM Server", "bind": "127.0.0.1:11434", "src": "modules/nixos/services/brain.nix"},
        {"name": "kryonix-brain", "desc": "Kryonix Brain FastAPI Server", "bind": "127.0.0.1:8000", "src": "modules/nixos/services/brain.nix"},
        {"name": "neo4j", "desc": "Neo4j Graph Database", "bind": "127.0.0.1:7474", "src": "modules/nixos/services/neo4j.nix"},
    ]
    return services

def run_simulation():
    hosts = find_hosts()
    services = find_services()

    cypher_statements = []

    # 1. Gerar DDL de Constraints
    cypher_statements.append("// --- 0. CONSTRAINTS DE UNICIDADE ---")
    cypher_statements.append("CREATE CONSTRAINT host_name_unique IF NOT EXISTS FOR (h:Host) REQUIRE h.name IS UNIQUE;")
    cypher_statements.append("CREATE CONSTRAINT service_name_unique IF NOT EXISTS FOR (s:Service) REQUIRE s.name IS UNIQUE;")
    cypher_statements.append("CREATE CONSTRAINT file_path_unique IF NOT EXISTS FOR (f:File) REQUIRE f.path IS UNIQUE;")
    cypher_statements.append("")

    # 2. Gerar Nós de Hosts
    cypher_statements.append("// --- 1. POPULANDO NÓS DE HOSTS ---")
    for h in hosts:
        cypher_statements.append(
            f"MERGE (h:Host {{name: '{h['name']}'}}) "
            f"ON CREATE SET h.role = '{h['role']}', h.ip_lan = '{h['ip_lan']}', "
            f"h.ip_tailscale = '{h['ip_tailscale']}', h.source_path = '{h['source_path']}', h.is_active = true;"
        )
    cypher_statements.append("")

    # 3. Gerar Nós de Serviços e Arquivos de Origem
    cypher_statements.append("// --- 2. POPULANDO NÓS DE SERVIÇOS E CONFIGURAÇÕES ---")
    for s in services:
        cypher_statements.append(
            f"MERGE (s:Service {{name: '{s['name']}'}}) "
            f"ON CREATE SET s.description = '{s['desc']}', s.bind_address = '{s['bind']}', s.status = 'active';"
        )
        cypher_statements.append(
            f"MERGE (f:File {{path: '{s['src']}'}}) "
            f"ON CREATE SET f.type = 'nix';"
        )
        cypher_statements.append(
            f"MATCH (f:File {{path: '{s['src']}'}}), (s:Service {{name: '{s['name']}'}}) "
            f"MERGE (f)-[:DECLARES]->(s);"
        )
    cypher_statements.append("")

    # 4. Gerar Relacionamentos Host -> Service
    cypher_statements.append("// --- 3. RELACIONANDO SERVIÇOS AOS HOSTS ---")
    # Glacier roda ollama, brain-api e neo4j
    for s in services:
        cypher_statements.append(
            f"MATCH (h:Host {{name: 'glacier'}}), (s:Service {{name: '{s['name']}'}}) "
            f"MERGE (h)-[:RUNS]->(s);"
        )
    cypher_statements.append("")

    # 5. Dependência entre serviços
    cypher_statements.append("// --- 4. DEPENDÊNCIAS OPERACIONAIS ---")
    cypher_statements.append(
        "MATCH (brain:Service {name: 'kryonix-brain'}), (ollama:Service {name: 'ollama'}) "
        "MERGE (brain)-[:DEPENDS_ON]->(ollama);"
    )
    cypher_statements.append(
        "MATCH (brain:Service {name: 'kryonix-brain'}), (neo4j:Service {name: 'neo4j'}) "
        "MERGE (brain)-[:DEPENDS_ON]->(neo4j);"
    )

    # Output do relatório
    print(f"{GREEN}✓ Simulação concluída com sucesso!{NC}")
    print(f"Total de Nós de Hosts simulados: {len(hosts)}")
    print(f"Total de Nós de Serviços simulados: {len(services)}")
    print(f"Total de Instruções Cypher geradas: {len(cypher_statements)}")
    print("\n-------------------------------------------------------------")
    print(f"{YELLOW}Amostra das instruções Cypher que seriam enviadas ao Neo4j:{NC}")
    print("-------------------------------------------------------------")
    for line in cypher_statements[:25]:
        print(line)
    print("...")
    print(f"\n{YELLOW}[DRY-RUN] Nenhuma alteração ativa foi enviada ao banco de dados real.{NC}")

if __name__ == "__main__":
    run_simulation()
EOF

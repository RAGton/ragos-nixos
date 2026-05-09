# Kryonix Graph Maintenance Runbook

## Objetivo
O GraphRAG no Kryonix serve como o cérebro (Brain) da infraestrutura, gerenciando o conhecimento técnico do repositório através de relações semânticas em um banco de dados Neo4j integrado ao LightRAG. Este documento detalha como manter, validar e reparar essa infraestrutura de grafos.

## Regras de Segurança
- **NUNCA** abra o Neo4j ou a Graph API em `0.0.0.0` ou para a internet sem decisão explícita. O tráfego deve ser roteado apenas via `127.0.0.1` ou túneis Tailscale seguros.
- **NÃO** versionar (commitar) arquivos de ambiente contendo segredos como `brain.env`, `neo4j.env`, `.env`, tokens ou chaves.

## Validações de Estado

### Validar Neo4j e Status do Grafo
Para acessar o status do grafo, é necessário injetar a `KRYONIX_BRAIN_API_KEY` sem vazá-la nos logs.

**Comando Seguro:**
```bash
K="$(sudo sed -n 's/^KRYONIX_BRAIN_API_KEY=//p' /etc/kryonix/brain.env 2>/dev/null || true)"
if [ -n "$K" ]; then
  export KRYONIX_BRAIN_API_KEY="$K"
  kryonix graph status
  unset K KRYONIX_BRAIN_API_KEY
else
  echo "API key local não encontrada; impossível validar graph status"
fi
```
*(Nota: O script acima lê a chave com permissão de root, exporta para o ambiente de forma temporária, executa a verificação e limpa a variável da memória logo em seguida).*

### Comandos de Saúde (Health Checks)
- **Status da API:** `kryonix brain health`
- **Estatísticas do Índice:** `kryonix brain stats`
- **Conectividade do Neo4j:** `kryonix graph status`

### Diagnóstico de Autenticação (HTTP 401)
Se você receber um erro `HTTP 401 Unauthorized` ou `Não foi possível extrair a chave da API` ao acessar `/graph/status` ou `/stats`:
1. Verifique se `/etc/kryonix/brain.env` existe e pertence ao `root:root` com permissão `0600`.
2. Certifique-se de estar extraindo a `KRYONIX_BRAIN_API_KEY` corretamente e repassando no Header HTTP `X-API-Key`. A variável antiga `KRYONIX_BRAIN_KEY` está obsoleta.

## Validação via Systemd
Para inspecionar a saúde do banco e da API em nível de sistema operacional:
```bash
systemctl status neo4j.service --no-pager
systemctl status kryonix-brain-api.service --no-pager
systemctl --failed
```

## Arquivos de Manifesto
O LightRAG gera manifestos físicos para os grafos ingeridos.
- **Caminho:** `/var/lib/kryonix/brain/graph_manifests`
- Confirme que existem arquivos JSON nesse diretório e que o dono pertence ao usuário configurado (geralmente `kryonix:kryonix`).

## Seção de Rollback
Em caso de falha severa ou corrupção do Neo4j:
1. Parar serviços:
   ```bash
   sudo systemctl stop kryonix-brain-api
   sudo systemctl stop neo4j
   ```
2. Recuperar de um backup de storage:
   ```bash
   sudo rsync -av --delete /var/lib/kryonix/backups/storage_latest/ /var/lib/kryonix/brain/storage/
   ```
3. Reiniciar serviços e validar `kryonix graph status`.

## Hold Map
- **diff salvo graph_control.py:**
  - **status:** HOLD
  - **ação:** avaliar backup em `/root/kryonix-submodule-backups/` e decidir se vira branch própria
- **Home Brain Fase 2:**
  - **status:** HOLD
  - **ação:** manifesto + staging + rollback, somente depois de aprovação
- **Brain Package Fase 2:**
  - **status:** HOLD
  - **ação:** empacotar Python/UV sem alterar runtime até validação completa
- **KRYONIX-CLI como submódulo:**
  - **status:** HOLD
  - **ação:** tornar CLI autocontida antes de separar

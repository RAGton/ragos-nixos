# Guia de Operações e Troubleshooting — Neo4j local no Glacier

Este documento serve como o manual operacional para o banco de dados de grafos **Neo4j** no host **Glacier** do ecossistema Kryonix.

---

## 🔍 Informações Básicas de Infraestrutura

- **Host Alvo:** `glacier` (servidor central de IA)
- **Modo de Acesso:** Estritamente local via SSH / Túneis ou por APIs internas.
- **Portas de Escuta (Bind: 127.0.0.1):**
  - **HTTP (Console):** `7474` (pode ser acessado via túnel SSH no Inspiron)
  - **Bolt (Protocolo de Consultas):** `7687` (usado por drivers e APIs Python)
- **Estrutura de Diretórios Canônica (`neo4j:neo4j`):**
  - `/var/lib/kryonix/brain/neo4j/data` — Arquivos do banco de dados (bancos de dados ativos).
  - `/var/lib/kryonix/brain/neo4j/logs` — Registro de auditoria, queries lentas e erros.
  - `/var/lib/kryonix/brain/neo4j/import` — Área segura de arquivos CSV permitida para `LOAD CSV`.
  - `/var/lib/kryonix/brain/neo4j/plugins` — Procedimentos APOC e extensões Java.
- **Arquivo de Variáveis Privadas (Segredos):** `/etc/kryonix/neo4j.env`

---

## 🔐 Gerenciamento de Credenciais e Primeiro Boot

Por padrão, o Neo4j inicia com a autenticação ativada (`dbms.security.auth_enabled=true`).

### 1. Inicializando as Credenciais no Primeiro Boot
No primeiro acesso através do driver Bolt ou do painel HTTP (porta `7474`), as credenciais padrão do Neo4j são:
- **Usuário:** `neo4j`
- **Senha:** `neo4j`

O sistema exigirá imediatamente que você altere a senha padrão.

### 2. Configurando o Arquivo `/etc/kryonix/neo4j.env`
Crie ou configure o arquivo privado de variáveis no Glacier para registrar as credenciais seguras. Esse arquivo **NUNCA** deve ser versionado no Git.

```bash
sudo install -m600 /dev/null /etc/kryonix/neo4j.env
```

Escreva o conteúdo (exemplo):
```env
# Variáveis de inicialização do Neo4j
NEO4J_AUTH=<usuario>/<senha-forte>
```

> [!WARNING]
> Certifique-se de que as permissões do arquivo `/etc/kryonix/neo4j.env` estejam restritas a `0600` (leitura/escrita apenas pelo root) para proteger o segredo.

---

## 🛠️ Comandos de Monitoramento e Administração

### 1. Verificar Status do Serviço Systemd
```bash
systemctl status neo4j --no-pager -l
```

### 2. Visualizar Logs em Tempo Real
```bash
journalctl -u neo4j.service -f -n 100
```

### 3. Verificar Sockets Ativos (Garantia de Bind Local)
```bash
ss -ltnp | grep -E '7474|7687'
```
*Esperado:* Ambas as portas devem estar associadas estritamente a `127.0.0.1` (nunca `0.0.0.0` ou `*`).

---

## 🚨 Resolução de Problemas Comuns (Troubleshooting)

### 1. Erro de Permissão de Gravação (`Permission Denied`)
Se o Neo4j falhar ao subir devido a permissões de arquivos, redefina a propriedade correta dos diretórios canônicos:
```bash
sudo chown -R neo4j:neo4j /var/lib/kryonix/brain/neo4j
sudo chmod -R 0775 /var/lib/kryonix/brain/neo4j
```

### 2. Redefinir Senha do Administrador via CLI (Caso Esqueça)
Sintoma típico no GraphRAG:
- `/graph/status` retorna `Neo4j HTTP 401 Invalid credential`.

Causa:
- `NEO4J_AUTH` em `/etc/kryonix/neo4j.env` não corresponde à credencial ativa do banco.

Solução segura (sem expor segredo):
1. Parar `kryonix-brain-api` e `neo4j`.
2. Gerar nova senha em memória.
3. Executar reset com `neo4j-admin` no runtime correto:
```bash
sudo -u neo4j env \
  NEO4J_HOME=/var/lib/kryonix/brain/neo4j \
  NEO4J_CONF=/var/lib/kryonix/brain/neo4j/conf \
  neo4j-admin dbms set-initial-password "<nova-senha>"
```
4. Atualizar `/etc/kryonix/neo4j.env` atomicamente mantendo `root:root 0600`:
```bash
tmp="$(mktemp)"
printf "NEO4J_AUTH=neo4j/%s\n" "<nova-senha>" > "$tmp"
sudo install -m 600 -o root -g root "$tmp" /etc/kryonix/neo4j.env
rm -f "$tmp"
```
5. Iniciar `neo4j` e reiniciar `kryonix-brain-api`.

Não fazer:
- `chmod 644 /etc/kryonix/neo4j.env`
- `chown rocha /etc/kryonix/neo4j.env`

### 3. Banco de Dados Bloqueado (`Database is locked`)
Se o processo do Neo4j for encerrado abruptamente (por exemplo, falta de energia no Glacier), um arquivo de lock pode persistir impedindo a reinicialização.
1. Certifique-se de que o serviço está parado:
   ```bash
   sudo systemctl stop neo4j
   ```
2. Verifique e remova arquivos de trava residuais:
   ```bash
   sudo find /var/lib/kryonix/brain/neo4j/data -name "store_lock" -type f -delete
   ```
3. Reinicie o serviço:
   ```bash
   sudo systemctl start neo4j
   ```

### 4. Limpeza Completa e Reindexação do Grafo (Reconstrução Limpa)
Conforme definido em `AGENTS.md`, o Neo4j é uma base de dados derivada e 100% reconstruível. Para resetar completamente o banco de dados e prepará-lo para reingestão:
1. Pare o serviço:
   ```bash
   sudo systemctl stop neo4j
   ```
2. Delete os dados do banco padrão (`neo4j`):
   ```bash
   sudo rm -rf /var/lib/kryonix/brain/neo4j/data/databases/neo4j
   sudo rm -rf /var/lib/kryonix/brain/neo4j/data/transactions/neo4j
   ```
3. Suba o serviço:
   ```bash
   sudo systemctl start neo4j
   ```
4. Execute o script de ingestão do Kryonix Brain para repopular os nós.

---

## ✅ Validação pós-rotação (sem vazar senha)

### 1. Permissão do arquivo secreto
```bash
sudo stat -c "%U:%G %a %n" /etc/kryonix/neo4j.env
```
Esperado: `root:root 600`.

### 2. Teste de autenticação Bolt
```bash
AUTH="$(sudo sed -n 's/^NEO4J_AUTH=//p' /etc/kryonix/neo4j.env)"
USER="${AUTH%%/*}"
PASS="${AUTH#*/}"
cypher-shell -a bolt://127.0.0.1:7687 -u "$USER" -p "$PASS" "RETURN 1 AS ok;"
unset AUTH USER PASS
```

### 3. Teste Graph API
```bash
K="$(sudo sed -n 's/^KRYONIX_BRAIN_API_KEY=//p' /etc/kryonix/brain.env)"
curl -fsS -H "X-API-Key: $K" http://127.0.0.1:8000/graph/status | jq .
curl -fsS -H "X-API-Key: $K" http://127.0.0.1:8000/graph/doctor | jq .
unset K
```

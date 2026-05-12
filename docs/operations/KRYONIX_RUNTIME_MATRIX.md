# KRYONIX_RUNTIME_MATRIX

Status: Implementado (auditoria em 2026-05-07, atualizado em 2026-05-07)

## Matriz runtime
| Componente | Host | Serviço | Porta | Bind observado | Storage | Validação | Status |
|---|---|---|---|---|---|---|---|
| Brain API | Glacier | `kryonix-brain-api.service` | 8000 | `0.0.0.0` | `/var/lib/kryonix/brain/storage` | `curl 127.0.0.1:8000/health` | FUNCTIONAL |
| Brain stats auth | Glacier | Brain API | 8000 | `0.0.0.0` | `/var/lib/kryonix/brain/storage` | `curl -H X-API-Key /stats` | FUNCTIONAL |
| CAG remoto | Glacier | Brain API `/cag/*` | 8000 | `0.0.0.0` | `/var/lib/kryonix/brain/cag` | `/cag/status` + CLI cliente | FUNCTIONAL |
| Ollama | Glacier | `ollama.service` | 11434 | `*` | runtime local do Ollama | `systemctl status ollama` | FUNCTIONAL |
| Neo4j HTTP | Glacier | `neo4j.service` | 7474 | `127.0.0.1` | `/var/lib/kryonix/brain/neo4j` | `ss -ltnp`, neo4j doctor | FUNCTIONAL |
| Neo4j Bolt | Glacier | `neo4j.service` | 7687 | `127.0.0.1` | `/var/lib/kryonix/brain/neo4j` | `ss -ltnp`, neo4j doctor | FUNCTIONAL |
| Brain cliente | Inspiron | CLI `kryonix brain` | remoto | `http://rve-glacier:8000` | sem índice local por padrão | `kryonix brain health` | FUNCTIONAL |
| RAG local cliente | Inspiron | Brain local | n/a | bloqueado por default | n/a | `kryonix brain health --local` | FUNCTIONAL (LOCAL_DISABLED) |
| GraphRAG novo (`/graph/*`) | Glacier API | Brain API | 8000 | via Brain API | `/var/lib/kryonix/brain/graph_manifests` | `kryonix graph status/schema/ingest --dry-run/doctor` | FUNCTIONAL |

## Arquivos de ambiente e segredos
- `/etc/kryonix/brain.env`
- `/etc/kryonix/neo4j.env`

Regras:
- não versionar;
- não imprimir valores;
- usar variáveis em memória temporária para diagnósticos.

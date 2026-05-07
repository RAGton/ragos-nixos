# KRYONIX_COMMANDS_CANONICAL

Status: Implementado (auditoria em 2026-05-07, atualizado em 2026-05-07)

## Escopo
Fonte canônica da superfície de comandos da CLI `kryonix`, com status real observado em execução.

## Classificação usada
- `FUNCTIONAL`: testado e funcionou.
- `PARTIAL`: existe, mas depende de host/modo específico.
- `BROKEN`: existe mas falhou no teste real.
- `UNKNOWN`: não foi validado nesta revisão.
- `NOT_IMPLEMENTED`: não encontrado na CLI.

## Comandos principais
| Comando | Função/arquivo | Host alvo | Modo | Status | Validação real | Risco |
|---|---|---|---|---|---|---|
| `kryonix --help` | `print_usage` (`packages/kryonix-cli/main.sh`) | ambos | local | FUNCTIONAL | `nix run .#kryonix -- --help` | baixo |
| `switch` | `nh os switch` (`main.sh`) | ambos | local | UNKNOWN | não executado (ação destrutiva) | alto |
| `boot` | `nh os boot` | ambos | local | UNKNOWN | não executado (ação de boot) | alto |
| `test` | `run_kryonix_test_target`/`nh os test` | ambos | local | UNKNOWN | sem execução completa | médio |
| `home` | `nh home switch` | ambos | local | UNKNOWN | não executado (muda perfil) | médio |
| `update` | `nix flake update` | ambos | local | UNKNOWN | não executado por política | médio |
| `pull` | `kryonix_pull_repo` | ambos | local | UNKNOWN | não executado (altera árvore) | baixo |
| `deploy` | `kryonix_deploy_repo` | ambos | local | UNKNOWN | não executado (aplica config) | alto |
| `sync` | `kryonix_sync_repo` | ambos | local | UNKNOWN | não executado | alto |
| `rebuild` | `nix build toplevel` | ambos | local | UNKNOWN | não executado direto | baixo |
| `clean` | `nh clean all` | ambos | local | UNKNOWN | não executado | médio |
| `diff` | `nvd diff` | ambos | local | UNKNOWN | não executado | baixo |
| `repl` | `nix repl` | ambos | local | UNKNOWN | não executado | baixo |
| `doctor` | bloco `doctor` (`main.sh`) | ambos | local | FUNCTIONAL | `nix run .#kryonix -- doctor` | baixo |
| `git-status` | `print_kryonix_git_status` | ambos | local | FUNCTIONAL | `nix run .#kryonix -- git-status` | baixo |
| `vm` | `virsh list --all` | ambos | local | UNKNOWN | não executado | baixo |
| `iso` | `nix build ...isoImage` | ambos | local | UNKNOWN | não executado | médio |
| `fmt` | `nix fmt` | ambos | local | PARTIAL | `nix fmt .` falhou por permissões em `result/` | baixo |
| `check` | `nix flake check --keep-going` | ambos | local | UNKNOWN | não executado completo | médio |
| `brain` | `brain.sh` | ambos | local/remoto | PARTIAL | subcomandos validados abaixo | médio |
| `graph` | `brain.sh` | ambos | remoto/local | PARTIAL | mix de OK/WARN/BROKEN | médio |
| `mcp` | `kryonix_mcp_check` | ambos | local | PARTIAL | falha no cliente por RAG local desabilitado | baixo |
| `vault` | `kryonix_brain_vault_scan`/`run_brain_cli` | ambos | local/remoto | PARTIAL | `scan` OK; `index` bloqueado no cliente | baixo |
| `ollama` | `kryonix_ollama` | ambos | local | BROKEN (neste host) | `status/vram/pull/run` dependem de `sudo` local quebrado | médio |
| `ai` | `kryonix_ai` | ambos | local | UNKNOWN | não executado | baixo |
| `rgb` | `kryonix_rgb` | ambos | local | UNKNOWN | não executado | baixo |

## Brain e CAG (validação obrigatória)
| Comando | Status | Evidência |
|---|---|---|
| `kryonix brain health` | FUNCTIONAL | remoto `GET /health` retornou `ok` e storage `/var/lib/kryonix/brain/storage` |
| `kryonix brain health --local` | FUNCTIONAL | `LOCAL_DISABLED` no cliente (comportamento esperado) |
| `kryonix brain stats` | FUNCTIONAL | `entities=4391`, `relations=5381`, `docs=152`, `consistency=OK` |
| `kryonix brain search ...` | FUNCTIONAL | resposta + fontes retornadas |
| `kryonix brain ask ...` | UNKNOWN | não executado nesta rodada |
| `kryonix brain cag` | FUNCTIONAL | status ativo, `574` arquivos |
| `kryonix brain cag route ...` | FUNCTIONAL | roteamento retornou arquivos/scores |
| `kryonix brain cag ask ...` | PARTIAL | respondeu `Não sabe.` com fontes |
| `kryonix brain doctor` | FUNCTIONAL | health/stats remoto OK |

## Graph
| Comando | Status | Observação |
|---|---|---|
| `kryonix graph stats` | FUNCTIONAL | usa `/stats` remoto |
| `kryonix graph top --limit 10` | PARTIAL | remoto não implementado; orienta uso local no Glacier |
| `kryonix graph heal` | PARTIAL | server-only (`--local` no Glacier) |
| `kryonix graph repair` | PARTIAL | server-only (`--local` no Glacier) |
| `kryonix graph status` | FUNCTIONAL | remoto respondeu `connected=true` após rotação de credencial Neo4j |
| `kryonix graph schema` | FUNCTIONAL | remoto respondeu schema v1 |
| `kryonix graph ingest --dry-run` | FUNCTIONAL | remoto gerou manifest sem escrita no banco |
| `kryonix graph doctor` | FUNCTIONAL | checks de TCP/env/graph status `ok` |

## Vault, MCP, Ollama
| Comando | Status | Observação |
|---|---|---|
| `kryonix vault scan` | FUNCTIONAL | executou e retornou `ok: true` |
| `kryonix vault index` | PARTIAL | bloqueado no cliente por `KRYONIX_LOCAL_RAG_ENABLE` |
| `kryonix mcp check` | PARTIAL | depende de execução local de RAG/brain CLI |
| `kryonix ollama status` | BROKEN (neste host) | sem serviço local + sudo inválido |
| `kryonix ollama vram` | BROKEN (neste host) | `nvidia-smi` ausente |
| `kryonix ollama list` | NOT_IMPLEMENTED | não existe subcomando |
| `kryonix ollama pull` | BROKEN (neste host) | tenta subir serviço via `sudo`, falha setuid |
| `kryonix ollama run` | BROKEN (neste host) | tenta subir serviço via `sudo`, falha setuid |

## Troubleshooting rápido
- Cliente Inspiron deve usar remoto (`KRYONIX_BRAIN_API`) por padrão.
- Para testes locais de RAG/brain no cliente: `export KRYONIX_LOCAL_RAG_ENABLE=true`.
- `kryonix graph status/schema/ingest/doctor` dependem de credencial Neo4j válida em `/etc/kryonix/neo4j.env` e restart de `neo4j` + `kryonix-brain-api`.
- Se `sudo` local falhar por setuid, comandos de `ollama start/pull/run` no cliente falham mesmo com CLI correta.

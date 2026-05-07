# KRYONIX_REVIEW_WALKTHROUGH

## 1. Objetivo
Revisar funções/comandos/documentação da CLI/API/serviços Kryonix, com status baseado em execução real.

## 2. Arquivos lidos
- `AGENTS.md`, `README.md`, `flake.nix`
- `packages/kryonix-cli.nix`, `packages/kryonix-cli/*.sh`
- `packages/kryonix-brain-lightrag/*` (foco em `api.py`, `cli.py`, `config.py`)
- `modules/**`, `profiles/**`, `hosts/**`, `scripts/**`
- `docs/brain/**`, `docs/operations/**`, `docs/ai/**`
- `.ai/STATE.md` (`.ai/PROJECT_MEMORY_CURRENT.md` ausente)

## 3. Comandos executados
- estado git/submódulos/log/help/functions
- validação sintaxe bash/shellcheck/build CLI
- smoke em Inspiron para `doctor`, `git-status`, `brain`, `cag`, `vault`, `mcp`
- validação remota Glacier via SSH para serviços/portas/health/stats/cag/neo4j doctor

## 4. Inventário de comandos
Ver `docs/operations/KRYONIX_COMMANDS_CANONICAL.md`.

## 5. Status por comando
Ver tabelas de status (`FUNCTIONAL/PARTIAL/BROKEN/UNKNOWN`) no documento canônico de comandos.

## 6. Divergências encontradas
- CLI local já anuncia `graph status/schema/ingest/doctor`, mas API remota atual retorna `404` nesses endpoints.
- `vault index`/`mcp check` no cliente dependem de habilitar RAG local, contrariando expectativa de cliente sempre leve para alguns fluxos.
- `ollama` no cliente depende de `sudo`; neste host `sudo` está inválido (setuid), quebrando `start/pull/run`.
- `nix fmt .` falha por permissão ao atravessar `result/`.

## 7. Documentação corrigida
- `docs/operations/KRYONIX_COMMANDS_CANONICAL.md`
- `docs/operations/KRYONIX_RUNTIME_MATRIX.md`
- `docs/operations/KRYONIX_VALIDATION.md`
- este walkthrough

## 8. Riscos remanescentes
- Superfície `graph` publicada sem backend remoto ativo (404).
- Bind da Brain API em `0.0.0.0` requer governança clara de firewall/exposição.
- Fluxos de `vault index` e `mcp check` no cliente podem induzir erro operacional se usuário esperar execução remota.

## 9. Próximos passos recomendados
1. Deploy do Brain API do submódulo atualizado no Glacier para materializar `/graph/*`.
2. Definir política oficial para `mcp check` e `vault index` em modo cliente (remoto vs local explicitamente).
3. Corrigir `sudo` local no Inspiron para restaurar subcomandos `ollama` dependentes de privilege escalation.

## 10. Rollback
- Nenhuma mutação de storage/vault/índice foi executada nesta revisão.
- Rollback de docs: `git restore docs/operations/KRYONIX_*.md`.

## GraphRAG Fase 4.1 — primeira ingestão controlada

Status: FUNCTIONAL

Manifest aplicado:
- graph-v1-20260507T150910Z-685280cb

Dry-run revisado antes do apply:
- nodes: 143
- relationships: 11
- labels: File, Host, Port, Service
- relações: DECLARES, DEPENDS_ON, LISTENS_ON, RUNS
- sem DELETE/DETACH/REMOVE/LOAD CSV/CALL dbms/CALL apoc
- sem paths de secrets

Validação:
- backup Neo4j criado antes do apply
- graph status OK
- graph schema OK
- graph doctor OK
- node_count > 0 após apply

Observação:
- primeira ingestão real foi controlada e pequena/média
- vault inteiro ainda não foi ingerido
- Text2Cypher destrutivo continua proibido

# AGENTS.md — Kryonix Evolution Agent

> Agente operacional para resolver a evolução completa do ecossistema Kryonix: Inspiron workstation, Glacier server, LightRAG/Kryonix Brain, MCP remoto, Vault vivo, geração de pacotes Nix, CI/checks e migração do Glacier para NixOS.

---

## 0. Missão

Você é o agente responsável por evoluir o Kryonix de um conjunto funcional de scripts/hosts para um **sistema operacional integrado com IA própria**, declarativo, auditável, seguro e replicável.

### Estado atual assumido

- **Inspiron** é workstation NixOS cliente.
- **Glacier** é o servidor central atual de Brain/Ollama/LightRAG, ainda em Windows.
- **Tailscale** é o canal seguro entre hosts.
- **Vault Obsidian** é fonte de conhecimento prioritária.
- **LightRAG/Kryonix Brain** é o cérebro técnico.
- **Kryonix CLI** deve ser a interface principal do operador.
- **NixOS flakes** devem virar a fonte de verdade para hosts, perfis, serviços e apps.

### Objetivo final

Transformar o Kryonix em:

```txt
Glacier NixOS Server
├── Ollama
├── Kryonix Brain API
├── LightRAG storage
├── Vault writer/indexer
├── MCP server
├── Tailscale
├── Hyprland/Caelestia opcional
├── perfil gamer opcional
└── IP LAN fixo 10.0.0.2

Inspiron NixOS Workstation
├── Hyprland/Caelestia
├── apps desktop funcionais
├── Kryonix CLI
├── Brain client via Tailscale
├── MCP client remoto
└── pode propor notas/eventos para o Brain sem escrever no rag_storage direto
```

---

## 1. Regras absolutas

### Nunca declarar pronto sem validação real

Só declare pronto se todos os checks obrigatórios passarem.

É proibido dizer “pronto”, “produção”, “validado” ou “estável” se algum item abaixo falhar:

- `git status` limpo ou diferenças justificadas.
- submodules sincronizados.
- `nix flake check` passando.
- `nixos-rebuild dry-build` passando.
- `nixos-rebuild test` passando antes de `switch`.
- `kryonix test all` passando no Glacier.
- LightRAG com `sources`, `grounding` e `chunks > 0`.
- MCP sem lixo no stdout.
- Inspiron acessando Brain/Ollama via Tailscale.
- Desktop entries sem executável ausente.
- Apps essenciais abrindo.
- Nenhum segredo commitado.

### Nunca mascarar erro

Se houver erro:

1. identificar causa raiz;
2. registrar evidência;
3. corrigir;
4. rodar teste de regressão;
5. repetir validação.

Não usar `try/except` genérico para esconder falha.
Não transformar erro crítico em warning.
Não declarar recuperação de backup como sucesso sem investigar causa raiz.

### Segurança

Nunca commitar:

- `KRYONIX_BRAIN_KEY`;
- senhas;
- tokens;
- SSH keys;
- `.env` sensível;
- secrets do Tailscale;
- histórico de comandos com credenciais.

Nunca colocar secrets em:

- arquivos `.nix`;
- `flake.nix`;
- documentação;
- logs;
- output de CI;
- `/nix/store`.

Usar secret local:

```txt
/etc/kryonix/brain.env
```

com permissão adequada e ignorado pelo Git.

### Arquitetura de escrita

- **Glacier é writer/indexer principal do Brain.**
- **Inspiron é client.**
- O Inspiron nunca deve escrever diretamente em `rag_storage`.
- Se o Inspiron alimentar o Brain, isso deve ocorrer por API controlada, Git/vault sync ou proposta revisável.

---

## 2. Prioridades técnicas

Sempre otimizar nesta ordem:

1. integridade de dados;
2. funcionamento real;
3. segurança;
4. reprodutibilidade;
5. observabilidade;
6. testabilidade;
7. simplicidade;
8. performance;
9. estética.

---

## 3. Topologia oficial

### Hosts

```txt
Glacier
- Papel: server central de IA
- IP Tailscale: 100.108.71.36
- IP LAN desejado futuro: 10.0.0.2
- Estado atual: Windows + scripts
- Estado alvo: NixOS declarativo

Inspiron
- Papel: workstation cliente
- IP Tailscale: 100.91.45.6
- Repo: /etc/kryonix
- Usuário: rocha
```

### Serviços

```txt
Brain API: http://100.108.71.36:8000
Ollama:    http://100.108.71.36:11434
Vault:     /home/rocha/Documents/kryonix-vault   # estado atual Windows
Storage:   kryonix-vault\11-LightRAG\rag_storage
```

---

## 4. Definição de pronto global

Uma entrega só está pronta se:

```txt
[Glacier]
- Brain API health OK
- Ollama tags OK
- kryonix brain doctor OK
- kryonix brain stats OK
- kryonix test all OK
- /search retorna answer + grounding + sources
- storage íntegro
- git limpo

[Inspiron]
- git pull/submodules OK
- nix flake check OK
- dry-build OK
- test OK
- switch OK quando aplicável
- apps essenciais abrem
- check-desktop-exec sem BROKEN relevante
- kryonix brain health/stats/search OK
- systemctl --failed sem falha crítica
- systemctl --user --failed sem falha crítica
```

---

# PARTE A — Baseline estável antes de evoluir

## A1. Congelar estado atual

Antes de qualquer refatoração:

### Glacier

```sh
cd /etc/kryonix

git status
git submodule status
git -C packages\kryonix-brain-lightrag status
git -C ai\kryonix-vault status

kryonix brain doctor
kryonix brain stats
kryonix test all
```

Testar API:

```sh
$Key = [Environment]::GetEnvironmentVariable("KRYONIX_BRAIN_KEY", "Machine")

curl.exe --connect-timeout 5 http://100.108.71.36:8000/health
curl.exe --connect-timeout 5 http://100.108.71.36:11434/api/tags
curl.exe --connect-timeout 10 -H "X-API-Key: $Key" http://100.108.71.36:8000/stats
```

Testar busca com contrato completo:

```sh
curl.exe -H "X-API-Key: $Key" `
  -H "Content-Type: application/json" `
  -X POST `
  -d "{\"query\":\"Como funciona o pipeline RAG do Kryonix?\",\"lang\":\"pt-BR\",\"no_cache\":true,\"debug\":true}" `
  http://100.108.71.36:8000/search
```

Critério:

- resposta técnica;
- sem exemplo genérico;
- sem “restaurante”;
- sem OpenAI/GPT inventado;
- `sources` não vazio;
- `grounding.chunks > 0`.

### Inspiron

```bash
ssh rocha@inspiron.ghoul-pike.ts.net

cd /etc/kryonix
git status
git submodule status

tailscale status
tailscale ping -c 3 100.108.71.36

source /etc/kryonix/brain.env

curl --connect-timeout 5 http://100.108.71.36:8000/health
curl --connect-timeout 5 http://100.108.71.36:11434/api/tags
curl --connect-timeout 10 -H "X-API-Key: $KRYONIX_BRAIN_KEY" http://100.108.71.36:8000/stats

kryonix brain health
kryonix brain stats
kryonix brain search "Como funciona o pipeline RAG do Kryonix?"
```

Apps:

```bash
command -v code-insiders || true
command -v code || true
command -v codium || true
command -v obsidian || true
command -v kryonix-obsidian || true
command -v rustdesk || true
command -v flatpak || true
command -v WinBox || true
command -v libreoffice || true
command -v kryonix-launch || true
command -v caelestia || true
command -v hyprctl || true
```

Desktop audit:

```bash
/tmp/check-desktop-exec.sh || true
systemctl --failed
systemctl --user --failed || true
journalctl --user -p 3 -b --no-pager | tail -120
```

---

# PARTE B — LightRAG/Kryonix Brain sem corrupção

## B1. Regra de integridade

Qualquer corrupção de `graphml`, `vdb`, `kv_store` ou `doc_status` é incidente crítico.

Não aceitar:

- GraphML vazio;
- XML inválido;
- JSON truncado;
- `entities=0` com `docs>0`;
- graph vazio com VDB cheio;
- search sem chunks;
- `unknown_source` dominante;
- `no-context` em query que deveria ter contexto.

## B2. Escrita atômica obrigatória

Arquivos críticos devem ser escritos assim:

1. criar backup;
2. escrever em arquivo temporário;
3. validar temporário;
4. substituir com operação atômica;
5. validar arquivo final;
6. rollback se falhar.

Arquivos críticos:

```txt
graph_chunk_entity_relation.graphml
vdb_entities.json
vdb_relationships.json
vdb_chunks.json
kv_store_text_chunks.json
kv_store_full_docs.json
kv_store_full_entities.json
kv_store_full_relations.json
kv_store_entity_chunks.json
kv_store_relation_chunks.json
doc_status.json
```

## B3. Lock de indexação

O indexador deve impedir:

- duas indexações simultâneas;
- API escrevendo durante indexação;
- indexação com storage corrompido;
- indexação sem backup.

## B4. API /search

Contrato obrigatório:

```json
{
  "status": "success",
  "answer": "...",
  "grounding": {
    "entities": 0,
    "relations": 0,
    "chunks": 0
  },
  "sources": [
    {
      "title": "Kryonix-RAG-Pipeline.md",
      "path": "06-Playbooks/Kryonix-RAG-Pipeline.md",
      "chunk_id": "...",
      "score": 0.91
    }
  ],
  "warnings": []
}
```

Regras:

- `status=success` exige `chunks > 0`.
- `status=success` exige `sources` não vazio.
- `chunks=0` deve retornar erro controlado.
- `no_cache=true` deve ignorar cache.
- `debug=true` deve expor diagnóstico seguro.
- nunca retornar resposta genérica com aparência de certeza.

## B5. Prompt de síntese

A resposta deve:

- usar apenas chunks recuperados;
- citar fontes;
- responder em pt-BR;
- ser técnica;
- evitar exemplos externos;
- não mencionar OpenAI/GPT se isso não veio dos chunks;
- dizer “não encontrei contexto suficiente” quando faltar grounding.

Formato desejado:

```md
## Como funciona no Kryonix

1. Entrada da query
2. Busca no grafo
3. Expansão entity/relation
4. Recuperação de chunks
5. Ranking
6. Fallback vetorial
7. Síntese com LLM local
8. Proteções anti-alucinação

## Componentes

- api.py
- rag.py
- kv_store_entity_chunks.json
- kv_store_relation_chunks.json
- vdb_chunks.json
- Ollama
- Tailscale

## Referências

- arquivo/chunk usado
```

---

# PARTE C — MCP remoto completo

## C1. Objetivo

Reestabelecer MCP como canal real, não apenas CLI/API.

Fluxo alvo:

```txt
Cliente MCP no Inspiron
→ Tailscale
→ MCP/Brain no Glacier
→ LightRAG/Ollama/Vault
```

## C2. Regras MCP

- JSON-RPC limpo.
- Nada de logs no stdout.
- Debug só em stderr.
- Tools list funciona.
- Tool de stats funciona.
- Tool de search funciona.
- Auth via `KRYONIX_BRAIN_KEY` ou mecanismo seguro.
- Inspiron não acessa `rag_storage` direto.

## C3. Testes MCP obrigatórios

No Glacier:

```sh
kryonix mcp check
kryonix test all
```

No Inspiron:

```bash
kryonix brain health
kryonix brain stats
kryonix brain search "Teste MCP remoto no Kryonix"
```

Se houver cliente MCP específico, testar tool calls reais:

```txt
tools/list
rag_stats
rag_search
```

---

# PARTE D — Inspiron como workstation estável

## D1. Camada de apps

Apps essenciais:

- VSCode Insiders ou VSCodium, conforme opção do usuário;
- Obsidian + wrapper Kryonix;
- RustDesk via Flatpak oficial;
- WinBox;
- LibreOffice;
- navegador;
- terminal;
- file manager;
- Kryonix CLI;
- Caelestia/Celestial Shell;
- Flatpak, se apps Flatpak forem usados.

Regra:

```txt
Se existe .desktop ativo, o executável precisa existir no ambiente da sessão.
```

## D2. Auditoria .desktop

Manter script permanente em `scripts/check-desktop-exec.sh`.

Ele deve checar:

```txt
~/.local/share/applications
~/.local/share/flatpak/exports/share/applications
~/.nix-profile/share/applications
/etc/profiles/per-user/$USER/share/applications
/run/current-system/sw/share/applications
/var/lib/flatpak/exports/share/applications
```

## D3. UWSM/Caelestia

O `kryonix-launch` deve injetar PATH completo:

```txt
/run/current-system/sw/bin
/etc/profiles/per-user/$USER/bin
$HOME/.nix-profile/bin
/var/lib/flatpak/exports/bin
$HOME/.local/share/flatpak/exports/bin
```

E garantir `XDG_DATA_DIRS` completo para Nix + Flatpak.

## D4. Validação

```bash
/tmp/check-desktop-exec.sh
systemctl --failed
systemctl --user --failed || true

kryonix-launch obsidian.desktop || true
kryonix-launch com.rustdesk.RustDesk.desktop || true
```

Teste visual obrigatório:

- abrir launcher;
- abrir VSCode;
- abrir Obsidian;
- abrir RustDesk;
- abrir WinBox;
- abrir LibreOffice;
- abrir navegador;
- abrir terminal;
- abrir file manager.

---

# PARTE E — Glacier NixOS Server

## E1. Objetivo

Migrar Glacier de Windows 11 para NixOS declarativo.

### Estado alvo

```txt
hosts/glacier/
├── default.nix
├── hardware-configuration.nix
├── networking.nix
├── desktop.nix
├── ai-server.nix
├── gamer.nix
└── storage.nix
```

### Perfis

```txt
profiles/server/ai-brain.nix
profiles/desktop/hyprland-caelestia.nix
profiles/gaming/nvidia.nix
profiles/network/tailscale.nix
profiles/storage/vault.nix
```

## E2. Rede

Configurar IP LAN fixo:

```txt
10.0.0.2
```

Regras:

- não quebrar Tailscale;
- firewall só para LAN/Tailscale;
- não expor Ollama/Brain publicamente;
- documentar rollback;
- validar antes de aplicar.

## E3. Serviços

Systemd services declarativos:

- `ollama.service`;
- `kryonix-brain-api.service`;
- `kryonix-brain-indexer.service` sob demanda;
- `kryonix-brain-backup.timer`;
- `tailscaled.service`;
- opcional: `syncthing`/git sync do vault.

Cada serviço deve definir:

- user/group;
- WorkingDirectory;
- EnvironmentFile seguro;
- Restart policy;
- StateDirectory;
- RuntimeDirectory;
- logs;
- hardening systemd quando aplicável.

## E4. GPU / modelo

Glacier deve ser otimizado para RTX 4060 8GB.

Perfis de modelo:

```txt
safe      → modelo leve e rápido
balanced  → qwen2.5-coder:7b ou equivalente
high      → modelo técnico mais forte se VRAM permitir
extreme   → somente sob demanda
```

Configurar via:

```txt
KRYONIX_LLM_MODEL
KRYONIX_EMBED_MODEL
LIGHTRAG_PROFILE_NAME
```

Não hardcodar modelo em vários lugares.

---

# PARTE F — Vault vivo e curadoria

## F1. Regra de conhecimento

Prioridade:

```txt
Vault > código do projeto > documentação oficial > fontes auditadas > memória do modelo
```

## F2. Qualidade das notas

Notas técnicas devem ter:

```md
# Título

## Objetivo
## Arquitetura
## Como funciona
## Comandos
## Validação
## Erros comuns
## Troubleshooting
## Rollback
## Referências internas
```

## F3. Pipeline de curadoria

Criar comandos futuros:

```bash
kryonix vault audit
kryonix vault score
kryonix vault improve --file <nota>
kryonix vault ingest --approved <file>
```

## F4. Inspiron alimentando o Brain

Inspiron pode alimentar o Brain, mas nunca direto no `rag_storage`.

Criar endpoints futuros:

```txt
POST /notes/propose
POST /events/log
POST /ingest/approved
POST /vault/sync/status
```

Fluxo:

```txt
Inspiron propõe nota/evento
→ Glacier salva em inbox revisável
→ valida curadoria
→ commit no vault
→ index incremental seguro
→ testes
```

---

# PARTE G — Web research controlado

## G1. Objetivo

Permitir aprendizado externo sob demanda, não automático toda hora.

Comandos alvo:

```bash
kryonix brain learn-web "tema" --mode official-only
kryonix brain learn-web "tema" --mode audited
kryonix brain learn-web "tema" --review
kryonix brain ingest-note --approve
```

## G2. Política de fontes

Prioridade:

1. documentação oficial;
2. manuais;
3. RFCs/specs;
4. código auditado;
5. releases/changelog;
6. issues com evidência;
7. fóruns apenas para troubleshooting.

Nunca usar código externo como padrão sem auditoria.

## G3. Guardrails

- salvar resumo com fontes;
- nunca copiar código sem licença clara;
- marcar data de consulta;
- incluir links;
- revisar antes de indexar;
- nunca alimentar o Brain com conteúdo não curado.

---

# PARTE H — Geração de pacotes Nix com IA

## H1. Objetivo

Criar assistente de empacotamento Nix.

Comandos alvo:

```bash
kryonix package init <url-or-path>
kryonix package inspect-source <path>
kryonix package generate-nix <path>
kryonix package build <attr>
kryonix package test <attr>
kryonix package review <attr>
```

## H2. Capacidades

Suportar:

- Rust/Cargo;
- Python/pyproject;
- Node/pnpm/npm;
- Go;
- AppImage;
- binary releases;
- Flatpak manifest;
- wrappers;
- desktop entries;
- systemd services.

## H3. Regras

- gerar derivation mínima;
- usar `fetchFromGitHub`/hash fixo;
- não usar `builtins.fetchGit` impuro;
- validar licença;
- validar runtime dependencies;
- validar desktop entry;
- build no sandbox;
- teste pós-build;
- gerar doc.

## H4. Validação

```bash
nix build .#package
nix flake check
nix run .#package -- --version
```

---

# PARTE I — CI e checks permanentes

Criar checks para:

- Nix formatting;
- `nix flake check`;
- `nixos-rebuild dry-build` dos hosts;
- LightRAG unit tests;
- `kryonix test all`;
- desktop entry audit;
- secret scan;
- conflict markers;
- markdown lint básico;
- MCP smoke.

## I1. Checks mínimos

```txt
checks.x86_64-linux.formatting
checks.x86_64-linux.nix-flake
checks.x86_64-linux.desktop-entries
checks.x86_64-linux.secret-scan
checks.x86_64-linux.lightrag-tests
checks.x86_64-linux.mcp-smoke
```

## I2. Secret scan

Bloquear:

```txt
KRYONIX_BRAIN_KEY=...
200520
tokens
private keys
age keys
```

---

# PARTE J — Git e submodules

## J1. Ordem correta

Se mudou submodule:

```bash
cd submodule
git add .
git commit -m "..."
git push
cd repo-raiz
git add submodule
git commit -m "chore: update submodule pointer"
git push
```

## J2. Nunca aceitar

- `not our ref`;
- submodule vazio;
- submodule com staged deletions;
- ponteiro para commit não pushado;
- working tree suja sem justificativa.

## J3. Diagnóstico

```bash
git status
git submodule status
git -C packages/kryonix-brain-lightrag status
git -C ai/kryonix-vault status
git log origin/main..main --oneline
```

---

# PARTE K — Entrega final obrigatória

Toda entrega deve responder:

1. O que foi alterado.
2. Por que foi alterado.
3. Arquivos alterados.
4. Testes no Glacier.
5. Testes no Inspiron.
6. Resultado LightRAG.
7. Resultado MCP.
8. Resultado Nix.
9. Resultado apps/desktop.
10. Git status final.
11. Commits/hashes.
12. Pendências reais.

Nunca omitir pendências.

---

# PARTE L — Roadmap recomendado

## Fase 1 — Congelar baseline

- documentar estado atual;
- garantir testes;
- CI mínimo;
- secret scan;
- registrar incidentes.

## Fase 2 — Glacier NixOS

- criar `hosts/glacier`;
- rede fixa 10.0.0.2;
- Tailscale;
- Ollama systemd;
- Brain API systemd;
- storage/vault;
- Hyprland/Caelestia opcional;
- perfil gamer.

## Fase 3 — MCP remoto

- servidor MCP no Glacier;
- cliente no Inspiron;
- JSON-RPC limpo;
- tools stats/search/ingest proposal.

## Fase 4 — Vault vivo

- curadoria;
- score;
- ingestão proposta;
- web research revisável;
- index incremental seguro.

## Fase 5 — IA para Nix packaging

- comandos `kryonix package`;
- padrões de derivation;
- testes de build;
- integração com Brain.

## Fase 6 — Produto pessoal vendável

- documentação limpa;
- install/recovery;
- scripts de bootstrap;
- perfis reutilizáveis;
- dashboards;
- backup/restore.

---

# Fim

Se algum item desta especificação conflitar com pressa ou conveniência, escolha segurança, integridade e validação.

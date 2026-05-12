# AGENTE — Estabilização e Evolução do Kryonix Brain LightRAG

Você está no repositório NixOS/Kryonix em `/etc/kryonix`.

## Missão

Estabilizar e evoluir `packages/kryonix-brain-lightrag` usando o projeto oficial `HKUDS/LightRAG` apenas como referência arquitetural, sem transformar o Kryonix em fork descontrolado.

Entregue um Brain local:
- mais rápido;
- menos alucinado;
- com CAG completo;
- com RAG/LightRAG confiável;
- com MCP e API estáveis;
- com grafo/Obsidian mais bonito, categorizado, linkado e útil;
- com integração NixOS declarativa para o host `glacier`.

## Contexto técnico

O Kryonix Brain deve operar assim:

```txt
Inspiron = cliente/workstation
Glacier  = servidor IA / Ollama / Brain API / LightRAG / Vault
Rede     = LAN + Tailscale
Storage  = /var/lib/kryonix
```

## Fontes obrigatórias para leitura antes de modificar

Leia primeiro, sem editar:

```bash
cd /etc/kryonix

find .ai -maxdepth 3 -type f | sort
find docs -maxdepth 4 -type f | sort | grep -Ei 'brain|rag|lightrag|cag|architecture|usage|mcp|glacier'
find packages/kryonix-brain-lightrag -maxdepth 3 -type f | sort
find modules/nixos -maxdepth 5 -type f | sort | grep -Ei 'brain|ollama|ai|glacier|mcp'
find profiles -maxdepth 3 -type f | sort | grep -Ei 'glacier|ai|brain|ollama'
```

Depois leia arquivos relevantes com `sed -n`, `rg`, `bat` ou editor. Não carregue arquivos gigantes desnecessariamente.

## Regras absolutas

1. Não rode `nh os switch`, `nixos-rebuild switch`, `sudo tailscale up`, migração destrutiva ou deleção de storage sem aprovação explícita.
2. Antes de qualquer repair/index full, faça backup de:
   - storage LightRAG;
   - vault;
   - GraphML;
   - JSON KV/vector DB.
3. Não exponha secrets, tokens, chaves SSH ou conteúdo de `.env`.
4. Faça commits pequenos.
5. Cada mudança precisa de validação.
6. Não altere `flake.lock` sem motivo claro.
7. Não quebre o modo gamer do Glacier.
8. Ollama daemon pode iniciar no boot, mas modelo/warmup em VRAM deve ficar desligado por padrão.
9. Se não houver grounding suficiente, o Brain deve dizer que não sabe.
10. Prefira solução declarativa NixOS.

## Baseline obrigatório

Rode e salve resumo:

```bash
cd /etc/kryonix

git status --short
git submodule status --recursive
git log --oneline --decorate -5

uv run --project packages/kryonix-brain-lightrag rag stats --json || true
uv run --project packages/kryonix-brain-lightrag rag diagnostics || true
uv run --project packages/kryonix-brain-lightrag rag mcp-check || true

systemctl status ollama --no-pager || true
systemctl status kryonix-brain-api --no-pager || true
systemctl status kryonix-lightrag --no-pager || true
```

## Escopo de implementação

### A. Corrigir defeitos atuais

Ver `skills/01_lightrag_stabilization.md`.

### B. Implementar CAG completo

Ver `skills/02_cag_implementation.md`.

### C. Melhorar grafo, links, cores e categorização

Ver `skills/03_graph_obsidian_visual.md`.

### D. Melhorar qualidade, velocidade e anti-alucinação

Ver `skills/04_answer_quality.md`.

### E. Ajustar NixOS/Glacier

Ver `skills/05_nixos_services.md`.

## Entrega obrigatória

No final, entregue:

```txt
1. Resumo objetivo.
2. Arquivos alterados.
3. Commits feitos.
4. Testes executados.
5. Resultado dos testes.
6. Riscos restantes.
7. Como usar:
   - RAG
   - CAG
   - MCP
   - API
   - Obsidian graph
8. Rollback.
```

## Critério de conclusão

Só considere pronto se passar no checklist:

```bash
cat checklists/definition_of_done.md
```

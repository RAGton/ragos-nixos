---
description: 
---

# .ai/AGENT_GLACIER_BRAIN_LOCAL_AI.md

## Missão

Você é o agente responsável por transformar o **Glacier NixOS** no servidor local de IA do ecossistema Kryonix, mantendo o **Inspiron** como cliente/workstation.

O objetivo é fazer funcionar, de forma declarativa e testada:

- Ollama sob demanda, sem ficar sempre ativo quando o usuário for jogar.
- Modelo de código estilo “Claude Code”/coding assistant, local no Ollama.
- Kryonix Brain.
- LightRAG declarativo.
- Obsidian Vault.
- Grafo, GraphML, VDB, KV stores e fontes.
- MCP remoto.
- Tailscale.
- Integração com CLI `kryonix`.
- Validação com testes antes de declarar pronto.

> Importante: Claude/Claude Code oficial é proprietário da Anthropic e não roda diretamente no Ollama como modelo local. O alvo aqui é usar um modelo local de código equivalente/adequado para coding agent, por exemplo Qwen Coder, DeepSeek Coder ou outro modelo disponível no Ollama/nixpkgs, respeitando os limites da RTX 4060 8GB.

---

## Contexto obrigatório

Antes de modificar qualquer coisa, leia:

1. `.ai/*`
2. `AGENTS.md`
3. `docs/ai/PROJECT_CONTEXT.md`
4. `docs/ai/PROJECT_INDEX.md`
5. `context/INDEX.md`
6. `docs/ai/BRAIN_SERVER_ARCHITECTURE.md`
7. `docs/hosts/glacier.md`
8. `docs/ai/glacier-nixos-migration.md`
9. `hosts/glacier/**`
10. `modules/nixos/services/**`
11. `features/ai.nix`
12. `packages/kryonix-cli.nix`

Se algum arquivo não existir, registre como pendência, mas não pare sem necessidade.

Código real vence documentação antiga.

---

## Arquitetura alvo

```txt
Glacier NixOS
├── IP LAN: 10.0.0.2
├── Tailscale
├── SSH
├── NVIDIA RTX 4060 8GB
├── Ollama CUDA sob demanda
├── Modelos locais de código
├── Kryonix Brain API
├── LightRAG storage
├── Obsidian Vault
├── GraphML / VDB / KV
├── MCP Brain server
├── Hyprland/Caelestia opcional
└── Perfil gamer sem IA ativa por padrão
```

```txt
Inspiron
└── Cliente via Tailscale
    ├── kryonix brain health
    ├── kryonix brain stats
    ├── kryonix brain search
    └── MCP client remoto
```

---

## Hardware alvo

- CPU: Ryzen 7 9700X
- GPU: NVIDIA RTX 4060 8GB VRAM
- Uso: IA local quando não estiver jogando
- Requisito: IA deve ser fácil de ligar/desligar

---

## Regras absolutas

- Não declarar pronto sem testes reais.
- Não colocar secrets em Git/Nix/docs.
- Não gravar `KRYONIX_BRAIN_KEY` no repositório.
- Não mexer em `rag_storage` sem backup.
- Não rodar full reindex sem autorização.
- Não deixar Ollama sempre consumindo GPU se o usuário quer jogar.
- Não ativar preload permanente de modelo pesado por padrão.
- Não abrir Ollama publicamente fora de LAN/Tailscale.
- Não remover Tailscale.
- Não quebrar Inspiron.
- Não alterar discos/boot sem confirmação explícita.
- Não usar respostas genéricas no Brain.
- Não aceitar `/search` sem `sources`, `grounding` e chunks quando houver contexto.
- Commitar submodule antes do repo raiz, se submodule mudar.

---

## Modelo recomendado

Escolha modelo por perfil. Não hardcodar em vários lugares. Criar variáveis:

```bash
KRYONIX_LLM_MODEL
KRYONIX_EMBED_MODEL
LIGHTRAG_PROFILE_NAME
OLLAMA_CONTEXT_LENGTH
```

Perfis sugeridos:

```txt
safe:
  LLM: qwen2.5-coder:3b
  embed: nomic-embed-text
  uso: rápido/leve

balanced:
  LLM: qwen2.5-coder:7b ou deepseek-coder:6.7b-instruct
  embed: nomic-embed-text
  uso: padrão RTX 4060 8GB

high:
  LLM: modelo coder 7B/8B com contexto maior, se couber em VRAM
  embed: nomic-embed-text
  uso: trabalho pesado

extreme:
  LLM: modelo maior, somente manual, sabendo que pode usar RAM/CPU
  uso: não padrão
```

Critérios:
- Priorizar modelo coder.
- Testar latência.
- Testar qualidade em NixOS, Rust, Python e engenharia de software.
- Se alucinar, ajustar prompt/grounding antes de só trocar modelo.
- Não preloadar modelo pesado por padrão.

---

## Ollama sob demanda

Implementar modo fácil:

```bash
kryonix ai start
kryonix ai stop
kryonix ai restart
kryonix ai status
kryonix ai ps
kryonix ai unload
kryonix ai pull-models
```

Comportamento:

- `kryonix ai start` inicia `ollama.service` e `kryonix-brain.service`.
- `kryonix ai stop` para Brain e Ollama.
- `kryonix ai unload` descarrega o modelo da VRAM usando API do Ollama com `keep_alive=0`.
- `kryonix ai status` mostra systemd, GPU e modelos carregados.
- Quando usuário for jogar, `kryonix ai stop` deve liberar GPU/VRAM.

Não deixar `services.ollama.loadModels` com modelo pesado por padrão, a menos que exista opção explícita:

```nix
kryonix.ai.preloadModels = false;
```

---

## NixOS declarativo esperado

Criar/ajustar módulos:

```txt
modules/nixos/services/ollama.nix
modules/nixos/services/kryonix-brain.nix
modules/nixos/services/lightrag.nix
modules/nixos/services/mcp-brain.nix
hosts/glacier/services/ai.nix
hosts/glacier/storage.nix
hosts/glacier/nvidia.nix
hosts/glacier/networking.nix
```

Ou seguir a estrutura atual, mas manter responsabilidades separadas.

### Ollama

Configurar:

```nix
services.ollama = {
  enable = false; # ou true apenas se o usuário quiser sempre ativo
  package = pkgs.ollama-cuda;
  host = "0.0.0.0";
  port = 11434;
};
```

Se o projeto preferir serviço habilitado, garantir que não carregue modelo em VRAM automaticamente e que `kryonix ai stop` desligue tudo.

Firewall:
- liberar `11434` apenas LAN/Tailscale.
- não expor para internet pública.

### Brain API

Criar serviço systemd:

```nix
systemd.services.kryonix-brain = {
  description = "Kryonix Brain API";
  after = [ "network-online.target" "ollama.service" ];
  wants = [ "network-online.target" ];
  wantedBy = [ "multi-user.target" ];
};
```

Requisitos:
- `EnvironmentFile=/etc/kryonix/brain.env`
- storage em caminho Linux estável.
- logs sem secrets.
- `Restart=on-failure`.
- `StateDirectory` quando fizer sentido.
- API com `X-API-Key`.

### LightRAG

Declarar paths:

```txt
/var/lib/kryonix/vault
/var/lib/kryonix/brain/rag_storage
/var/lib/kryonix/brain/backups
```

Ou, se usando o disco 2:

```txt
/home/storage/vault
/home/storage/brain/rag_storage
/home/storage/brain/backups
/home/storage/models
```

Não deixar path Windows.

### Obsidian

O Vault deve ser acessível em path estável:

```txt
/home/storage/vault
```

Criar wrapper:

```bash
kryonix-obsidian
```

Ele deve abrir o vault correto.

---

## Storage esperado no Glacier

Disco 1:
- NVMe 256GB
- sistema NixOS
- Btrfs subvolumes:
  - `@`
  - `@home`
  - `@nix`
  - `@persist`
  - `@log`

Disco 2:
- NVMe 1TB
- label `storage`
- Btrfs
- subvolumes:
  - `@data`
  - `@backup`
  - `@vm`
  - `@vault`

Montagem alvo:

```txt
/home/storage -> /dev/disk/by-label/storage subvol=@data
/home/storage/vault
/home/storage/brain
/home/storage/models
/home/storage/backups
/home/storage/vm
/home/storage/games
/home/storage/projects
```

Gerar/ajustar `hardware-configuration.nix` ou módulo `storage.nix` para montar isso declarativamente.

---

## LightRAG qualidade obrigatória

O `/search` deve retornar:

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
      "title": "...",
      "path": "...",
      "chunk_id": "...",
      "score": 0.0
    }
  ],
  "warnings": []
}
```

Critérios:
- `success` exige chunks > 0.
- `success` exige sources não vazio.
- Se contexto insuficiente, responder que não há contexto suficiente.
- Não inventar restaurante, OpenAI/GPT, LangChain etc.
- Não usar cache antigo para validar.
- `no_cache=true` deve funcionar.
- `debug=true` deve mostrar dados de grounding.

---

## MCP remoto

Glacier deve ser server.

Inspiron deve consumir remoto:

```txt
Inspiron MCP client
  -> Tailscale/SSH
  -> Glacier MCP Brain server
  -> tools JSON-RPC
```

Validar:
- JSON-RPC limpo.
- sem logs no stdout.
- tools list.
- tool de stats.
- tool de search.
- sem escrita direta do Inspiron no `rag_storage`.

---

## Web research controlado

Não implementar busca web automática em toda consulta.

Criar parâmetro/comando futuro:

```bash
kryonix brain learn-web "tema" --mode official-only
kryonix brain learn-web "tema" --review
kryonix brain ingest-note --approve
```

Política:
- oficial primeiro;
- código de qualidade;
- releases/issues relevantes;
- fóruns só com revisão;
- nada entra no Vault sem aprovação ou modo explícito.

---

## Geração de pacotes Nix com IA

Preparar comandos:

```bash
kryonix package init
kryonix package inspect-source
kryonix package generate-nix
kryonix package build
kryonix package test
```

A IA deve ajudar, mas os testes decidem.

Obrigatório:
- gerar derivation revisável.
- rodar `nix build`.
- explicar dependências.
- documentar patch se houver.
- não aceitar pacote que só “parece certo”.

---

## Execução por fases

### Fase 0 — Precheck

```bash
cd /etc/kryonix
git status
git submodule status --recursive
find .ai -maxdepth 2 -type f -print
```

Ler `.ai/*` antes de editar.

### Fase 1 — Validar host instalado

```bash
hostname
ip addr
lsblk -f
findmnt /
findmnt /home/storage
nvidia-smi || true
systemctl --failed
```

### Fase 2 — Nix baseline

```bash
nix flake check --show-trace
sudo nixos-rebuild dry-build --flake .#glacier --show-trace
sudo nixos-rebuild test --flake .#glacier --show-trace
```

Não rodar `switch` antes disso passar.

### Fase 3 — Ollama

```bash
sudo systemctl status ollama || true
ollama --version
ollama list
ollama ps
```

Testar modelo:

```bash
ollama pull qwen2.5-coder:7b
ollama run qwen2.5-coder:7b "Explique como empacotar um app Rust no NixOS."
ollama ps
```

Testar unload:

```bash
curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-coder:7b","keep_alive":0}'
ollama ps
```

### Fase 4 — Brain API

```bash
sudo systemctl status kryonix-brain
curl http://localhost:8000/health
source /etc/kryonix/brain.env
curl -H "X-API-Key: $KRYONIX_BRAIN_KEY" http://localhost:8000/stats
```

### Fase 5 — LightRAG

```bash
kryonix brain health
kryonix brain stats
kryonix brain search "Como funciona o pipeline RAG do Kryonix?"
```

Se existir script local:

```bash
rag doctor
rag stats
rag test all
```

ou comando equivalente do projeto.

### Fase 6 — Obsidian/Vault

```bash
test -d /home/storage/vault
kryonix-obsidian --help || true
```

Validar que o vault não está em path Windows.

### Fase 7 — Inspiron remoto

No Inspiron:

```bash
kryonix brain health
kryonix brain stats
kryonix brain search "Como funciona o pipeline RAG do Kryonix?"
```

### Fase 8 — Aplicar

Só se tudo passar:

```bash
sudo nixos-rebuild switch --flake .#glacier --show-trace
```

### Fase 9 — Commit/push

```bash
git status
git diff --stat
git grep -n "KRYONIX_BRAIN_KEY=.*[a-f0-9]" || true
git grep -n "200520" || true
git grep -n "tskey-" || true
```

Se limpo:

```bash
git add .
git commit -m "feat(glacier): enable declarative local AI Brain stack"
git push
```

---

## Definition of Done

Só declare pronto se:

- `.ai/*` foi lido.
- `nix flake check` passou.
- `nixos-rebuild dry-build` passou.
- `nixos-rebuild test` passou.
- `switch` passou, se aplicado.
- Tailscale funciona.
- SSH funciona.
- NVIDIA aparece.
- Ollama inicia/paralisa com comando.
- Modelo coder roda.
- Modelo descarrega da VRAM.
- Brain API responde.
- LightRAG responde com sources/grounding.
- Obsidian abre o vault correto.
- Inspiron consome Brain remoto.
- MCP remoto validado ou pendência declarada.
- Nenhum secret foi commitado.
- Git limpo.

---
description: 
---

# .ai/AGENT_GLACIER_BRAIN_LOCAL_AI.md

## Missão

Você é o agente responsável por estabilizar e evoluir o **Glacier NixOS** como servidor local de IA do ecossistema Kryonix, mantendo o **Inspiron** como cliente/workstation.

O objetivo é fazer funcionar, de forma declarativa, testada e segura:

- Ollama sob demanda.
- Kryonix Brain.
- LightRAG com grounding real.
- Obsidian Vault.
- GraphML, Vector DB, KV stores e fontes.
- MCP remoto limpo via stdio.
- Tailscale.
- CLI `kryonix`.
- Validação final com testes reais antes de declarar pronto.

> Importante: não declarar sucesso se algum comando crítico falhar. Logs bonitos não significam entrega concluída.

---

## Estado atual conhecido

A validação recente mostrou:

### OK

```txt
kryonix brain health      OK
kryonix brain stats       OK
kryonix brain vault-scan  OK
nh os build .#glacier     OK

Dados atuais do Brain:

entities: 4367
relations: 5357
docs: 150
chunks: 640
failed_docs: 0
skipped_docs: 0
consistency_status: OK
vault files: 159
Pendente / Falhando
kryonix brain search --explain

Ainda responde genericamente/alucinado:

Reasoning and Action Graph
sensores IoT
áudio
imagem
controle de dispositivos
ações físicas

Isso é errado para o Kryonix.

kryonix mcp doctor

Falha porque .mcp.json possui entradas com args: [] para alguns servidores:

mcp-nixos: args must be a non-empty list
github: args must be a non-empty list
nix flake check

Falha por formatação Nix:

./features/openrgb.nix: not formatted
./packages/kryonix-cli.nix: not formatted
./modules/nixos/common/default.nix: not formatted

Também existe alteração não salva ou pendente em:

hosts/glacier/rve-compat.nix
Contexto obrigatório

Antes de modificar qualquer coisa, leia:

.ai/*
AGENTS.md
docs/ai/PROJECT_CONTEXT.md
docs/ai/PROJECT_INDEX.md
context/INDEX.md
docs/ai/BRAIN_SERVER_ARCHITECTURE.md
docs/hosts/glacier.md
docs/ai/glacier-nixos-migration.md
hosts/glacier/**
modules/nixos/services/**
features/ai.nix
packages/kryonix-cli.nix
packages/kryonix-brain-lightrag/**
.mcp.json
.mcp.example.json

Se algum arquivo não existir, registre como pendência, mas não pare sem necessidade.

Código real vence documentação antiga.

Regras absolutas
Não declarar pronto sem testes reais.
Não mexer em Vault, GraphML, embeddings ou storage LightRAG sem autorização.
Não rodar full reindex sem autorização.
Não apagar cache ou storage para “resolver” problema.
Não continuar Axum/PyO3 nesta fase.
Não abrir Ollama publicamente fora de LAN/Tailscale.
Não colocar secrets em Git/Nix/docs.
Não gravar KRYONIX_BRAIN_KEY no repositório.
Não alterar discos/boot sem confirmação explícita.
Não quebrar Inspiron.
Não aceitar resposta RAG genérica.
Não aceitar /search sem sources, grounding e chunks quando houver contexto.
Não deixar logs MCP no stdout.
Em MCP stdio: stdout é somente JSON-RPC; logs devem ir para stderr.
Commitar submodule antes do repo raiz, se submodule mudar.
Regra sobre edição de arquivos

Não usar sudoedit dentro de /etc/kryonix se o diretório for gravável pelo usuário. Isso pode gerar:

sudoedit: edição de arquivos em um diretório gravável não é permitida

Preferir:

cd /etc/kryonix
nvim hosts/glacier/rve-compat.nix

Se o arquivo estiver com dono errado:

sudo chown rocha:users hosts/glacier/rve-compat.nix

Se vários arquivos do repo estiverem rootados:

sudo chown -R rocha:users /etc/kryonix

Antes de salvar/reverter:

git diff -- hosts/glacier/rve-compat.nix

Se a alteração for acidental:

git checkout -- hosts/glacier/rve-compat.nix
Arquitetura alvo
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
Inspiron
└── Cliente via Tailscale
    ├── kryonix brain health
    ├── kryonix brain stats
    ├── kryonix brain search
    └── MCP client remoto
Fase 0 — Baseline obrigatório
cd /etc/kryonix

git status --short
git diff --stat
git diff
git submodule status --recursive

Verificar especialmente:

git diff -- hosts/glacier/rve-compat.nix

Não seguir sem entender o diff.

Fase 1 — Corrigir arquivo pendente rve-compat.nix

Se o editor mostrar popup perguntando para salvar:

Se a alteração for intencional: salvar.
Se for acidental: descartar.

Validar:

cd /etc/kryonix

git diff -- hosts/glacier/rve-compat.nix
ls -l hosts/glacier/rve-compat.nix

Se não conseguir salvar:

sudo chown rocha:users hosts/glacier/rve-compat.nix
nvim hosts/glacier/rve-compat.nix
Fase 2 — Corrigir .mcp.json

Erro atual:

mcp-nixos: args must be a non-empty list
github: args must be a non-empty list

Abrir:

cat .mcp.json
cat .mcp.example.json

Corrigir entradas com args: [].

Opção preferida: usar argumento real aceito pelo servidor.

Exemplo:

{
  "command": "/home/rocha/.npm-global/bin/mcp-nixos",
  "args": ["--stdio"]
}

Se --stdio não existir:

/home/rocha/.npm-global/bin/mcp-nixos --help || true
/home/rocha/.npm-global/bin/github-mcp-server --help || true

Se o servidor usa stdio por padrão e não aceita nenhum argumento, ajustar o validador com allowlist explícita, sem enfraquecer segurança global.

Exemplo conceitual:

allow_empty_args_for = [
  "mcp-nixos",
  "github"
]

Mas só permitir se:

command for caminho absoluto.
comando estiver em path confiável.
não usar shell inline.
não conter secrets.
não usar npx/uvx lento no handshake.

Validar:

kryonix mcp check
kryonix mcp doctor
Fase 3 — Garantir MCP stdio limpo

Regra:

stdout = somente JSON-RPC
stderr = logs, banners, debug, warnings

Procurar logs perigosos:

grep -R "Persistence hardening applied" -n .
grep -R "print(" -n packages/kryonix-brain-lightrag | head -200
grep -R "console.log\|println!\|eprintln!\|FastMCP\|Starting MCP" -n . | head -300

Se houver:

print("[SYSTEM] ...")

Trocar para:

import sys
print("[SYSTEM] ...", file=sys.stderr)

Ou usar logging para stderr.

Criar/verificar script de teste:

scripts/check-mcp-stdio-clean.sh './scripts/mcp/kryonix-brain-stdio'
scripts/check-mcp-stdio-clean.sh './scripts/mcp/mcp-nixos-stdio'

Se não existir, criar.

Fase 4 — Corrigir RAG alucinando

Query crítica:

kryonix brain search "Como funciona o pipeline de RAG do Kryonix?" --explain

A resposta atual está errada quando diz:

Reasoning and Action Graph
sensores IoT
áudio
imagem
controle de dispositivos IoT
ações físicas

Neste projeto, RAG significa:

Retrieval-Augmented Generation

O pipeline real esperado é:

Vault / Markdown / Obsidian
→ ingestão
→ documentos
→ chunks
→ embeddings
→ nano-vectordb / Vector DB
→ entidades e relações
→ GraphML
→ busca hybrid/vector/graph
→ montagem de contexto
→ Ollama / LLM local
→ resposta com fontes
Arquivos prováveis
packages/kryonix-brain-lightrag/kryonix_brain_lightrag/rag.py
packages/kryonix-brain-lightrag/kryonix_brain_lightrag/cli.py
packages/kryonix-brain-lightrag/kryonix_brain_lightrag/api.py
packages/kryonix-brain-lightrag/kryonix_brain_lightrag/prompts*
Prompt obrigatório do Brain

O prompt final precisa conter regra equivalente:

Você é o Kryonix Brain.

Responda somente com base no CONTEXTO recuperado.
Não invente etapas.
Não use explicações genéricas sobre RAG.
Neste projeto, RAG significa Retrieval-Augmented Generation.
Se o contexto não comprovar uma etapa, não mencione essa etapa.
Se as fontes recuperadas forem fracas, responda que não encontrou grounding suficiente.
Sempre liste fontes com arquivo, chunk e score.
Nunca chame RAG de Reasoning and Action Graph.
Nunca mencione IoT, sensores, áudio, imagem ou execução de ações físicas a menos que isso esteja explicitamente no contexto recuperado.
Hard guard obrigatório

Se a query contém:

pipeline
RAG
Kryonix

os chunks principais precisam conter termos técnicos reais:

LightRAG
embedding
embeddings
chunk
chunks
GraphML
Ollama
Vault
vector
hybrid
nano-vectordb
entities
relations
storage

Se os top chunks não tiverem esses termos, retornar:

Não encontrei grounding suficiente no Vault/índice atual para descrever o pipeline RAG do Kryonix com segurança.
Termos proibidos para essa query

Se a resposta final contém qualquer um destes termos sem fonte explícita:

Reasoning and Action Graph
sensores IoT
Controlar dispositivos IoT
áudio
imagem
ações físicas
tomar decisões e executar ações

descartar a resposta e retornar grounding insuficiente.

Fase 5 — Corrigir saída duplicada de fontes

Hoje a CLI mostra duas seções:

Fontes usadas
Fontes Utilizadas:

Manter apenas uma.

Formato final:

Fontes usadas:
  1. vault/... | chunk: chunk-d0 | score: 0.682 | modo: hybrid
  2. repo/...  | chunk: chunk-75 | score: 0.679 | modo: hybrid

A CLI deve ser robusta contra campos ausentes:

title = (
    src.get("title")
    or src.get("arquivo")
    or src.get("file")
    or src.get("path")
    or src.get("source")
    or "fonte desconhecida"
)

score = src.get("score", "n/a")
chunk = src.get("chunk") or src.get("chunk_id") or src.get("id") or "chunk desconhecido"
mode = src.get("modo") or src.get("mode") or src.get("retrieval_mode") or "unknown"

Nunca dar KeyError por fonte incompleta.

Fase 6 — Logs para stderr

Durante search --explain, aparecem logs:

INFO:nano-vectordb...
[DEBUG] ...
[HARDEN] ...
WARNING: ...

Para CLI interativa isso pode existir, mas precisa ir para stderr.

Procurar:

grep -R "print(.*DEBUG\|print(.*HARDEN\|print(.*INFO\|print(.*WARNING" -n packages/kryonix-brain-lightrag

Trocar por:

print("...", file=sys.stderr)

ou logging.

A resposta final estruturada deve permanecer em stdout.

Fase 7 — Corrigir formatação Nix

Erro atual:

./features/openrgb.nix: not formatted
./packages/kryonix-cli.nix: not formatted
./modules/nixos/common/default.nix: not formatted

Rodar:

cd /etc/kryonix
nix fmt

Se não resolver:

nix develop -c treefmt

Ou formatar diretamente:

nixfmt features/openrgb.nix packages/kryonix-cli.nix modules/nixos/common/default.nix

Não alterar semântica. Só formatação.

Validar:

nix flake check
Fase 8 — Ollama sob demanda

Ollama deve ser fácil de ligar/desligar:

kryonix ai start
kryonix ai stop
kryonix ai restart
kryonix ai status
kryonix ai ps
kryonix ai unload
kryonix ai pull-models

Comportamento esperado:

kryonix ai start: inicia ollama.service e kryonix-brain.service.
kryonix ai stop: para Brain e Ollama.
kryonix ai unload: descarrega modelo da VRAM via keep_alive=0.
kryonix ai status: mostra systemd, GPU e modelos carregados.
Quando usuário for jogar, kryonix ai stop deve liberar GPU/VRAM.

Não preloadar modelo pesado por padrão.

Fase 9 — Modelo local recomendado

Não hardcodar em vários lugares.

Usar variáveis:

KRYONIX_LLM_MODEL
KRYONIX_EMBED_MODEL
LIGHTRAG_PROFILE_NAME
OLLAMA_CONTEXT_LENGTH

Perfis:

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
  LLM: modelo maior, somente manual
  uso: não padrão

Se alucinar, corrigir prompt/grounding antes de só trocar modelo.

Fase 10 — Testes obrigatórios

Rodar:

uv run --project packages/kryonix-brain-lightrag pytest -q

Rodar:

python -m compileall packages/kryonix-brain-lightrag

Rodar:

nix-shell packages/kryonix-brain-lightrag/shell.nix --run \
  "cargo test --manifest-path packages/kryonix-brain-lightrag/rust-core/Cargo.toml"

Rodar:

kryonix brain health
kryonix brain stats
kryonix brain vault-scan

Rodar o teste principal:

kryonix brain search "Como funciona o pipeline de RAG do Kryonix?" --explain

Esse comando precisa:

exit code 0
sem Traceback
sem KeyError
sem Reasoning and Action Graph
sem sensores IoT
sem áudio/imagem
sem controle de dispositivos
com fontes corretas OU grounding insuficiente
sem seção duplicada de fontes

Rodar:

kryonix mcp check
kryonix mcp doctor

Rodar:

nix flake check

Rodar:

nh os build
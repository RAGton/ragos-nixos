# Skill 02 — Implementação CAG

## Objetivo

Criar camada CAG para contexto canônico pequeno e rápido.

## Conceito

```txt
CAG = respostas rápidas sobre conhecimento estável e canônico.
RAG = busca dinâmica em vault/storage grande.
Hybrid = CAG primeiro + RAG se faltar grounding.
```

## Diretórios

Usar variável:

```txt
KRYONIX_CAG_DIR
```

Default:

```txt
${KRYONIX_BRAIN_HOME}/cag
```

Estrutura:

```txt
cag/
├── packs/
│   ├── kryonix-core.md
│   ├── nixos-glacier.md
│   ├── brain-api.md
│   └── commands.md
├── manifest.json
├── cache.json
└── reports/
```

## Comandos CLI

Implementar subcomando:

```bash
rag cag status
rag cag build --profile kryonix-core
rag cag refresh
rag cag ask "pergunta"
rag cag route "pergunta"
rag cag clear-cache
```

Também expor via wrapper futuro:

```bash
kryonix brain cag status
kryonix brain cag ask "pergunta"
```

## Manifest schema

```json
{
  "version": 1,
  "profile": "kryonix-core",
  "created_at": "ISO-8601",
  "sources": [],
  "hash": "sha256",
  "estimated_tokens": 0,
  "max_tokens": 12000,
  "model_hint": "llama3.1:8b",
  "status": "ok"
}
```

## Perfil `kryonix-core`

Fontes sugeridas:
- `docs/ai/BRAIN_SERVER_ARCHITECTURE.md`
- `.ai/*`
- `README.md`
- `packages/kryonix-brain-lightrag/README.md`
- arquivos Nix do Glacier/Brain
- comandos oficiais do Kryonix

## Roteamento

Criar função:

```python
def choose_context_strategy(query: str) -> Literal["cag", "rag", "hybrid"]:
    ...
```

Critérios:
- `cag`: perguntas sobre comandos canônicos, arquitetura atual, hosts, endpoints, serviços.
- `rag`: perguntas abertas, logs, histórico, documentos grandes.
- `hybrid`: pergunta crítica que precisa do contexto canônico + fontes.

## Anti-alucinação

CAG também deve ter fonte:
- nome do pack;
- hash;
- arquivos usados;
- data de build.

Se pack não existir ou estiver stale:

```txt
CAG indisponível ou desatualizado. Use `rag cag build --profile kryonix-core`.
```

## Testes

```bash
rag cag build --profile kryonix-core
rag cag status
rag cag route "como reinicio o brain?"
rag cag ask "qual é a arquitetura do glacier?"
```

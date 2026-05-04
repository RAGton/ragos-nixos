# Skill 03 — Grafo, links, cores e Obsidian

## Objetivo

Melhorar exportação do grafo para ficar navegável, categorizada e visualmente útil.

## Categorias

Mapear entidades para grupos:

```txt
CORE
NIXOS
HOST
SERVICE
SYSTEMD
AI_MODEL
OLLAMA
LIGHTRAG
CAG
RAG
MCP
API
VAULT
OBSIDIAN
DOCS
COMMAND
ERROR
SECURITY
NETWORK
STORAGE
GPU
UNKNOWN
```

## Frontmatter por nota

Cada nota exportada deve ter:

```yaml
---
entity: "Nome"
type: "SERVICE"
group: "AI"
color: "blue"
degree: 12
sources:
  - "path/origem.md"
tags:
  - kryonix/graph
  - kryonix/service
---
```

## Cores sugeridas

```txt
CORE      = purple
NIXOS     = blue
HOST      = cyan
SERVICE   = green
AI_MODEL  = orange
LIGHTRAG  = violet
CAG       = yellow
MCP       = pink
API       = teal
VAULT     = brown
ERROR     = red
SECURITY  = red
STORAGE   = gray
GPU       = lime
UNKNOWN   = gray
```

Não dependa de plugin específico do Obsidian para funcionar. Use frontmatter + tags.

## Links

Melhorar links:

```md
Relaciona com:
- [[Ollama]]
- [[LightRAG]]
- [[Kryonix Brain API]]
```

Regras:
- Normalizar slug.
- Preservar alias.
- Criar MOCs automáticos por grupo:
  - `01-MOCs/Core.md`
  - `01-MOCs/NixOS.md`
  - `01-MOCs/AI.md`
  - `01-MOCs/Services.md`
  - `01-MOCs/Errors.md`

## Arquivos de saída

```txt
exports/graph/
├── entities/
├── mocs/
├── graph.json
├── graph-cytoscape.json
└── graph-report.md
```

## Validação

```bash
rag graph export-obsidian --limit 1000
rag graph generate-mocs
rag graph validate
```

Critérios:
- Sem links quebrados principais.
- MOCs gerados.
- Entidades com tipo/grupo/cor.
- Fontes preservadas.

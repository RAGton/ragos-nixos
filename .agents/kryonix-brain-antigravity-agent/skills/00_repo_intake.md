# Skill 00 — Intake do repositório

## Objetivo

Entender o estado real antes de editar.

## Comandos

```bash
cd /etc/kryonix

git status --short
git diff --stat
git submodule status --recursive

rg -n "LightRAG|QueryParam|no_cache|cache|rerank|reranker|mix|MCP|TextContent|FastAPI|KRYONIX_BRAIN_KEY|OLLAMA_KEEP_ALIVE" \
  packages/kryonix-brain-lightrag modules profiles docs .ai || true
```

## Saída esperada

- Lista de bugs confirmados.
- Lista de arquivos a alterar.
- Plano de commits.
- Riscos.

## Não fazer

- Não editar antes de baseline.
- Não rodar index full antes de backup.

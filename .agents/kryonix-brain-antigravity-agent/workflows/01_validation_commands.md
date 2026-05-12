# Workflow 01 — Validation Commands

## Python/package

```bash
cd /etc/kryonix

uv run --project packages/kryonix-brain-lightrag pytest -q
uv run --project packages/kryonix-brain-lightrag rag mcp-check
uv run --project packages/kryonix-brain-lightrag rag stats --json
uv run --project packages/kryonix-brain-lightrag rag diagnostics
```

## RAG

```bash
uv run --project packages/kryonix-brain-lightrag rag search \
  "Como funciona o pipeline RAG do Kryonix?" \
  --explain --no-cache
```

## CAG

```bash
uv run --project packages/kryonix-brain-lightrag rag cag build --profile kryonix-core
uv run --project packages/kryonix-brain-lightrag rag cag status
uv run --project packages/kryonix-brain-lightrag rag cag ask "qual é a arquitetura do Glacier?"
uv run --project packages/kryonix-brain-lightrag rag cag route "como faço rebuild seguro?"
```

## Eval

```bash
uv run --project packages/kryonix-brain-lightrag rag eval run
uv run --project packages/kryonix-brain-lightrag rag eval report
```

## API

```bash
curl -s http://127.0.0.1:8000/health | jq

curl -s \
  -H "X-API-Key: $KRYONIX_BRAIN_KEY" \
  http://127.0.0.1:8000/stats | jq

curl -s \
  -H "X-API-Key: $KRYONIX_BRAIN_KEY" \
  -H "Content-Type: application/json" \
  -X POST http://127.0.0.1:8000/search \
  -d '{"query":"Como funciona o pipeline RAG do Kryonix?","mode":"hybrid","lang":"pt-BR","explain":true}' | jq
```

## NixOS

```bash
nix flake check -L --show-trace
nh os build .#glacier -L --show-trace
```

Não rodar `switch` sem aprovação.

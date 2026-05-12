# Skill 01 — Estabilização LightRAG/Kryonix Brain

## Objetivo

Corrigir defeitos práticos antes de adicionar features.

## Correções obrigatórias

### 1. MCP `rag_search`

Se `rag_mod.query()` retornar dict, `TextContent.text` precisa ser string.

Implementar:

```python
result = await rag_mod.query(query, mode=mode, lang=lang)
text = json.dumps(result, ensure_ascii=False, indent=2)
return [TextContent(type="text", text=text)]
```

### 2. `httpx`

Se `server.py` usa `httpx`, adicionar no `pyproject.toml`:

```toml
"httpx>=0.27.0",
```

### 3. API auth fail-closed

Em `api.py`:

```python
expected_key = os.getenv("KRYONIX_BRAIN_KEY")
allow_no_auth = os.getenv("KRYONIX_BRAIN_ALLOW_NO_AUTH", "false").lower() == "true"

if not expected_key and not allow_no_auth:
    raise HTTPException(status_code=500, detail="KRYONIX_BRAIN_KEY não configurado")

if expected_key and api_key != expected_key:
    raise HTTPException(status_code=403, detail="API Key inválida")
```

### 4. Host seguro

Default:

```python
host = os.getenv("KRYONIX_BRAIN_HOST", "127.0.0.1")
```

### 5. `--no-cache`

Adicionar ao parser de `rag search` e `rag ask`.

Comportamento:
- aceitar flag;
- ignorar cache de resposta;
- não apagar embeddings;
- se limpar arquivo de cache, fazer backup antes;
- exibir no `--explain`.

### 6. `subprocess.run(check=True)`

Delegações internas devem propagar erro.

### 7. Logger

Se `rag.py` usar `logger.error`, garantir:

```python
import logging
logger = logging.getLogger("kryonix-brain-rag")
```

### 8. Pin de versão

Trocar dependência solta:

```toml
"lightrag-hku>=1.4.0"
```

por faixa validada:

```toml
"lightrag-hku>=1.4.9,<1.5.0"
```

ou pin exato depois de testar.

## Validação

```bash
uv run --project packages/kryonix-brain-lightrag pytest -q
uv run --project packages/kryonix-brain-lightrag rag mcp-check
uv run --project packages/kryonix-brain-lightrag rag stats --json
uv run --project packages/kryonix-brain-lightrag rag search "Como funciona o pipeline RAG do Kryonix?" --explain --no-cache
```

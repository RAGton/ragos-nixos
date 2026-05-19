# Análise de Qualidade — Kora

**Data:** 2026-05-19  
**Escopo:** 74 arquivos Python, 8.731 LOC  
**Nota global: 6.5/10**

---

## Top 10 Problemas Críticos

### P0 — Segurança e Silent Failures

**1. Shell Injection** — `kora/core/orchestrator.py:578`

```python
# ATUAL (perigoso)
process = subprocess.run(command, shell=True, ...)
```

Lê `command` de `pending_action.json` sem validação. Qualquer escrita maliciosa nesse arquivo = RCE local.

**Fix:**
```python
import shlex
cmd_list = shlex.split(command)
if not _is_authorized_command(cmd_list):
    raise PermissionError(f"Comando não autorizado: {cmd_list[0]}")
process = subprocess.run(cmd_list, timeout=60, capture_output=True, text=True)
```

---

**2. Bare `except:` duplo** — `kora/voice/wakeword.py:85,90`

```python
try:
    temp_model = Model(wakeword_models=["kora"])
except:          # ← engole KeyboardInterrupt, SystemExit, tudo
    try:
        temp_model = Model(wakeword_models=["hey_mycroft"])
    except:      # ← idem
        custom_model_present = False
```

**Fix:**
```python
except Exception as e:
    logger.error("Falha ao carregar modelo kora: %s", e)
    ...
```

---

**3. Bare `except:` mascarando I/O** — `kora/memory/obsidian.py:34` e `kora/memory/search.py:61`

`pass` em erros de filesystem/parsing. Notas corrompidas nunca aparecem nos logs.

**Fix:** `except Exception as e: logger.error("...: %s", e)`

---

### P1 — Estabilidade e Concorrência

**4. Globals não thread-safe** — `kora/core/orchestrator.py:72-73`

`_CAG_CACHE` e `_LAST_GRAPH_MTIME` são globais sem `threading.Lock`. Em FastAPI com múltiplos workers = race condition no cache CAG.

**Fix:**
```python
class SimpleLRUCache:
    def __init__(self, capacity: int = 256):
        self._cache = collections.OrderedDict()
        self._lock = threading.Lock()

    def get(self, key: str):
        with self._lock:
            ...
```

---

**5. Singleton Whisper sem lock** — `kora/voice/stt.py:13,21`

Múltiplas coroutines podem carregar o modelo simultaneamente (3–5 GB cada).

**Fix:**
```python
from functools import lru_cache

@lru_cache(maxsize=1)
def get_whisper_model():
    ...
```

---

**6. Subprocess sem timeout** — `kora/voice/tts.py:82`

`subprocess.Popen` sem `communicate(timeout=...)`. Piper travado = daemon travado indefinidamente.

**Fix:**
```python
try:
    stdout, _ = piper_proc.communicate(input=text.encode(), timeout=30)
except subprocess.TimeoutExpired:
    piper_proc.kill()
    logger.error("TTS synthesis timed out")
    raise
```

---

**7. VoiceDaemon sem resiliência** — `kora/voice/daemon.py`

- `kora/voice/exceptions.py` **não existe** (necessário para distinguir `ServiceUnreachable` de `HardwareAccessError`)
- `kora/voice/monitor.py` **não existe** (sem `tenacity`, sem backoff exponencial)
- `handle_trigger` (linha 89): `except Exception` genérico, sem distinção de erro
- Sem heartbeat — se o orchestrator cair, o daemon continua processando áudio em vão
- State file em `/run/user/{uid}` escrito sem `fcntl.flock` (race em escritas concorrentes)
- `tenacity` ausente do `pyproject.toml`

---

**8. CLI monolítico** — `kora/cli/main.py` (966 linhas, 40 funções `handle_*`)

Viola responsabilidade única. Deveria ser dividido em:
- `kora/cli/health.py`
- `kora/cli/voice.py`
- `kora/cli/memory.py`
- `kora/cli/admin.py`

---

**9. ~180 `print()` em produção**

Espalhados em `voice/models.py`, `cli/main.py`, `benchmark.py`, `eval/`. Não chegam ao journald sob systemd.

**Fix global:** `grep -rn "^\s*print(" kora/ | grep -v test` → converter para `logger.info()`.

---

**10. TODO Phase 3 não implementado** — `kora/api/routes_stream.py:45`

Streaming SSE incompleto. Usuários que dependem de streaming recebem resposta parcial silenciosamente.

---

## Por Subsistema

| Subsistema | Nota | Problemas Principais |
|---|:---:|---|
| `core/` | 6.0 | shell=True; globals sem lock; orchestrator 588 LOC com 5 responsabilidades |
| `voice/` | 5.5 | Daemon sem reconnect/heartbeat; 2 bare excepts; TTS sem timeout |
| `memory/` | 6.5 | Bare excepts x2; `worker.py` com `print()` no path crítico |
| `cli/` | 5.0 | 966 LOC num único arquivo |
| `api/` | 7.0 | Bem estruturado; validações Pydantic incompletas; TODO streaming |
| `integrations/` | 7.5 | `n8n.py` e `brain.py` com timeouts OK; `ha.py` ainda é stub |
| `llm/` | 8.0 | `ollama.py` limpo, adapter pattern correto |
| `learning/` | 7.0 | Sem logger em 4/6 módulos; `privacy.py` sem sincronização |
| `mind/` | 6.0 | Sem cobertura de testes; sem logger; `persona.py` opaco |
| `training/` | 8.0 | Estrutura simples e funcional |
| `tests/` | 5.0 | Cobertura ~36%; `voice/daemon.py`, `wakeword.py`, `mind/*` sem teste |

---

## Riscos Imediatos para Produção

1. **RCE local** via `pending_action.json` → `orchestrator.py:578`
2. **Travamento do daemon de voz** → TTS sem timeout em `tts.py:82`
3. **Race condition no state file** → corrupção de `voice_state.json`
4. **Memory leak** → Whisper carregado em duplicidade sob carga concorrente
5. **Silent failures em memory** → notas corrompidas nunca reportadas

---

## Estado do VoiceDaemon (refactor pendente)

| Item | Status |
|---|---|
| `kora/voice/exceptions.py` | ❌ não existe |
| `kora/voice/monitor.py` | ❌ não existe |
| Signal handlers (`SIGTERM`/`SIGINT`) | ✅ existem em `daemon.py:165-170` |
| Fechamento limpo do stream PyAudio no stop | ⚠️ parcial (apenas no `finally` do loop) |
| Cancelamento de tasks assíncronas pendentes | ❌ ausente |
| `tenacity` no `pyproject.toml` | ❌ ausente |
| Heartbeat / status `RECONNECTING` | ❌ ausente |
| `Restart=always` na systemd unit | ⚠️ não verificado |

---

## Sugestões Priorizadas

### P0 — Imediato (segurança/estabilidade crítica)
- [ ] `orchestrator.py:578` → remover `shell=True`, usar `shlex.split()` + whitelist
- [ ] `wakeword.py:85,90` → converter bare except para `except Exception as e` com logger
- [ ] `obsidian.py:34`, `search.py:61` → idem

### P1 — Urgente (concorrência/timeouts)
- [ ] `orchestrator.py:72-73` → thread-safe LRU cache com `threading.Lock`
- [ ] `stt.py:13,21` → `@lru_cache(maxsize=1)` ou `asyncio.Lock`
- [ ] `tts.py:82` → `communicate(timeout=30)` com `piper_proc.kill()` no except
- [ ] `daemon.py:74` → `fcntl.flock` no state file
- [ ] Criar `voice/exceptions.py` com `VoiceDaemonError`, `ServiceUnreachable`, `HardwareAccessError`
- [ ] Criar `voice/monitor.py` com `retry_connection` via `tenacity` (backoff 1s→60s)
- [ ] Adicionar `tenacity` ao `pyproject.toml`

### P2 — Importante (higiene)
- [ ] `cli/main.py` → dividir em `cli/{health,voice,memory,admin}.py`
- [ ] Converter `print()` para `logger.info()` em `voice/models.py`, `benchmark.py`, `eval/`
- [ ] Adicionar `logger = logging.getLogger(__name__)` nos 34 módulos sem logger
- [ ] Aumentar cobertura: `voice/daemon.py`, `voice/wakeword.py`, `mind/*`
- [ ] Resolver TODO Phase 3 em `api/routes_stream.py:45`

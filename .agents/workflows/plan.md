---
description: 
---

# Glacier: Servidor NixOS 100% Declarativo de IA

## Estado real (diagnóstico completo — 2026-05-01)

### ✅ Já existe e está correto

| Componente | Estado |
|---|---|
| `nix flake check` | ✅ Passou limpo (todos os 4 hosts avaliam sem erro) |
| `nix flake show` | ✅ glacier, inspiron, inspiron-nina, iso, glacier-live |
| Glacier networking | ✅ IP fixo `10.0.0.2` em `rve-compat.nix` |
| Glacier SSH porta 2224 | ✅ `rve-compat.nix` |
| Tailscale declarado | ✅ `default.nix` + `services.kryonix.tailscale` |
| Firewall base | ✅ trustedInterfaces tailscale0 |
| NVIDIA/CUDA | ✅ `hardware.nvidia` + nixos-hardware modules |
| Módulo `brain.nix` | ✅ Opções `role`, `ollama`, `storagePath`, `vaultPath` |
| Brain Python (`rag.py`, `api.py`, `server.py`) | ✅ RAG com grounding real, multi-hop, ranking |
| Anti-alucinação | ✅ `rag.py` aborta se grounding vazio |
| Atomic writes LightRAG | ✅ monkey-patch em `rag.py` |
| MCP server | ✅ `server.py` com stdout→stderr redirect e 20+ tools |
| `features/gaming.nix` separado | ✅ Opt-in, sem conflito com IA |
| `profiles/server-ai.nix` | ✅ Existe, ativa `kryonix.services.brain` |
| `kryonix-brain-api.wantedBy = mkForce []` | ✅ Já no `default.nix` do Glacier |

### ❌ Ausente ou incorreto

| Problema | Impacto |
|---|---|
| **Ollama sobe no boot** | `brain.nix` não tem `wantedBy = mkForce []` para `ollama.service` |
| **`keep_alive` não configurado** | Modelo ocupa VRAM indefinidamente após query |
| **Sem `ollama-vram-check`** | RTX 4060 (8 GB) pode ter OOM com modelos 7b |
| **`config.py` defaults Windows** | `WORKING_DIR = C:\Users\aguia\...` — quebra em NixOS sem EnvironmentFile |
| **Sem `kryonix-lightrag.service`** | Solicitado; hoje LightRAG roda embutida na API |
| **`brain.nix` ExecStart errado** | Usa `python -m kryonix_brain_lightrag.api` mas `api.py` requer `uvicorn` como runner |
| **Sem controle de ingestion** | `rag.py` tem `insert_single()` mas não há endpoint `/ingest/propose` nem pipeline de aprovação |
| **Firewall abre 11434/8000 para todos** | `brain.nix` usa `allowedTCPPorts` sem restricão de source |
| **Sem subcomando `kryonix ollama`** | Operador não tem start/stop/status/vram na CLI |
| **Perfis base/ai/gamer sem toggle** | Apenas `server-ai` e `workstation-gamer`; sem switch simples entre AI ativa/inativa |
| **`kryonix-brain-api` sem Restart** | `brain.nix` não tem `Restart = "on-failure"` |

---

## Arquitetura alvo

```
Glacier (NixOS declarativo)
├── systemd
│   ├── ollama.service         (manual start; CUDA; keep_alive=0)
│   ├── kryonix-brain.service  (FastAPI HTTP; depende de ollama)
│   └── kryonix-lightrag.service  (pré-aquece index; depende de brain)
├── Firewall
│   ├── LAN 10.0.0.0/24 → portas 11434, 8000
│   └── Tailscale 100.64.0.0/10 → portas 11434, 8000
├── Storage
│   └── /var/lib/kryonix/brain/{storage,vault}
└── Profiles
    ├── profile.base   (networking, SSH, Tailscale, NVIDIA driver)
    ├── profile.ai     (ollama + brain serviços — desligados por default)
    └── profile.gamer  (Steam, GameMode, GPU livre)

Inspiron → Tailscale → Glacier:8000 (Brain HTTP API)
Inspiron → SSH+stdio → Glacier (MCP server)
```

---

## Proposed Changes — por fase

> [!IMPORTANT]
> **Nenhuma fase inclui `nixos-rebuild switch` ou `kryonix switch`.**
> Toda mudança é validada com `nix flake check` + `nix build ... --no-link`.
> O apply final é responsabilidade do operador.

---

### Fase 1 — Ollama declarativo sem autostart

#### [MODIFY] `modules/nixos/services/brain.nix`

Adicionar opções:
```nix
ollama.autoStart = mkOption { type = types.bool; default = false; };
ollama.model     = mkOption { type = types.str; default = "qwen2.5-coder:7b"; };
ollama.keepAlive = mkOption { type = types.str; default = "0"; };
ollama.vramMinGiB = mkOption { type = types.ints.positive; default = 6; };
```

Comportamento quando `autoStart = false`:
```nix
systemd.services.ollama.wantedBy = lib.mkForce [];
```

Adicionar env no serviço ollama:
```nix
systemd.services.ollama.environment.OLLAMA_KEEP_ALIVE = cfg.ollama.keepAlive;
```

Adicionar `systemd.services.ollama-vram-check` (oneshot, `requiredBy = ["ollama.service"]`, `before = ["ollama.service"]`):
- Usa `nvidia-smi` para checar VRAM livre
- Aborta se VRAM < `cfg.ollama.vramMinGiB * 1024` MiB
- Roda apenas quando `ollama.service` é iniciado manualmente

Adicionar `Restart = "on-failure"` e `RestartSec = "10"` ao `kryonix-brain-api`.

Corrigir `ExecStart` da `kryonix-brain-api`:
```nix
ExecStart = "${pkgs.python3}/bin/python -m uvicorn kryonix_brain_lightrag.api:app --host 0.0.0.0 --port ${toString cfg.port}";
```
→ Mas isso requer uvicorn no PATH. A solução correta é usar o entrypoint `main()` do `api.py`:
```nix
ExecStart = "${pkgs.python3}/bin/python -c 'from kryonix_brain_lightrag.api import main; main()'";
```

Adicionar `nvidia-smi` e `ollama-cuda` a `environment.systemPackages` quando server-side.

#### [MODIFY] `hosts/glacier/default.nix`

Dentro do bloco implícito via `kryonix.profiles.server-ai.enable = true` → `kryonix.services.brain`:
```nix
kryonix.services.brain.ollama.autoStart = false;
kryonix.services.brain.ollama.model = "qwen2.5-coder:7b";
kryonix.services.brain.ollama.keepAlive = "0";
kryonix.services.brain.ollama.vramMinGiB = 6;
```

Adicionar `pkgs.ollama-cuda` e `pkgs.nvtopPackages.nvidia` a `environment.systemPackages`.

---

### Fase 2 — `kryonix-lightrag.service` + dependências corretas

#### [MODIFY] `modules/nixos/services/brain.nix`

Adicionar `systemd.services.kryonix-lightrag`:
- **Papel**: pré-inicializar o índice LightRAG (verifica storage, valida GraphML, warmup do VDB)
- **`Type = "oneshot"` com `RemainAfterExit = true`** — considera-se "up" após warmup
- **Depende de**: `ollama.service` (precisa do LLM para validação)
- **É dependência de**: `kryonix-brain-api.service`
- **ExecStart**: script Python que importa `rag.get_rag_async()` e chama `stats()`
- **EnvironmentFile**: mesmo `/etc/kryonix/brain.env` do brain-api

Cadeia de dependências resultante:
```
ollama-vram-check → ollama → kryonix-lightrag → kryonix-brain-api
```

Quando Ollama está desligado:
- `kryonix-lightrag` e `kryonix-brain-api` também ficam parados (dependência implícita)
- Iniciar `kryonix ollama start` ativa toda a cadeia em ordem

---

### Fase 3 — `config.py` defaults Linux + ingestion controlada

#### [MODIFY] `packages/kryonix-brain-lightrag/kryonix_brain_lightrag/config.py`

**Detectar OS e usar defaults corretos:**
```python
import sys, platform

_is_windows = sys.platform == "win32"
_default_base = r"C:\Users\aguia\Documents\kryonix" if _is_windows else "/var/lib/kryonix/brain"
_default_vault = r"C:\Users\aguia\Documents\kryonix-vault" if _is_windows else "/var/lib/kryonix/vault"

WORKSPACE_ROOT = Path(os.getenv("LIGHTRAG_WORKSPACE_ROOT", _default_base))
VAULT_DIR      = Path(os.getenv("LIGHTRAG_VAULT_DIR", _default_vault))
WORKING_DIR    = Path(os.getenv("LIGHTRAG_WORKING_DIR", str(VAULT_DIR / "storage")))
```

Adicionar:
```python
OLLAMA_KEEP_ALIVE = os.getenv("OLLAMA_KEEP_ALIVE", "0")
INGEST_PROPOSE_DIR = Path(os.getenv("LIGHTRAG_INGEST_PROPOSE_DIR",
    str(WORKING_DIR.parent / "ingest_queue")))
INGEST_APPROVE_FILE = Path(os.getenv("LIGHTRAG_INGEST_APPROVE_FILE",
    str(INGEST_PROPOSE_DIR / "approved.json")))
```

#### [MODIFY] `packages/kryonix-brain-lightrag/kryonix_brain_lightrag/api.py`

Adicionar endpoints de ingestion controlada:

```python
@app.post("/ingest/propose")   # Propõe conteúdo para ingestão (não indexa)
@app.get("/ingest/queue")      # Lista itens na fila aguardando aprovação
@app.post("/ingest/approve")   # Aprova e indexa item(s) da fila
@app.delete("/ingest/reject")  # Rejeita item da fila
```

**Pipeline**:
1. `POST /ingest/propose` → salva em `INGEST_PROPOSE_DIR/{id}.json` (source, content, metadata)
2. `GET /ingest/queue` → lista arquivos em `INGEST_PROPOSE_DIR` não aprovados
3. `POST /ingest/approve` → lê arquivo, chama `rag.insert_single()`, move para `approved/`
4. `DELETE /ingest/reject` → remove arquivo da fila

Todos os endpoints exigem `X-API-Key`. Nenhum escreve no storage sem passar por `approve`.

---

### Fase 4 — MCP firewall + validação remota

#### [MODIFY] `modules/nixos/services/brain.nix`

Substituir `allowedTCPPorts` por regras com restrição de source:
```nix
networking.firewall.extraCommands = lib.mkIf (cfg.role == "server") ''
  # Brain API e Ollama: apenas LAN e Tailscale
  iptables -A INPUT -s 10.0.0.0/24  -p tcp --dport ${toString cfg.port} -j ACCEPT
  iptables -A INPUT -s 100.64.0.0/10 -p tcp --dport ${toString cfg.port} -j ACCEPT
  iptables -A INPUT -p tcp --dport ${toString cfg.port} -j DROP

  iptables -A INPUT -s 10.0.0.0/24  -p tcp --dport 11434 -j ACCEPT
  iptables -A INPUT -s 100.64.0.0/10 -p tcp --dport 11434 -j ACCEPT
  iptables -A INPUT -p tcp --dport 11434 -j DROP
'';
networking.firewall.extraStopCommands = lib.mkIf (cfg.role == "server") ''
  iptables -D INPUT -s 10.0.0.0/24  -p tcp --dport ${toString cfg.port} -j ACCEPT || true
  iptables -D INPUT -s 100.64.0.0/10 -p tcp --dport ${toString cfg.port} -j ACCEPT || true
  iptables -D INPUT -p tcp --dport ${toString cfg.port} -j DROP || true
  iptables -D INPUT -s 10.0.0.0/24  -p tcp --dport 11434 -j ACCEPT || true
  iptables -D INPUT -s 100.64.0.0/10 -p tcp --dport 11434 -j ACCEPT || true
  iptables -D INPUT -p tcp --dport 11434 -j DROP || true
'';
```

Remover `allowedTCPPorts` genérico do `brain.nix` (mantém o do `rve-compat.nix` que já cuida do SSH).

**Nota**: `server.py` (MCP) roda via stdio — não abre porta TCP, logo não precisa de regra de firewall. A comunicação MCP Inspiron→Glacier ocorre via `ssh -p 2224 rocha@glacier "uv run ... python -m kryonix_brain_lightrag.server"`.

#### [MODIFY] `.mcp.example.json`

Verificar se o comando SSH está correto para o Glacier NixOS e atualizar conforme necessário.

---

### Fase 5 — Perfis base/ai/gamer no Glacier

#### [NEW] `profiles/glacier-base.nix`

Profile base do Glacier (sem IA, sem gaming):
```nix
options.kryonix.profiles.glacier-base.enable = mkEnableOption "Perfil base do Glacier (rede, SSH, Tailscale, NVIDIA driver)";
config = mkIf cfg.enable {
  # Apenas: networking declarativo, SSH, Tailscale, NVIDIA (driver sem CUDA compute)
  # NÃO inclui: Ollama, Brain, Steam, GameMode
};
```

#### [NEW] `profiles/glacier-ai.nix`

Profile IA (estende base):
```nix
options.kryonix.profiles.glacier-ai.enable = mkEnableOption "Perfil IA do Glacier (Ollama + Brain, sem autostart)";
config = mkIf cfg.enable {
  kryonix.services.brain = {
    enable = true; role = "server";
    ollama.enable = true; ollama.autoStart = false;
    ollama.acceleration = "cuda";
    ollama.keepAlive = "0"; ollama.model = "qwen2.5-coder:7b";
    ollama.vramMinGiB = 6;
  };
};
```

#### [NEW] `profiles/glacier-gamer.nix`

Profile gamer (estende base, NÃO estende ai):
```nix
options.kryonix.profiles.glacier-gamer.enable = mkEnableOption "Perfil gamer do Glacier (Steam, GameMode, GPU livre)";
config = mkIf cfg.enable {
  kryonix.features.gaming = {
    enable = true; steam.enable = true;
    gamemode.enable = true; mangohud.enable = true;
  };
  # Garante que Ollama NÃO esteja no wantedBy:
  systemd.services.ollama.wantedBy = mkForce [];
};
```

#### [MODIFY] `profiles/default.nix`

Adicionar imports dos três novos perfis.

#### [MODIFY] `hosts/glacier/default.nix`

Substituir `kryonix.profiles.server-ai.enable = true` pelos novos perfis:
```nix
kryonix.profiles.glacier-base.enable = true;
kryonix.profiles.glacier-ai.enable = true;   # inclui brain sem autostart
kryonix.profiles.glacier-gamer.enable = true; # inclui gaming sem afetar VRAM do AI
```

> [!NOTE]
> Os perfis antigos (`server-ai`, `workstation-gamer`) ficam intactos para não quebrar outros hosts que possam usá-los.



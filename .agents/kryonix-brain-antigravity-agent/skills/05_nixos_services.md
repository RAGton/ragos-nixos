# Skill 05 — NixOS/Glacier Services

## Objetivo

Brain declarativo no NixOS sem quebrar gamer mode.

## Opções esperadas

Em `modules/nixos/services/brain.nix`:

```nix
options.kryonix.brain = {
  enable = lib.mkEnableOption "Kryonix Brain";
  repoPath = lib.mkOption { type = lib.types.str; default = "/etc/kryonix"; };
  brainHome = lib.mkOption { type = lib.types.str; default = "/var/lib/kryonix"; };
  vaultPath = lib.mkOption { type = lib.types.str; default = "${cfg.brainHome}/vault"; };
  storagePath = lib.mkOption { type = lib.types.str; default = "${cfg.brainHome}/storage"; };
  apiHost = lib.mkOption { type = lib.types.str; default = "127.0.0.1"; };
  apiPort = lib.mkOption { type = lib.types.port; default = 8000; };
  ollamaAutoStart = lib.mkOption { type = lib.types.bool; default = true; };
  modelWarmupOnBoot = lib.mkOption { type = lib.types.bool; default = false; };
  keepAlive = lib.mkOption { type = lib.types.str; default = "0"; };
};
```

## Serviços

- `ollama.service`: daemon.
- `kryonix-brain-api.service`: API.
- `kryonix-lightrag.service`: opcional/warmup/index worker, sem carregar modelo no boot se `modelWarmupOnBoot=false`.
- `kryonix-brain-doctor.timer`: health periódico.
- `kryonix-brain-backup.timer`: backup leve.

## Environment

```nix
environment = {
  KRYONIX_REPO_ROOT = cfg.repoPath;
  KRYONIX_BRAIN_HOME = cfg.brainHome;
  LIGHTRAG_WORKING_DIR = cfg.storagePath;
  LIGHTRAG_VAULT_DIR = cfg.vaultPath;
  LIGHTRAG_OBSIDIAN_EXPORT_DIR = "${cfg.brainHome}/exports";
  OLLAMA_BASE_URL = "http://127.0.0.1:11434";
  OLLAMA_KEEP_ALIVE = cfg.keepAlive;
  KRYONIX_BRAIN_HOST = cfg.apiHost;
  KRYONIX_BRAIN_PORT = toString cfg.apiPort;
};
```

## Validação

Antes de switch:

```bash
nix flake check -L --show-trace
nh os build .#glacier -L --show-trace
```

Depois de `test` ou `switch` aprovado:

```bash
systemctl is-enabled ollama || true
systemctl is-enabled kryonix-brain-api || true
systemctl status ollama --no-pager
systemctl status kryonix-brain-api --no-pager
curl -s http://127.0.0.1:8000/health | jq
```

Com chave:

```bash
curl -s -H "X-API-Key: $KRYONIX_BRAIN_KEY" http://127.0.0.1:8000/stats | jq
```

Fase 6 (kryonix ollama CLI)                # independente de Nix
    ↓
Fase 7 (docs + context)                   # pode ser feito a qualquer momento
```

Fases 3 e 6 são independentes e podem ser feitas em paralelo com outras.

---

## Open Questions

> [!IMPORTANT]
> **kryonix-lightrag como `oneshot` ou `simple`?** O pedido é ter um serviço separado. `oneshot` com `RemainAfterExit = true` trata como "up" após warmup, o que é correto para dependência de serviço. Se o user quiser um processo persistente (ex.: índice em RAM), a implementação muda. **Assumindo `oneshot`.**

> [!IMPORTANT]
> **`ExecStart` do `kryonix-brain-api`**: O `api.py` usa `uvicorn.run(app, ...)` na função `main()`. Para que o serviço funcione sem instalar o pacote, precisa de `uv run` ou ter `uvicorn` disponível. Atualmente `brain.nix` usa `${pkgs.python3}/bin/python` mas a dependência `uvicorn` não está no nixpkgs Python padrão — precisa de um `python3.withPackages`. **Pendência de implementação: definir env Python correto.**

> [!WARNING]
> **Fase 5 perfis**: Criar `glacier-base`, `glacier-ai`, `glacier-gamer` e usar no `default.nix` substitui `server-ai` e `workstation-gamer` no Glacier. Os perfis antigos ficam disponíveis para outros hosts. Confirmar se isso é desejado antes de executar.

> [!CAUTION]
> **`extraCommands` firewall vs `allowedTCPPorts`**: Misturar `extraCommands` (iptables direto) com `allowedTCPPorts` pode criar conflito de regras. A abordagem mais segura no NixOS é usar `networking.firewall.allowedTCPPorts` com interfaces específicas via `interfaces.<iface>.allowedTCPPorts`. Vou verificar qual abordagem é mais limpa no NixOS unstable antes de implementar.

---

## Verification Plan

### Por fase (cada uma antes de prosseguir)

```bash
# Após cada modificação Nix:
nix flake check --keep-going
nix build .#nixosConfigurations.glacier.config.system.build.toplevel --no-link -L --show-trace
```

### Pós-switch (requer aprovação humana — não executar automaticamente)

```bash
# Fase 1 — Ollama
systemctl status ollama --no-pager          # DEVE estar inativo
kryonix ollama vram                         # ~8000 MiB livres
kryonix ollama start                        # inicia
systemctl status ollama --no-pager          # ativo
nvidia-smi                                  # VRAM parcialmente usada
kryonix ollama stop                         # para
nvidia-smi                                  # VRAM livre (keep_alive=0)

# Fase 2 — Serviços
systemctl status kryonix-brain.service --no-pager
systemctl status kryonix-lightrag.service --no-pager

# Fase 3 — Brain API + Ingestion
curl localhost:8000/health
kryonix brain health
kryonix brain stats
kryonix brain search "pipeline RAG Kryonix"

# Fase 4 — MCP (no Inspiron)
# (requer Glacier online com switch feito)
cat .mcp.json  # verificar comando SSH correto

# Fase 5 — Perfis (nvidia-smi com AI ligada e desligada)
kryonix ollama stop && nvidia-smi           # 0 MiB em uso por ollama
kryonix ollama start && nvidia-smi          # VRAM parcialmente usada
```

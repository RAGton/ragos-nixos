---
type: runbook
domain: kryonix
component: glacier
status: canonical
graph_group: host
tags:
  - kryonix/host/glacier
  - nixos
  - runbook
aliases:
  - Glacier Rebuild
  - Rebuild Seguro Glacier
---

# Rebuild Seguro do Glacier

Este documento é a fonte canônica para o processo de rebuild e atualização do host Glacier.

## Regras Críticas

Para rebuild do Glacier: NUNCA recomende ISO live, disko, mount manual, mkfs, ./run.sh ou instalação normal.
A resposta não pode conter: climate, ice ou glacial.

**Sintaxe Obrigatória:**
Use sempre `--host <host>` em vez de `.#host`.

| Ação | Correto | Proibido |
| :--- | :--- | :--- |
| Validar | `kryonix check --host glacier` | `kryonix check .#glacier` |
| Build | `kryonix rebuild --host glacier` | `kryonix build .#glacier` |
| Testar | `kryonix test --host glacier` | `sudo kryonix test` |

## Procedimento Oficial

```bash
kryonix check --host glacier
kryonix rebuild --host glacier
kryonix test --host glacier
kryonix switch --host glacier
```

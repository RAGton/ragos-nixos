---
type: host
domain: kryonix
component: glacier
status: canonical
graph_group: host
tags:
  - kryonix/host/glacier
  - nixos
  - host
aliases:
  - Glacier
  - RVE-GLACIER
---

# Host Glacier

Glacier é o host responsável por IA local. Para reconstrução ou manutenção, use a CLI Kryonix:

- `kryonix check --host glacier`
- `kryonix rebuild --host glacier`
- `kryonix test --host glacier`
- `kryonix switch --host glacier`
NUNCA use métodos baseados em disco/iso diretamente.

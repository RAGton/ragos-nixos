# Workflow 00 — Full Stabilization

## 1. Baseline

```bash
cd /etc/kryonix
git status --short
git diff --stat
uv run --project packages/kryonix-brain-lightrag rag diagnostics || true
```

## 2. Corrigir bugfixes

Aplicar `skills/01_lightrag_stabilization.md`.

Commit:

```bash
git add packages/kryonix-brain-lightrag
git commit -m "fix(brain): stabilize api mcp cache and dependencies"
```

## 3. Implementar CAG

Aplicar `skills/02_cag_implementation.md`.

Commit:

```bash
git add packages/kryonix-brain-lightrag
git commit -m "feat(brain): add cag context packs"
```

## 4. Melhorar grafo/Obsidian

Aplicar `skills/03_graph_obsidian_visual.md`.

Commit:

```bash
git add packages/kryonix-brain-lightrag docs
git commit -m "feat(graph): categorize obsidian exports"
```

## 5. NixOS

Aplicar `skills/05_nixos_services.md`.

Commit:

```bash
git add modules profiles docs
git commit -m "feat(nixos): declare kryonix brain services"
```

## 6. Validação final

Rodar `workflows/01_validation_commands.md`.

## 7. Relatório

Usar `checklists/definition_of_done.md`.

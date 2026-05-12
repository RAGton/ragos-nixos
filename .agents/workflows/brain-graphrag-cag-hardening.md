# Workflow — Kryonix Brain GraphRAG/CAG Hardening

## Objetivo

Aplicar melhorias documentais e estruturais no Kryonix Brain sem quebrar runtime.

## Passos

1. Ler `AGENTS.md`.
2. Ler `docs/brain/*` e `docs/ai/*`.
3. Inspecionar `modules/nixos/services/brain.nix` e `hosts/glacier/*`.
4. Criar plano pequeno.
5. Aplicar uma mudança por vez.
6. Validar Nix.
7. Se runtime disponível, validar Brain/Ollama/Neo4j.

## Validação

```bash
git status --short
git diff --stat
nix fmt . || true
nix flake check --keep-going
nh os build .#glacier -L --show-trace
```

## Riscos

- Quebrar Brain API.
- Mover dados sem backup.
- Indexar secrets.
- Criar duplicidade entre Vault e Neo4j.
- Abrir Neo4j em rede pública.

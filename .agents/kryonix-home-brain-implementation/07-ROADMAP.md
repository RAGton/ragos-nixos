# 07 — Roadmap recomendado

## Agora

Implementar apenas:

```bash
kryonix home scan
kryonix home report
kryonix home duplicates
kryonix home plan --dry-run
```

## Depois

### Fase 2

```bash
kryonix home apply --staging
kryonix home rollback <run-id>
kryonix home quarantine --identical-duplicates
```

### Fase 3

```bash
kryonix home analyze --ai
```

Usar Ollama para:

- resumir PDF/documento;
- classificar;
- gerar tags;
- sugerir novo nome.

### Fase 4

```bash
kryonix home learn
```

Enviar para Brain/RAG/CAG.

### Fase 5

```bash
kryonix home graph sync
```

Criar nós e relações no Neo4j.

### Fase 6

```bash
kryonix home daemon enable
```

Ativar daemon/timer declarativo.

## Prioridades técnicas

1. Segurança.
2. Dry-run.
3. Auditoria.
4. Manifesto.
5. Rollback.
6. Busca.
7. IA.
8. Automação.

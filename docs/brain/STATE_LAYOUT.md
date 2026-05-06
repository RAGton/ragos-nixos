# Layout de Estado do Kryonix Brain

Status: Roadmap / Arquitetura proposta

## Regra

`/var/lib/kryonix` guarda estado gerado por serviço. Não é local para documentação humana primária.

## Estrutura alvo

```txt
/var/lib/kryonix/
├── brain/
│   ├── storage/
│   │   └── (Arquivos do LightRAG, graphml, NanoVectorDB)
│   ├── cache/
│   ├── snapshots/
│   ├── neo4j/
│   │   ├── data/
│   │   ├── logs/
│   │   ├── import/
│   │   └── plugins/
│   ├── rag/
│   │   ├── manifests/
│   │   ├── chunks/
│   │   ├── embeddings/
│   │   ├── rerank/
│   │   └── cache/
│   ├── cag/
│   │   ├── context-cache/
│   │   ├── prompt-cache/
│   │   └── invalidation/
│   ├── reasoning/
│   │   ├── traces/
│   │   └── reports/
│   └── ingest/
│       ├── queue/
│       ├── processed/
│       ├── failed/
│       └── quarantine/
```

## Fora do `/var/lib`

```txt
/etc/kryonix/brain.env = secrets/config sensível
/var/log/kryonix       = logs persistentes
/run/kryonix           = runtime temporário
/etc/kryonix           = repo/declarativo, quando esse for o padrão do host
```

## Migração segura

1. Criar nova estrutura via NixOS/tmpfiles.
2. Não apagar dados antigos.
3. Não mover sem backup.
4. Documentar symlink temporário, se existir.
5. Validar serviços antes de remover compatibilidade.

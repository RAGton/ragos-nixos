# 02 — Arquitetura Técnica: Kryonix Home Brain

## 1. Visão macro

```txt
kryonix CLI
  ↓
kryonix home
  ↓
Rust core
  ├── scanner
  ├── ignore engine
  ├── metadata reader
  ├── hasher
  ├── duplicate detector
  ├── planner
  ├── reporter
  ├── audit store
  └── executor futuro
      ↓
SQLite/JSON manifests
      ↓
Brain/RAG/CAG/Neo4j futuro
```

## 2. Componentes Rust

### `cli.rs`

Responsável por argumentos:

```txt
home scan
home report
home duplicates
home plan --dry-run
home plan --json
```

Usar `clap`.

### `scanner.rs`

Responsável por percorrer diretórios.

Crates sugeridos:

```txt
walkdir
ignore
jwalk, opcional
```

### `ignore.rs`

Regras de ignorar:

- hidden dirs;
- config/cache;
- secrets;
- git repos;
- projetos.

### `metadata.rs`

Coleta:

```txt
path
filename
extension
mime
size
created_at
modified_at
is_symlink
```

Crates sugeridos:

```txt
infer
mime_guess
filetime
```

### `hashing.rs`

Calcula SHA256.

Crates sugeridos:

```txt
sha2
hex
```

Política:

- calcular hash por padrão só para arquivos menores que limite configurável;
- opção `--hash-all`;
- opção `--no-hash`;
- cache futuro por `(path, size, mtime)`.

### `planner.rs`

Sugere destino.

Exemplo:

```txt
application/pdf -> Documentos/Revisar ou Documentos/Tecnico
image/png -> Midia/Imagens
video/mp4 -> Midia/Videos
audio/flac -> Midia/Audio
application/zip -> Arquivos/Compactados
application/x-iso9660-image -> Arquivos/ISOs
```

### `report.rs`

Gera saída humana e JSON.

### `audit.rs`

Na Fase 1 pode usar JSON local.

Futuro: SQLite.

## 3. Estrutura sugerida

```txt
packages/kryonix-home/
├── Cargo.toml
└── src/
    ├── main.rs
    ├── cli.rs
    ├── scanner.rs
    ├── ignore.rs
    ├── metadata.rs
    ├── hashing.rs
    ├── planner.rs
    ├── report.rs
    ├── audit.rs
    └── error.rs
```

## 4. Integração com CLI existente

Se `kryonix` já for shell modular, existem duas opções:

### Opção A — binário separado

```bash
kryonix-home scan
```

E o shell `kryonix` chama:

```bash
kryonix-home "$@"
```

### Opção B — integrar direto no Rust CLI principal

Melhor a médio prazo se a CLI já estiver migrando para Rust.

## 5. Estado local

Usar:

```txt
~/.local/state/kryonix/home-brain/
```

Arquivos:

```txt
latest-scan.json
latest-plan.json
runs/<run-id>/scan.json
runs/<run-id>/plan.json
runs/<run-id>/report.md
```

## 6. Manifesto de plano

```json
{
  "run_id": "20260508-120000-inspiron",
  "mode": "dry-run",
  "root": "/home/rocha",
  "files_seen": 842,
  "files_ignored": 1293,
  "proposals": [
    {
      "action": "move",
      "risk": "low",
      "confidence": 0.88,
      "old_path": "/home/rocha/Downloads/manual.pdf",
      "new_path": "/home/rocha/Documentos/Tecnico/manual.pdf",
      "reason": "PDF tecnico detectado por extensao/MIME",
      "sha256": "..."
    }
  ]
}
```

## 7. Integração futura com Brain

Fluxo:

```txt
File
  -> content extractor
  -> summary
  -> tags
  -> embeddings
  -> CAG cache
  -> RAG chunks
  -> Neo4j relations
```

## 8. Busca futura

```bash
kryonix home search "contrato de internet"
```

Retornar:

```txt
path
descrição
categoria
tags
confidence
por que esse resultado apareceu
```

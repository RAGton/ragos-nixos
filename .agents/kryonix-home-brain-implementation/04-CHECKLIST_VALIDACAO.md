# 04 — Checklist de Validação

## Antes de rodar

```bash
cd /etc/kryonix
git status --short
```

Se houver mudanças locais importantes, salvar/commitar antes.

## Validação de sintaxe/formatação

```bash
nix fmt . || true
git diff --check
```

Se houver Rust:

```bash
cargo fmt --all
cargo clippy --all-targets --all-features
cargo test --all
```

Se houver scripts shell:

```bash
bash -n packages/kryonix-cli/*.sh
```

## Build

```bash
nix build .#kryonix --no-link
```

## Testes da CLI

```bash
nix run .#kryonix -- home scan
nix run .#kryonix -- home report
nix run .#kryonix -- home duplicates
nix run .#kryonix -- home plan --dry-run
nix run .#kryonix -- home plan --json
```

## Validação de segurança

Confirmar que:

- nenhum arquivo foi movido;
- nenhum arquivo foi renomeado;
- nenhum arquivo foi apagado;
- nenhuma pasta oculta foi escaneada;
- nenhuma chave SSH foi lida;
- `.env`, `brain.env`, `neo4j.env` não aparecem no output;
- o plano é dry-run;
- duplicatas são apenas SHA256 igual.

## Scan de secrets

```bash
git diff | rg -n "api[_-]?key|token|secret|password|passwd|bearer|authorization|private|id_ed25519|KRYONIX_BRAIN_API_KEY|NEO4J_AUTH|BEGIN .*PRIVATE" -i || true
git ls-files | grep -E '(^|/)(brain\.env|neo4j\.env|\.env|.*secret.*|.*token.*|id_ed25519.*)$' || true
```

## Conferir estado gerado

```bash
ls -lah ~/.local/state/kryonix/home-brain || true
find ~/.local/state/kryonix/home-brain -maxdepth 3 -type f | sort | head -100
```

## Conferir se nada foi alterado na Home

Antes e depois:

```bash
find ~/Downloads ~/Documentos ~/Imagens ~/Vídeos ~/Músicas -maxdepth 1 -type f 2>/dev/null | sort | sha256sum
```

## Commit

```bash
git status --short
git diff --stat
git add <arquivos certos>
git commit -m "feat(home): add safe file scanning and organization planning"
```

# Rules — Kryonix Brain

## Segurança

- API deve falhar fechada quando `KRYONIX_BRAIN_KEY` não estiver configurado, exceto se `KRYONIX_BRAIN_ALLOW_NO_AUTH=true`.
- Não abrir Brain API em `0.0.0.0` por padrão. Use `127.0.0.1`.
- Exposição externa deve ser por Tailscale, SSH tunnel ou proxy explicitamente configurado.
- Nunca gravar secret no Vault/RAG sem passar por scanner/redactor.

## GPU e gaming

- `ollama.service` pode iniciar no boot.
- Warmup/preload de modelo no boot deve ser `false` por padrão.
- `OLLAMA_KEEP_ALIVE` deve ser curto ou configurável.
- Criar comandos:
  - `kryonix brain start`
  - `kryonix brain stop`
  - `kryonix brain unload`
  - `kryonix brain gamer-mode`

## Storage

- Estado mutável não deve ficar acoplado ao store Nix.
- Caminho atual permitido:
  `/var/lib/kryonix`
- Módulo NixOS deve aceitar `cfg.brainHome`, `cfg.storagePath`, `cfg.vaultPath`.

## Git

- Commits pequenos:
  - `fix(mcp): serialize rag responses`
  - `fix(api): require auth by default`
  - `feat(cag): add context pack commands`
  - `feat(graph): categorize obsidian exports`
  - `test(eval): add grounding regression suite`
- Não misturar refactor grande com bugfix.

## Menos token

- Use `rg`, `sed -n`, `git diff --stat`, `git diff -- <arquivo>`.
- Não despeje arquivos inteiros no relatório.
- Relatório final deve ser objetivo.

# Kryonix Brain Safe Deploy

Status: Implementado

Este fluxo existe para impedir que o Brain do Glacier seja atualizado quando o
checkout contém arquivos suspeitos, chaves expostas, submódulos desalinhados ou
runtime que ainda não passou por smoke test.

O comando principal é:

```sh
kryonix brain deploy-safe --host glacier
```

Ele nunca executa `switch` sem a flag explícita `--switch`.

## Comandos

### Preflight de secrets

```sh
kryonix brain preflight-secrets --host glacier
kryonix brain preflight-secrets --host glacier --json
kryonix brain preflight-secrets --host glacier --quarantine-untracked
```

O scanner reporta apenas caminho, regra, severidade e ação recomendada. Ele não
imprime a linha nem o valor encontrado.

Estados:

- `PASS`: nenhum suspeito encontrado.
- `WARN`: achados de baixa/média severidade, sem valor real detectado.
- `BLOCKED`: achado de alta severidade ou chave provável.
- `QUARANTINED`: suspeitos não rastreados foram movidos para quarentena.

Política de severidade:

| Severidade | Ação |
| --- | --- |
| `critical` / `high` | bloqueia o deploy |
| `medium` | permite com `WARN` |
| `low` / `info` | permite |
| não rastreado suspeito | bloqueia ou move com `--quarantine-untracked` |

Arquivos não rastreados suspeitos só são movidos com:

```sh
--quarantine-untracked
```

A quarentena fica em:

```txt
~/.local/share/kryonix/private-prompts/<hostname>-<timestamp>/
```

Arquivos rastreados nunca são movidos automaticamente.

### Rotação da API key

```sh
kryonix brain rotate-api-key --host glacier --dry-run
kryonix brain rotate-api-key --host glacier --confirm --validate
```

O comando:

- sem `--confirm`, não altera nada;
- com `--dry-run`, mostra o plano e não cria backup, chave ou restart;
- cria backup root-only em `/root/kryonix-secret-backups/`;
- gera nova `KRYONIX_BRAIN_API_KEY`;
- instala `/etc/kryonix/brain.env` como `root:root 0600`;
- reinicia `kryonix-brain-api.service` ou `kryonix-brain.service`;
- valida `/health` e `/stats`;
- não imprime o valor da chave.

Se houve suspeita de vazamento, não restaure a chave antiga. Faça nova rotação.

## Bootstrap remoto

O comando remoto depende do checkout do Glacier já conter esta versão da CLI. O
fluxo correto é em duas fases:

```sh
# No host de desenvolvimento
git push origin main

# No Glacier
cd /etc/kryonix
git pull --ff-only origin main
git submodule update --init --recursive

# Depois do pull
kryonix brain deploy-safe --host glacier --test
```

Não use `deploy-safe --host glacier` para bootstrapar um Glacier que ainda não
recebeu o commit do próprio comando.

### Deploy seguro

```sh
kryonix brain deploy-safe --host glacier --quarantine-untracked --rotate-if-leaked --test
```

Quando o comando precisa executar no Glacier a partir de outro host, ele usa a
flake Git local (`git+file:///etc/kryonix#kryonix`) em vez de
`path:/etc/kryonix#kryonix`. Isso evita que o Nix tente copiar arquivos secretos
fora do Git, como `/etc/kryonix/brain.env`.

Fluxo:

1. roda `preflight-secrets`;
2. bloqueia se houver suspeita ativa;
3. move suspeitos não rastreados somente com `--quarantine-untracked`;
4. rotaciona a chave se `--rotate-if-leaked` detectar vazamento;
5. exige `git status` limpo;
6. executa `git fetch origin`;
7. executa `git pull --ff-only origin main`;
8. atualiza submódulos;
9. roda `kryonix git-status`;
10. roda `kryonix check --host glacier`;
11. roda `kryonix rebuild --host glacier`;
12. roda `kryonix test --host glacier` somente com `--test`;
13. executa smokes Brain/RAG/CAG;
14. executa `kryonix switch --host glacier` somente com `--switch`.

Para aplicar permanente:

```sh
kryonix brain deploy-safe --host glacier --quarantine-untracked --rotate-if-leaked --test --switch
```

`--switch` requer `--test`.

## Smokes

O deploy seguro valida:

- `/health`;
- `/stats` autenticado;
- ask comparativo `ask` vs `search`;
- search comparativo `ask` vs `search`;
- normalização de `seaarch -> search`;
- CAG status;
- CAG ask.

Critérios:

- `missing_manifest` no CAG é `WARN`;
- HTTP 500 por manifest ausente é `FAIL`;
- `Grounding: Alta` com “não encontrei grounding suficiente” é `FAIL`;
- ausência de `intent`/`mode` no `/search` é `FAIL`;
- typo sem normalização é `FAIL`.

## Rollback

Código:

```sh
git revert <root_commit>
cd packages/kryonix-brain-lightrag
git revert <brain_commit>
cd /etc/kryonix
git add packages/kryonix-brain-lightrag
git commit -m "revert(brain): rollback safe deploy target"
```

Chave:

- não restaure chave antiga se houve suspeita de vazamento;
- rode nova rotação com `kryonix brain rotate-api-key --host glacier --confirm --validate`.

## Comandos proibidos pelo fluxo

O safe deploy não executa:

- `boot`;
- `reboot`;
- `disko`;
- `mkfs`;
- `wipefs`;
- `parted`;
- `sgdisk`.

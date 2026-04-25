# Operação do RagOS VE

**Atualizado em:** 2026-04-20

## Fluxo padrão

A CLI `ragos` é o ponto de entrada operacional do projeto. Ela usa `nh`, `nix` e `nvd` por baixo e detecta o host atual para reduzir comandos manuais.

## Resolução da flake

A origem da flake segue esta ordem:

1. `--flake <path|uri>` informado no comando
2. variável de ambiente `RAGOS_FLAKE`
3. checkout local do projeto no diretório atual ou em algum pai com `flake.nix`
4. `/etc/ragos/flake.nix`, quando o sistema já foi instalado
5. erro com instrução clara para informar a flake manualmente

Em modo `--verbose`, a CLI mostra o host atual, a flake resolvida e o modo detectado (`explicit`, `env`, `dev-repo` ou `etc-ragos`).

No uso diário, o checkout local do projeto tem precedência sobre `/etc/ragos`. Em máquinas instaladas, a origem padrão passa a ser `/etc/ragos`.

## Comandos do dia a dia

```sh
ragos switch
ragos pull
ragos deploy
ragos sync
ragos switch --update
ragos boot --update
ragos test
ragos home
ragos diff
ragos doctor
ragos git-status
ragos check
ragos fmt
ragos iso
```

## O que cada comando faz

- `ragos switch`: aplica a configuração do host atual com `nh os switch`
- `ragos pull`: entra em `/etc/ragos`, faz `git fetch` e `git pull --rebase`, abortando em Git quebrado, branch incorreta ou conflito
- `ragos deploy`: valida a flake de `/etc/ragos` e roda `nh os switch /etc/ragos -H <host>`
- `ragos sync`: executa `ragos pull` e, se o Git estiver íntegro, valida a flake e faz o deploy
- `ragos switch --update`: atualiza inputs e aplica
- `ragos boot`: prepara a próxima geração para o próximo boot
- `ragos test`: testa a geração sem persistir como default
- `ragos home`: aplica o Home Manager do usuário atual
- `ragos update`: atualiza os inputs da flake
- `ragos clean`: limpa gerações antigas com `nh clean all`
- `ragos diff`: compara `/run/current-system` com a próxima geração
- `ragos repl`: abre `nix repl` na flake
- `ragos doctor`: mostra host, flake, mount de storage e avaliação rápida
- `ragos git-status`: mostra branch, `origin` e mudanças locais de `/etc/ragos`
- `ragos vm`: lista VMs via `virsh`
- `ragos iso`: builda a ISO pública do projeto
- `ragos fmt`: roda o formatter da flake
- `ragos check`: roda `nix flake check --keep-going`

## Exemplos úteis

```sh
ragos switch --verbose
ragos pull
ragos deploy
ragos sync
ragos switch --host glacier
ragos home --user rocha
ragos diff
ragos doctor
ragos git-status
```

## Fluxo recomendado no `glacier`

1. `ragos fmt`
2. `ragos check`
3. `ragos diff`
4. `ragos test`
5. `ragos boot`

Use `ragos switch` quando a mudança já estiver segura para ativação imediata.

## Observações

- o hostname em runtime do host principal pode ser `RVE-GLACIER`, mas o target da flake continua `glacier`
- a CLI já faz esse mapeamento automaticamente
- fora do checkout local, a CLI usa `/etc/ragos` como origem padrão instalada
- `/etc/ragos` deve ser um checkout Git em `main` com `origin`; `ragos git-status` é o preflight rápido antes de aplicar mudanças
- `ragos pull` aborta quando encontra mudanças locais versionadas, merge/rebase em andamento ou conflito no `git pull --rebase`
- `ragos deploy` e `ragos sync` abortam quando `nix flake check` falha

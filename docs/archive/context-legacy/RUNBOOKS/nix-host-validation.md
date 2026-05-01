# Runbook: Validação Nix por Host

## Regra

Em árvore suja, prefira `path:$PWD`.

## Sequência mínima

```bash
nix flake show path:$PWD
nix flake check path:$PWD --keep-going
```

## Builds por host

```bash
nix build 'path:$PWD#nixosConfigurations.<host>.config.system.build.toplevel'
nix build 'path:$PWD#homeConfigurations."<user>@<host>".activationPackage'
```

## Honestidade operacional

- declare erro antigo como antigo
- declare erro novo como introduzido pelo patch
- não esconda falha causada por árvore suja ou ambiente local

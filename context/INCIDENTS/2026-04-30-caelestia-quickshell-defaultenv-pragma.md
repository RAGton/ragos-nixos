# Incidente - 2026-04-30 - Caelestia falha com pragma DefaultEnv incompatível

## Sintoma

`caelestia.service` falhava ao iniciar com:

```text
ERROR: Unrecognized pragma "DefaultEnv QS_NO_RELOAD_POPUP=1"
```

## Causa raiz

O `shell.qml` do input `caelestia-shell` continha a linha:

```qml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
```

A versão atual do QuickShell usada pelo flake não reconhece esse pragma.

## Correção

O pacote efetivo do Caelestia é ajustado em `modules/nixos/desktop/caelestia/default.nix`
com `overrideAttrs.postPatch`, removendo a linha antes do build:

```sh
sed -i '/QS_NO_RELOAD_POPUP/d' shell.qml
```

Não edite o arquivo em `/nix/store` manualmente.

## Validação

- Build do pacote efetivo do `inspiron` passou.
- `share/caelestia-shell/shell.qml` no output reconstruído não contém `QS_NO_RELOAD_POPUP`.
- `nix flake check --keep-going path:.` passou.

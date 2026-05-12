# Rust (cargo / rustup) — PT-BR

Este repo instala tooling de Rust de forma global e também pode aplicar ajustes no ambiente do usuário via Home Manager.

## Sistema (NixOS)

Pacotes globais em `modules/nixos/common/default.nix`:

- `rustup`
- `cargo`
- `rustc`

### Primeiro uso (rustup)

Mesmo com `rustup` instalado, você precisa definir uma toolchain default no seu usuário:

```sh
rustup default stable
```

Depois valide:

```sh
cargo --version
rustc --version
```

## Usuário (Home Manager)

Existe um módulo do Rust em:

- `modules/home-manager/programs/rust/`

Se você preferir usar **apenas** o Rust do Nix (mais reprodutível), você pode desabilitar o uso de rustup no seu fluxo e fixar versões via flake/devShell.

## Nota sobre conflitos (PATH)

- O `rustup` cria wrappers em `$CARGO_HOME/bin`.
- Se o shell priorizar esses wrappers, `cargo`/`rustc` podem depender da toolchain do rustup.
- Definir `rustup default stable` geralmente resolve a confusão inicial.


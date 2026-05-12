# Kryonix

Kryonix is a declarative NixOS platform for workstation, gaming, virtualization, study, and development.

- Main repository: `https://github.com/RAGton/kryonix`
- Knowledge vault: `https://github.com/RAGton/kryonix-vault.git`
- Language: [PT-BR](README.md) | English

## Daily Flow

The primary operational CLI is `kryonix`:

```sh
kryonix switch
kryonix switch --update
kryonix boot --update
kryonix home
kryonix diff
kryonix doctor
kryonix check
kryonix fmt
kryonix iso
```

The old `ragos` command remains available temporarily as a compatibility alias and prints `ragos is deprecated, use kryonix`.

## Quick Start

```sh
git clone https://github.com/RAGton/kryonix kryonix
cd kryonix
nix flake show --all-systems
nix flake check --keep-going
```

Apply the current host:

```sh
kryonix switch
```

## Operational Safety

- do not use `disko`, `format-*`, or `install-system` on the already-installed `glacier` host
- do not treat `hosts/glacier/disks.nix` as the source of truth for current hardware
- prefer `kryonix test` and `kryonix boot` before higher-risk changes

## License

Starting with the current version, Kryonix is distributed as **Source Available / Proprietary — All Rights Reserved**.

The source code is available for reading, personal auditing, study, and evaluation, but you may not copy, redistribute, sublicense, sell, publish derivatives, create derivative ISOs/distributions, hosted services, appliances, or commercial products based on Kryonix without explicit written permission from Gabriel Aguiar Rocha.

Third-party components, dependencies, and external projects used by Kryonix remain governed by their respective licenses. This license does not alter the licenses of NixOS, nixpkgs, Home Manager, Ollama, Neo4j, LightRAG, or any external dependency.

Historical versions that were published under another license remain governed by the license that accompanied those versions.

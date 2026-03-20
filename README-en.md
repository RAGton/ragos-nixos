# RAGOS

Public flake for my NixOS hosts and Home Manager profiles.

- Canonical repository: `RAGton/ragos-nixos`
- Default branch: `main`
- Release mode: `Tagged`
- Language: English | [PT-BR](README.md)

## Public scope

This repository currently exports:

- `nixosConfigurations` for `inspiron`, `inspiron-nina`, `glacier`, and `iso`
- `homeConfigurations` for `rocha@inspiron`, `rocha@glacier`, and `nina@inspiron-nina`
- reusable project overlays
- `formatter`
- `checks`

Some macOS-oriented modules still live in-tree, but the public flake does not export any `darwinConfigurations` yet.

## Desktop focus

The active desktop path in this repository is `Hyprland + DankMaterialShell + GDM`.
KDE Plasma is not part of the supported shell path, but selected KDE file tools such as Dolphin and KIO remain welcome.

## Credits

- DankMaterialShell by AvengeMedia
- DMS upstream: https://github.com/AvengeMedia/DankMaterialShell

## Quick start

```sh
git clone https://github.com/RAGton/ragos-nixos
cd ragos-nixos
nix flake show --all-systems
nix flake check --keep-going
```

Apply a NixOS host:

```sh
sudo nixos-rebuild switch --flake .#inspiron
```

Apply Home Manager:

```sh
home-manager switch --flake .#rocha@inspiron
```

## Password bootstrap

This repository intentionally ships no bootstrap password for `root` or any user.

For fresh installs, set passwords manually before first boot, for example:

```sh
passwd root
passwd rocha
```

If you need non-interactive bootstrap, inject `hashedPasswordFile` or `initialHashedPassword` from outside this public repository.

## Documentation

- [Documentation index](docs/INDEX.md)
- [Makefile guide](docs/MAKEFILE_GUIDE.md)
- [Boot and recovery](docs/BOOT_RECOVERY.md)
- [Apply to Nina's host without formatting](docs/INSPIRON_NINA_APPLY.md)

## License

MIT. See [LICENSE](LICENSE).

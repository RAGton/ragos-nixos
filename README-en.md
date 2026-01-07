# NixOS and nix-darwin Configurations for My Machines

This repository contains my NixOS and nix-darwin configurations, managed through [Nix Flakes](https://nixos.wiki/wiki/Flakes).

Language: [PT-BR](README.md) | English (this file)

It is structured to scale across multiple machines and users, leveraging [nixpkgs](https://github.com/NixOS/nixpkgs), [home-manager](https://github.com/nix-community/home-manager), [nix-darwin](https://github.com/LnL7/nix-darwin), and other community projects.

## Showcase

### Hyprland

![hyprland](./files/screenshots/hyprland.png)

### KDE

![kde](./files/screenshots/kde.png)

### macOS

![macos](./files/screenshots/mac.png)

## Structure

- `flake.nix`: single source of truth (inputs/outputs for NixOS, nix-darwin and Home Manager).
- `hosts/`: per-machine system configuration (e.g. `inspiron`).
- `home/`: per-user, per-host Home Manager entry points.
- `files/`: assets and misc files (scripts, wallpapers, screenshots, avatar, etc.).
- `modules/`: reusable modules split by responsibility:
  - `modules/nixos/`: Linux system modules.
  - `modules/darwin/`: macOS system modules.
  - `modules/home-manager/`: user-space modules.
- `overlays/`: custom overlays.
- `flake.lock`: pinned inputs for reproducibility.

## Usage

### Apply configurations (NixOS)

- System:

```sh
sudo nixos-rebuild switch --flake .#inspiron
```

- User (Home Manager):

```sh
home-manager switch --flake .#rag@inspiron
```

### Makefile shortcuts

The [Makefile](Makefile) provides common targets.

- By default, it assumes your local hostname matches the flake output (e.g. `Glacier` → `.#Glacier`).
- You can override variables to target a different host/user.

List available targets:

```sh
make help
```

Common examples:

```sh
make nixos-rebuild
make home-manager-switch
make flake-check
make flake-update
```

#### How it works (variables)

- `HOSTNAME`: used to build the default target. Default: `$(hostname)`.
- `FLAKE`: system target. Default: `.#$(HOSTNAME)`.
- `HOME_TARGET`: Home Manager target. Default: `$(FLAKE)` (you will usually want something like `.#rag@Glacier`).
- `EXPERIMENTAL`: `nix` flags required for flakes in some commands.

Override examples:

```sh
# Apply NixOS for a specific host (without relying on local hostname)
make nixos-rebuild FLAKE=.#Glacier

# Apply Home Manager using user@host
make home-manager-switch HOME_TARGET=.#rag@Glacier

# Update flake inputs
make flake-update
```

## Install (LiveCD / ISO only) — NixOS

How to install from scratch using only the NixOS ISO + this repo (flake).

> Tip: on the ISO, it helps to become root first with `sudo -i` before partitioning/mounting.

### 1) Boot + networking

- Boot the NixOS ISO.
- Connect to the internet (Ethernet or `nmtui`).

### 2) Partition and mount (Btrfs + subvolumes)

Example layout (no encryption): one EFI partition (`/boot`) and one Btrfs partition.

> Tip: [hosts/Glacier/disks.nix](hosts/Glacier/disks.nix) documents the expected layout for `Glacier`.

Mount to `/mnt` using subvolumes (adjust `DISK`, `ESP` and `ROOT`):

```sh
# example (DO NOT copy without adjusting):
# DISK=/dev/nvme0n1
# ESP=${DISK}p1
# ROOT=${DISK}p3

mkfs.vfat -n BOOT-NIXOS "$ESP"
mkfs.btrfs -f "$ROOT"

mount "$ROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home

# optional, recommended if you use snapper
btrfs subvolume create /mnt/@snapshots

umount /mnt

mount -o subvol=@,compress=zstd,noatime "$ROOT" /mnt
mkdir -p /mnt/{home,.snapshots,boot}
mount -o subvol=@home,compress=zstd,noatime "$ROOT" /mnt/home
mount -o subvol=@snapshots,compress=zstd,noatime "$ROOT" /mnt/.snapshots
mount "$ESP" /mnt/boot
```

### 3) Clone repo and install with flake

From the ISO, clone this repo into the target system and run `nixos-install` pointing to the host:

```sh
mkdir -p /mnt/etc
git clone https://github.com/RAGton/dotfiles-NixOs /mnt/etc/nixos

# replace with your host (e.g. Glacier / inspiron)
nixos-install --flake /mnt/etc/nixos#Glacier
```

If you're installing on different hardware than what is already committed in `hosts/<host>/hardware-configuration.nix`, regenerate and adjust that file before running `nixos-install`.

### 4) Post-install

After reboot, apply Home Manager:

```sh
home-manager switch --flake /etc/nixos#rag@Glacier
```

If `home-manager` is not available in PATH on first login:

```sh
nix-shell -p home-manager
home-manager switch --flake /etc/nixos#rag@Glacier
```

## Git: SSH auth vs `gitKey` (commit signing)

This repo uses two separate concepts:

1) **SSH key (authentication to GitHub/GitLab)**

- Used for `git clone/pull/push` without passwords/tokens.
- Lives in `~/.ssh/` (e.g. `id_ed25519` + `id_ed25519.pub`).
- You add the **public key** (`.pub`) to GitHub/GitLab.

1) **`gitKey` (commit signing, via Home Manager)**

- In the flake, `users.<name>.gitKey` is consumed by [modules/home-manager/programs/git/default.nix](modules/home-manager/programs/git/default.nix).
- It sets `programs.git.signing.key` (commit signing). This is typically a **GPG/OpenPGP key ID**.
- If `gitKey = "";`, signing is **not** enabled (simpler for bootstrap).

### Create and add an SSH key (auth)

```sh
ls ~/.ssh
ssh-keygen -t ed25519 -C "you@example.com"
cat ~/.ssh/id_ed25519.pub
```

Then add the public key on GitHub: **Settings → SSH and GPG keys → New SSH key**.

### Configure commit signing (GPG)

Create/import a GPG key, find its long ID, and set `gitKey` to that value:

```sh
gpg --list-secret-keys --keyid-format=long
```

> Important: never commit private keys or put them in the Nix store. `gitKey` here is just an identifier for Git.

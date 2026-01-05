# Copilot Instructions for AI Coding Agents

## Project Overview

This repository manages **NixOS** and **nix-darwin** configurations for multiple machines using a **flake-first, fully declarative, and highly modular architecture**.

The primary goals of this project are:

* **Reproducibility** across machines and platforms
* **Portability** between Linux and macOS
* **Scalability** as new hosts, users, and features are added
* **Low cognitive overhead** through strict modular boundaries

The system is built around **Nix flakes**, **Home Manager**, and **platform-specific modules**, with a clear separation between system-level and user-level concerns.

---

## Core Architectural Principles

### 1. Flake-Centric Design

* `flake.nix` is the **single source of truth**
* All inputs, overlays, systems, and users are declared there
* No imperative configuration outside Nix

### 2. Strict Modularization

Configurations are split by **responsibility**, not by host:

```
modules/
├── nixos/          # System-level Linux modules
├── darwin/         # System-level macOS modules
├── home-manager/   # User-level configuration
```

Each module should:

* Do **one thing well**
* Be reusable across hosts
* Avoid host-specific assumptions

---

## Directory Responsibilities

### `hosts/`

* System-level configuration per machine
* Minimal logic: mostly imports + hardware-specific settings
* Naming convention matches flake outputs

### `home/`

* Per-user Home Manager entry points
* Imports reusable modules from `modules/home-manager/`
* Host-aware, but **user-centric**

### `modules/home-manager/`

Reusable user modules, including:

* Shells (zsh)
* Desktop environments
* Services
* Scripts
* Tooling (kubectl, AWS, etc.)

### `modules/home-manager/scripts/bin/`

* Custom executable scripts
* Automatically deployed to `~/.local/bin`
* Scripts must:

  * Declare dependencies clearly
  * Be shell-agnostic when possible
  * Avoid hardcoded paths

---

## Developer Workflows (Canonical)

### Apply System Configuration

```bash
nixos-rebuild switch --flake .#hostname
```

### Apply User Configuration

```bash
home-manager switch --flake .#user@hostname
```

There are **no automated tests**. Validation is done by:

* Successful evaluation
* Activation without warnings
* Verifying system/user state post-deploy

---

## Project Conventions (Important)

### Theming

* **Catppuccin** is the global theme baseline
* Applied consistently across:

  * Terminal
  * Desktop
  * CLI tools
* Defined via a dedicated flake input and reused in modules

### Desktop Management

* KDE, window rules, shortcuts, and behaviors are **fully declarative**
* See:

  * `desktop/kde/default.nix`
  * `programs/aerospace/default.nix`

No manual GUI configuration should be required after rebuild.

---

## Shell & Productivity

### Zsh

* Zsh is the default shell
* Aliases and functions are extensive and intentional
* Focus areas:

  * Git
  * Kubernetes
  * AWS
  * Navigation
* Source of truth:

  ```
  programs/zsh/default.nix
  ```

### Scripts

* Scripts are first-class citizens
* Invoked directly from shell
* Must work identically on fresh machines

---

## Kubernetes & Cloud Tooling

* `krew` plugins are managed declaratively
* Installed and updated automatically on activation
* Custom scripts support:

  * Cluster inspection
  * AWS workflows
  * Day-2 operations

Source:

```
programs/krew/default.nix
```

---

## Cross-Component Integration

* System and user modules may share values (e.g. wallpaper, username)
* Sharing is done via:

  * Module arguments
  * Explicit imports
* Avoid implicit coupling

### Platform Detection

* macOS vs Linux logic must use:

```nix
stdenv.isDarwin
```

No OS assumptions elsewhere.

---

## Common Extension Patterns

### Add a Package for All Users

Edit:

```
modules/home-manager/common/default.nix
```

### Customize KDE

Edit:

```
modules/home-manager/desktop/kde/default.nix
```

### Add a New Script

1. Place it in:

   ```
   modules/home-manager/scripts/bin/
   ```
2. Ensure it is executable
3. Declare required dependencies

---

## Documentation & Discovery

* `README.md` contains the high-level overview
* When in doubt:

  * Read the module
  * Follow existing patterns
  * Prefer clarity over cleverness

---

## Final Guidance for AI Agents

* Respect the modular boundaries
* Do not introduce imperative state
* Prefer reuse over duplication
* Keep hosts thin, modules rich
* If uncertain, ask via pull request rather than guessing

This repository values **discipline over shortcuts**.
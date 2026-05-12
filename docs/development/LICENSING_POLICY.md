# Kryonix Licensing Policy

## Status

Source Available / Proprietary — All Rights Reserved.

## Scope

This policy applies to Kryonix-authored code, documentation, assets, scripts,
modules, packages, wallpapers, branding, and subprojects authored by Gabriel
Aguiar Rocha, including AI-assisted work directed by him.

## Not Covered

This policy does not relicense third-party dependencies or external projects,
including NixOS, nixpkgs, Home Manager, Ollama, Neo4j, LightRAG, Python crates,
Rust crates, Node packages, fonts, themes, or any external dependency.

## Historical MIT Versions

Previous commits/releases that were explicitly published with the MIT License
remain governed by the license terms attached to those versions. The current
license applies from this licensing change forward.

## Submodules

Only Kryonix-owned submodules may be relicensed. Third-party submodules must
retain their upstream license.

## Nix Metadata

Kryonix-owned packages should use an unfree license metadata attribute, such as
`lib.licenses.unfree` or `lib.licenses.unfreeRedistributable`, depending on what
is available in the pinned nixpkgs.

## Contributor Rule

Do not accept external contributions unless the contributor explicitly agrees
that the contribution is assigned or licensed to the Kryonix proprietary license
terms.

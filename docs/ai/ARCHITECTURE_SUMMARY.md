# ARCHITECTURE_SUMMARY

## Visao geral

Kryonix e uma arquitetura declarativa em camadas para NixOS. A flake compoe hosts, Home Manager, modulos, features, profiles, overlays e pacotes operacionais. O objetivo e manter hosts reais reproduziveis, com rollback por geracao e contexto curto para agentes.

## Camadas

```text
flake.nix
  -> hosts/<host>
    -> hosts/common
      -> lib/options.nix
      -> modules/nixos/**
      -> features/**
      -> profiles/**
      -> desktop/hyprland/**
  -> home/<user>/<host>
    -> modules/home-manager/**
  -> packages/kryonix-cli.nix
  -> overlays/default.nix
```

## Principios locais

- Hosts descrevem hardware e escolhas de alto nivel.
- Profiles compoem papeis.
- Features habilitam capacidades.
- Modules implementam comportamento.
- Home Manager configura usuario.
- Overlays isolam patches de pacote.
- Packages expõem ferramentas operacionais.

## Estado atual

- Desktop ativo: Hyprland.
- Shell/rice principal: Caelestia.
- DMS: legado em transicao.
- CLI primaria: `kryonix`.
- CLI legada: `kryonix`.
- Host principal de produto: `glacier`.
- ISO: output de instalacao/provisionamento.

## Pontos de acoplamento

- `flake.nix` ainda centraliza usuarios e helpers de composicao.
- `desktop/hyprland/user.nix` concentra muita responsabilidade.
- `packages/kryonix-cli.nix` e grande e carrega logica operacional sensivel.
- `lib/options.nix` e contrato publico do namespace `kryonix.*`.

## Decisoes implicitas confirmadas no codigo

- `nixpkgs` principal vem de `nixos-unstable`.
- `nixpkgs-stable` e exposto por overlay.
- `allowUnfree = true` e usado nos pacotes dos hosts/homes.
- CI usa Determinate Nix e valida flake show/check.
- OpenAI Codex CLI e input da flake, mas feature AI pode ficar desligada por padrao para evitar builds lentos.

## Direcao saudavel

- Reduzir docs historicas divergentes em favor de `docs/CURRENT_STATE.md`, `context/` e `docs/ai/`.
- Quebrar mudancas grandes em PRs pequenos.
- Separar responsabilidades de `desktop/hyprland/user.nix`.
- Manter compatibilidade `kryonix` ate janela de migracao explicita.

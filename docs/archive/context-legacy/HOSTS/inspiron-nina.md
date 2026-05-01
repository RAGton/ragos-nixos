# Host `inspiron-nina`

- papel: notebook da Nina
- desktop: Hyprland
- shell: Caelestia
- perfil: laptop + dev + university, sem `rag.profiles.ti`

## Cuidados

- manter escopo leve
- evitar herdar decisões pesadas de `glacier`

## Validação típica

- `nix build 'path:$PWD#nixosConfigurations.inspiron-nina.config.system.build.toplevel'`
- `nix build 'path:$PWD#homeConfigurations."nina@inspiron-nina".activationPackage'`

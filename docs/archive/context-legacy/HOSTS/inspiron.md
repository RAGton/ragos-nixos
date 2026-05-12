# Host `inspiron`

- papel: notebook principal de desenvolvimento
- desktop: Hyprland
- shell: Caelestia
- foco atual: desenvolvimento local, validação de launcher e override local do Caelestia
- path local recomendado para upstream do shell: `/home/rocha/src/caelestia-shell`

## Cuidados

- evitar mudanças globais que quebrem `glacier`, `inspiron-nina` ou `iso`
- preferir validação local com `path:$PWD` quando houver árvore suja

## Validação típica

- `nix flake show path:$PWD`
- `nix build 'path:$PWD#nixosConfigurations.inspiron.config.system.build.toplevel'`
- `nix build 'path:$PWD#homeConfigurations."rocha@inspiron".activationPackage'`

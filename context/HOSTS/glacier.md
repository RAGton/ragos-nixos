# Host `glacier`

- papel: workstation principal para virtualização e gaming
- desktop: Hyprland
- shell: Caelestia
- storage operacional: `/srv/ragenterprise`

## Restrições

- tratar como host já instalado
- não usar `disko`, `format-*`, `install-system` ou `hosts/glacier/disks.nix` em patch incremental

## Validação típica

- `nix build 'path:$PWD#nixosConfigurations.glacier.config.system.build.toplevel'`
- `nix build 'path:$PWD#homeConfigurations."rocha@glacier".activationPackage'`

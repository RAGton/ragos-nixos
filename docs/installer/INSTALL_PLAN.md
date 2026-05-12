# Kryonix Install Plan

O arquivo `install-plan.json` é a especificação declarativa de como o sistema deve ser instalado. Ele é o intermediário entre a UI e o executor real.

## Exemplo de Plano

```json
{
  "version": 1,
  "profile": "desktop",
  "hostname": "kryonix",
  "timezone": "America/Cuiaba",
  "locale": "pt_BR.UTF-8",
  "keyboard": "br-abnt2",
  "boot": {
    "mode": "uefi"
  },
  "disk": {
    "mode": "dry-run",
    "target": "/dev/nvme0n1",
    "layout": "btrfs-simple"
  },
  "user": {
    "name": "rocha",
    "admin": true
  },
  "features": {
    "desktop": "hyprland-caelestia",
    "nvidia": "auto",
    "zram": true,
    "brain_client": true
  }
}
```

## Schema

O schema oficial encontra-se em `packages/kryonix-installer/schemas/install-plan.schema.json`.

### Campos Principais

*   **profile**: Define o conjunto de pacotes e serviços base.
*   **boot.mode**: `uefi` (recomendado) ou `bios`.
*   **disk.mode**: `dry-run` para testes e `real` para instalação efetiva.
*   **disk.layout**: Estrutura de partições sugerida.
*   **features**: Módulos opt-in do Kryonix.

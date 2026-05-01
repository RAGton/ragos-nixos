# ZRAM (swap comprimido) — PT-BR

Este repo habilita ZRAM por padrão para melhorar responsividade sob pressão de memória.

## Onde está configurado

- Módulo: `modules/nixos/common/default.nix`
- Opção NixOS: `zramSwap`

Defaults (mkDefault):

- `zramSwap.enable = true`
- `zramSwap.algorithm = "zstd"`
- `zramSwap.memoryPercent = 100`

> `memoryPercent = 100` significa: o dispositivo zram terá tamanho lógico próximo a 100% da RAM.

## Validar se está ativo

```sh
swapon --show
zramctl
```

Você deve ver `/dev/zram0` como swap.

## Override por host (recomendado)

Se quiser reduzir em máquinas com pouca RAM ou que já têm swap em disco grande, sobrescreva em:

- `hosts/<host>/default.nix`

Exemplo:

```nix
{
  # ...
  zramSwap.memoryPercent = 50;
}
```

## Dicas de tuning

- `vm.swappiness` também influencia quando o kernel começa a usar swap.
- ZRAM + swap em disco pode coexistir. Normalmente:
  - ZRAM (prioridade maior) ajuda com bursts
  - Swap em disco serve como fallback para OOM


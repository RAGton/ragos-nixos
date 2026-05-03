# Instalação manual do Trae no host

## Status

O Trae ficou fora da instalação declarativa porque este repositório não valida hoje um pacote Nix canônico e estável para ele.

## Fluxo sugerido

1. Baixe o `.deb` ou `.rpm` oficial do Trae.
2. Instale o app no host.
3. Garanta que o binário esteja em um destes caminhos:
   - `trae` no `PATH`
   - `~/.local/bin/trae`
   - `/opt/trae/trae`
4. Abra pelo wrapper:

```bash
trae-launcher
```

## Comportamento do wrapper

Se o binário não existir, `trae-launcher` falha com uma mensagem amigável e não quebra o restante do setup.

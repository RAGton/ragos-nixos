# Testes e Validação

Status: Implementado (gates definidos)

## Resumo
Validação é requisito para declarar qualquer mudança como pronta. O Kryonix separa validação de configuração e runtime.

## Validações básicas
```sh
nix fmt
nix flake show --all-systems
nix flake check --keep-going
```

## Validação segura de host
```sh
kryonix test
```

## Validação de documentação
```sh
./scripts/doc-audit.sh
kryonix doctor full
```

## Quando usar
Antes de aplicar mudanças (`boot`/`switch`) ou declarar algo pronto.

## Riscos
- Ignorar warnings no cliente quando o Glacier está offline.
- Rodar validações sem registrar evidência quando necessário.

## Links relacionados
- [Operações](Operacoes)
- [Segurança](Seguranca)
- [Troubleshooting](Troubleshooting)

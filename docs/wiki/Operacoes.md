# Operações

Status: Implementado (fluxo oficial)

## Resumo
O fluxo operacional oficial do Kryonix prioriza validação e segurança antes de qualquer ação destrutiva.

## Fluxo recomendado
```sh
kryonix git-status
kryonix fmt
kryonix check
kryonix diff
kryonix test
kryonix boot   # quando seguro
kryonix switch # quando seguro
```

## Quando usar
Antes de aplicar mudanças em hosts locais ou remotos.

## Comandos relevantes
```sh
kryonix git-status
kryonix fmt
kryonix check
kryonix diff
kryonix test
```

## Riscos
- `boot` e `switch` são destrutivos.
- Alterações de rede/boot exigem plano de rollback.

## Links relacionados
- [CLI Kryonix](CLI-Kryonix)
- [Testes e Validação](Testes-e-Validacao)
- [Segurança](Seguranca)

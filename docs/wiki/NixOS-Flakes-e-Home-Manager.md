# NixOS, Flakes e Home Manager

Status: Implementado (base do projeto)

## Resumo
Kryonix usa Flakes para definir hosts, Home Manager, pacotes e checks em uma única fonte de verdade.

## Outputs do Flake
- `nixosConfigurations`: hosts (`glacier`, `inspiron`, `inspiron-nina`, `iso`).
- `homeConfigurations`: perfis Home Manager por usuário/host.
- `packages`: CLI `kryonix` e ferramentas auxiliares.
- `overlays`, `formatter`, `checks`.

## Fluxo recomendado
```sh
nix flake show --all-systems
nix flake check --keep-going
kryonix check
kryonix home
```

## Quando usar
Para entender como o repo compõe NixOS e Home Manager, e como validar o flake.

## Comandos relevantes
```sh
nix flake show --all-systems
nix flake check --keep-going
kryonix fmt
kryonix check
```

## Riscos
- Atualizar `flake.lock` sem intenção explícita.
- Rodar `switch` sem validar primeiro.

## Links relacionados
- [Arquitetura](Arquitetura)
- [Operações](Operacoes)
- [Testes e Validação](Testes-e-Validacao)

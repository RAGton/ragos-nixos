# Skill: Nix Host Implementation

## Objetivo

Aplicar mudanças de host NixOS respeitando a arquitetura atual do RagOS VE.

## Quando usar

- alteração em `hosts/`, `profiles/`, `features/` ou `modules/`
- ajuste de host existente
- validação de build por host

## Entradas

- host alvo
- objetivo funcional
- restrições operacionais

## Passos

1. confirmar host e camada correta
2. localizar o menor ponto de alteração
3. aplicar patch pequeno
4. validar com `path:$PWD` se a árvore estiver suja
5. registrar decisão ou incidente se a mudança alterar o modo de operar

## Comandos de validação

```bash
nix flake show path:$PWD
nix flake check path:$PWD --keep-going
nix build 'path:$PWD#nixosConfigurations.<host>.config.system.build.toplevel'
nix build 'path:$PWD#homeConfigurations."<user>@<host>".activationPackage'
```

## Critérios de saída

- host certo alterado
- nenhum fluxo destrutivo introduzido
- build do host concluído ou falha antiga separada

## Riscos

- empurrar lógica de feature para dentro do host
- tocar `flake.lock` ou arquivos destrutivos sem necessidade

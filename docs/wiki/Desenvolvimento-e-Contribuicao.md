# Desenvolvimento e Contribuição

Status: Implementado (guidelines)

## Resumo
O desenvolvimento no Kryonix exige mudanças pequenas, validação e documentação honesta. O código do repo é a fonte de verdade.

## Princípios de contribuição
- Mudanças pequenas e auditáveis.
- Não misturar correção funcional com refactor estético.
- Não alterar `flake.lock` sem necessidade explícita.
- Documentação deve refletir o código real.

## Licenciamento
O projeto é **Source Available / Proprietário**. Leia a política de licenciamento antes de redistribuir.

## Quando usar
Ao preparar PRs ou planejar alterações de configuração.

## Comandos relevantes
```sh
nix flake show --all-systems
nix flake check --keep-going
./scripts/doc-audit.sh
kryonix check
```

## Riscos
- Quebrar hosts por mudanças de hardware/boot.
- Commits grandes sem validação.

## Links relacionados
- [Testes e Validação](Testes-e-Validacao)
- [Operações](Operacoes)
- [Segurança](Seguranca)

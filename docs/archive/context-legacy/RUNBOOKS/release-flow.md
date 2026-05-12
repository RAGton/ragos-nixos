# Runbook: Release e Fechamento

## Objetivo

Fechar uma entrega sem vender estado não validado.

## Estrutura recomendada

1. status objetivo
2. hosts e superfícies afetadas
3. comandos de validação executados
4. comportamento validado
5. limitações e riscos restantes
6. separação entre erro antigo e erro novo

## Não fazer

- não tratar plano como implementação
- não esconder falha de build/teste
- não misturar `glacier` com fluxo destrutivo de instalação

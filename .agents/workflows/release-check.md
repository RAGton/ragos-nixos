# Release Check Workflow

## Quando usar
Antes de finalizar qualquer tarefa para garantir que todos os padrões foram respeitados.

## Regras aplicadas
- `.agents/rules/90-definition-of-done.md`

## Entradas
- Conjunto de alterações realizadas.

## Saídas
- Checklist de DoD preenchido.
- Evidências registradas em `docs/TESTING.md`.

## Passos
1. **Revisar:** Conferir se todas as regras de `.agents/rules/` foram seguidas.
2. **Audit:** Rodar auditorias automáticas (docs, nix).
3. **Evidência:** Garantir que capturas de tela, logs ou outputs de teste estão salvos.
4. **Finalizar:** Emitir o relatório final conforme o padrão do projeto.

## Validação obrigatória
- Todos os itens do Definition of Done devem estar marcados.

## Rollback
- Corrigir pendências antes de declarar como pronto.

## Output final esperado
Tarefa entregue com alta qualidade e documentação impecável.

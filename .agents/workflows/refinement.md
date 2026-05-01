# Refinement Workflow

## Quando usar
Este workflow deve ser usado no início de qualquer tarefa para a qual não exista um workflow específico, ou quando a tarefa for complexa e exigir planejamento detalhado.

## Regras aplicadas
- `.agents/rules/00-core.md`
- `.agents/rules/10-documentation.md`

## Entradas
- Solicitação do usuário.
- Contexto atual do repositório.

## Saídas
- Plano de implementação (`implementation_plan.md` ou similar).
- Definição de tarefas em `task.md`.

## Arquivos permitidos
- `.context/ACTIVE_WORK.md`
- `docs/ROADMAP.md`

## Arquivos proibidos
- Alterações diretas em `flake.lock` sem planejamento.
- Alterações em `docs/archive/`.

## Passos
1. **Análise:** Entender o objetivo real da tarefa.
2. **Inventário:** Identificar arquivos afetados.
3. **Plano:** Descrever a abordagem técnica.
4. **Validação do Plano:** Confirmar com o usuário se a abordagem está correta.

## Validação obrigatória
- O plano deve cobrir testes e rollback.

## Rollback
- Descartar o plano e as alterações pendentes.

## Output final esperado
Um plano de ação claro e aprovado.
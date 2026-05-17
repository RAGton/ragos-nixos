# Refinement Workflow

## Quando usar
Este workflow deve ser usado no início de qualquer tarefa complexa para a qual não exista um workflow específico, ou que envolva decisões de arquitetura e ambiguidade técnica.

## Regras aplicadas
- `.agents/rules/00-core.md`
- `.agents/rules/10-documentation.md`

## Entradas
- Solicitação do usuário.
- Contexto atual do repositório (via `.context/CURRENT_STATE.md` e `ACTIVE_WORK.md`).

## Saídas (Artefatos Antigravity)
- **Plano de Implementação:** [implementation_plan.md](file:///home/rocha/.gemini/antigravity/brain/9c417c93-9bfe-468d-9727-582fcd003743/implementation_plan.md) com status de feedback ativado.
- **Lista de Tarefas:** [task.md](file:///home/rocha/.gemini/antigravity/brain/9c417c93-9bfe-468d-9727-582fcd003743/task.md) para acompanhamento dos checklists.
- **Relatório Walkthrough:** [walkthrough.md](file:///home/rocha/.gemini/antigravity/brain/9c417c93-9bfe-468d-9727-582fcd003743/walkthrough.md) detalhando as mudanças e validações concluídas.

## Arquivos permitidos
- `.context/ACTIVE_WORK.md`
- `docs/ROADMAP.md`

## Arquivos proibidos
- Alterações diretas em `flake.lock` sem planejamento.
- Alterações em `docs/archive/`.

## Passos do Ciclo de Planejamento (Planning Mode)
1. **Fase de Pesquisa:** Investigar o código, logs e dependências sem modificar arquivos fontes ou rodar comandos destrutivos.
2. **Fase de Proposta:** Criar ou atualizar o `implementation_plan.md` listando mudanças propostas por componente, validações automatizadas e planos de rollback.
3. **Fase de Aprovação:** Definir `request_feedback = true` e aguardar aprovação explícita por escrito do operador humano.
4. **Fase de Execução:** Criar o `task.md` e marcar progressivamente itens como `[ ]` (pendente), `[/]` (em progresso) e `[x]` (completo) à medida que implementa.
5. **Fase de Verificação:** Rodar testes e gerar o `walkthrough.md` com evidências (comandos e capturas/gravações se aplicável).

## Validação obrigatória
- O plano deve cobrir testes automatizados (ex: nix builds, benchmarks) e manuais.
- O plano deve documentar detalhadamente o impacto nos privilégios e segurança de segredos.

## Rollback
- Em caso de falha durante a execução ou rejeição do plano, desfazer as alterações de working tree (`git restore`) e retornar ao baseline anterior.

## Output final esperado
Uma entrega funcional completa, validada e documentada seguindo o ciclo de governança do Antigravity.
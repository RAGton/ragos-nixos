# Agent Workflows

Este diretório contém os playbooks operacionais para tarefas comuns no Kryonix.

## Workflows Disponíveis
- **refinement.md:** Refinamento de tarefas e planejamento inicial.
- **docs-audit.md:** Auditoria de documentação e conformidade.
- **nixos-change.md:** Procedimento para alterações em módulos e hosts NixOS.
- **runtime-doctor.md:** Diagnóstico de saúde do sistema em tempo real.
- **brain-rag-change.md:** Alterações no sistema de IA/Brain/RAG.
- **release-check.md:** Verificação final antes de uma entrega ou merge.

## Estrutura de um Workflow
Cada workflow deve conter:
1. Quando usar
2. Regras aplicadas (de `.agents/rules/`)
3. Passos detalhados
4. Validação obrigatória
5. Plano de rollback

# Agent System Inventory

Este documento cataloga todos os arquivos relacionados a agentes, contexto e governança no repositório Kryonix.

| Caminho | Camada | Propósito | Consumidor | Status | Risco | Ação Recomendada |
|---------|--------|-----------|------------|--------|-------|------------------|
| `.vscode/settings.json` | IDE | Configurações do editor | Desenvolvedor/Agente | keep | Baixo | Manter |
| `ai/kryonix-vault/` | Vault | Cérebro técnico (Obsidian) | Agente/Humano | keep | Médio | Manter como fonte de conhecimento |
| `ai/prompts/` | Prompts | Prompts experimentais | Agente | refactor | Baixo | Padronizar e mover para .agents se estável |
| `ai/skills/` | Skills | Habilidades específicas | Agente | refactor | Médio | Integrar com .agents/workflows |
| `ai/templates/` | Templates | Modelos de arquivos | Agente/Humano | keep | Baixo | Manter |
| `docs/agents/agente-update.md` | Docs | Atualização de agentes | Agente | refactor | Baixo | Integrar na nova arquitetura |
| `docs/agents/README.md` | Docs | Guia de agentes | Humano/Agente | refactor | Baixo | Atualizar para nova arquitetura |
| `docs/ai/AI_USAGE_POLICY.md` | Docs | Política de uso de IA | Humano | keep | Baixo | Manter |
| `docs/ai/ARCHITECTURE_SUMMARY.md` | Docs | Resumo da arquitetura | Humano/Agente | keep | Médio | Manter |
| `docs/ai/BRAIN_SERVER_ARCHITECTURE.md` | Docs | Arquitetura do Brain Server | Humano/Agente | keep | Médio | Manter |
| `docs/ai/CODE_TASTE.md` | Docs | Preferências de código | Agente | keep | Baixo | Manter |
| `docs/ai/DESIGN_PREFERENCES.md` | Docs | Preferências de design | Agente | keep | Baixo | Manter |
| `docs/ai/DISTRIBUTED_BRAIN_SERVER.md` | Docs | Brain Server Distribuído | Humano/Agente | keep | Médio | Manter |
| `docs/ai/FOLDER_STRUCTURE.md` | Docs | Estrutura de pastas | Humano/Agente | keep | Baixo | Manter |
| `docs/ai/OBSIDIAN_CLI_POLICY.md` | Docs | Política da CLI Obsidian | Humano/Agente | keep | Médio | Manter |
| `docs/ai/OBSIDIAN_CLI_SAFE_COMMANDS.md` | Docs | Comandos seguros Obsidian | Humano/Agente | keep | Médio | Manter |
| `docs/ai/PROJECT_CONTEXT.md` | Docs | Contexto do projeto | Agente | keep | Baixo | Manter |
| `docs/ai/PROJECT_INDEX.md` | Docs | Índice do projeto | Agente | keep | Baixo | Manter |
| `docs/ai/PROMPT_USE_OBSIDIAN_BRAIN.md` | Docs | Prompt para uso do Brain | Agente | keep | Baixo | Manter |
| `docs/ai/RISK_AREAS.md` | Docs | Áreas de risco | Agente | keep | Médio | Manter |
| `docs/ai/STABILIZATION_REPORT.md` | Docs | Relatório de estabilização | Humano | keep | Baixo | Manter |
| `docs/ai/TECHNICAL_PLAYBOOK.md` | Docs | Playbook técnico | Agente | keep | Médio | Manter |
| `docs/ai/VAULT_ACCESS_REQUEST.md` | Docs | Requisição de acesso ao vault | Humano/Agente | keep | Baixo | Manter |
| `docs/ai/VAULT_UPDATE_PROPOSAL.md` | Docs | Proposta de update do vault | Humano/Agente | keep | Baixo | Manter |
| `docs/ARCHITECTURE.md` | Docs | Arquitetura geral | Humano/Agente | keep | Alto | Manter |
| `docs/archive/` | Arquivo | Histórico preservado | Humano | keep | Baixo | Manter como referência histórica |
| `docs/brain/` | Docs | Documentação do Brain | Humano/Agente | keep | Médio | Manter |
| `docs/CURRENT_STATE.md` | Docs | Estado atual | Humano/Agente | keep | Médio | Manter |
| `docs/evidence/` | Docs | Evidências de testes | Humano/Agente | keep | Baixo | Manter |
| `docs/GLACIER.md` | Docs | Documentação Glacier | Humano/Agente | keep | Alto | Manter |
| `docs/hosts/` | Docs | Documentação de hosts | Humano/Agente | keep | Médio | Manter |
| `docs/INSTALL.md` | Docs | Guia de instalação | Humano | keep | Alto | Manter |
| `docs/mcp/` | Docs | Documentação MCP | Humano/Agente | keep | Médio | Manter |
| `docs/OPERATIONS.md` | Docs | Operações | Humano/Agente | keep | Médio | Manter |
| `docs/README.md` | Docs | README principal | Humano/Agente | keep | Baixo | Manter |
| `docs/ROADMAP.md` | Docs | Roadmap do projeto | Humano/Agente | keep | Baixo | Manter |
| `docs/SECURITY.md` | Docs | Segurança | Humano/Agente | keep | Alto | Manter |
| `docs/TESTING.md` | Docs | Testes | Humano/Agente | keep | Médio | Manter |
| `docs/TROUBLESHOOTING.md` | Docs | Troubleshooting | Humano/Agente | keep | Médio | Manter |
| `docs/USAGE.md` | Docs | Guia de uso | Humano/Agente | keep | Médio | Manter |

## Próximos Passos
- Criar `.agents/rules/` para centralizar políticas.
- Criar `.agents/workflows/` para procedimentos operacionais.
- Criar `.context/` para estado operacional volátil.
- Integrar com `AGENTS.md`.

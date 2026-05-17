# Kryonix Agent Index

Este arquivo cataloga todos os subagentes especializados da equipe **Gemini/Antigravity** no repositório **Kryonix**. Use esta tabela para direcionar a execução de tarefas para o agente correto com base no escopo e objetivo da alteração.

---

## Equipe de Agentes Especializados

| Nome do Agente | Função / Missão | Escopo de Edição | Permissões | Foco Operacional |
| :--- | :--- | :--- | :--- | :--- |
| [kora-mind-constructor](file:///etc/kryonix/.agents/roles/kora-mind-constructor.md) | Cérebro LLM & Diálogo Natural | `packages/kora/kora/core/`, `mind/`, `llm/` | **Implementação** | Router, Orchestrator, Persona e Dialogue Policies |
| [kora-voice-stabilizer](file:///etc/kryonix/.agents/roles/kora-voice-stabilizer.md) | Estabilização de Áudio & Pipeline | `packages/kora/kora/voice/`, CLI | **Implementação** | VAD, STT, TTS, openWakeWord, microfone e systemd |
| [kora-security-warden](file:///etc/kryonix/.agents/roles/kora-security-warden.md) | Auditoria de Segurança & Secrets | NENHUM (Auditor independente) | **READ-ONLY** | Policy Engine, Secrets, Trust Boundary, Permissões e Sudo |
| [kryonix-nixos-integrator](file:///etc/kryonix/.agents/roles/kryonix-nixos-integrator.md) | Integração NixOS & HM Declarativa | `flake.nix`, `hosts/`, `modules/nixos/` | **Implementação** | Módulos Nix, builds, systemd system units e switch seguro |
| [kora-memory-rag-engineer](file:///etc/kryonix/.agents/roles/kora-memory-rag-engineer.md) | Engenharia de Memória & RAG | `packages/kora/kora/memory/`, `learning/` | **Implementação** | Obsidian Vault, LightRAG, Neo4j, e indexação incremental |
| [kora-quality-benchmark-engineer](file:///etc/kryonix/.agents/roles/kora-quality-benchmark-engineer.md) | Benchmarks & Qualidade de Resposta | `packages/kora/kora/eval/`, `core/quality.py`| **Implementação** | Testes de regressão, qualidade conversacional e latência |
| [kora-local-llm-training-engineer](file:///etc/kryonix/.agents/roles/kora-local-llm-training-engineer.md) | Treinamento Local & Fine-Tuning | `packages/kora/kora/training/` | **Implementação** | Feedback loops, exportação de datasets SFT/DPO e LoRA |
| [kora-ux-cli-designer](file:///etc/kryonix/.agents/roles/kora-ux-cli-designer.md) | Design de Interface & Experiência CLI | CLI, UI/UX, shell scripts | **Implementação** | Animações rich, Waybar JSON, spinners, logs amigáveis |
| [kora-n8n-automation-engineer](file:///etc/kryonix/.agents/roles/kora-n8n-automation-engineer.md) | Automações Locais & Workflows n8n | `packages/kora/kora/integrations/n8n.py` | **Implementação** | Webhooks locais, Action Proposals e verificação de rede |

---

## Como Operar com a Equipe

1. **Intake da Tarefa**: Leia a descrição e determine qual componente do ecossistema Kryonix/Kora será afetado.
2. **Orquestração**: Siga o fluxo definido no [Workflow de Orquestração de Agentes](file:///etc/kryonix/.agents/workflows/kora-agent-orchestration.md).
3. **Checklists de Qualidade**: Certifique-se de que os gates de validação obrigatórios listados no diretório [checklists/](file:///etc/kryonix/.agents/checklists/) sejam executados antes de declarar uma alteração como pronta.

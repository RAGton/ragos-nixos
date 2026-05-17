# Agente: Kora Mind Constructor

## Missão
Transformar a Kora em uma assistente LLM-centered, natural, contextual e altamente útil, com diálogo fluido e contínuo.

---

## Escopo
- Arquitetura cognitiva conversacional da Kora (`packages/kora/kora/mind/`).
- Fluxo de orquestração central e roteamento semântico (`orchestrator.py` e `router.py`).
- Definição da Persona da Kora e prompt de sistema (`system_prompt.md`).
- Estruturação do contexto multi-sessão e limites de tokens para conversas.
- Políticas de Diálogo (`dialogue_policy.py`) e camada de reflexão cognitiva (`reflection.py`).
- Prevenção de respostas genéricas e redundâncias no diálogo diário.

---

## Restrições Operacionais de Arquivos

### Arquivos que deve ler:
- [orchestrator.py](file:///etc/kryonix/packages/kora/kora/core/orchestrator.py)
- [router.py](file:///etc/kryonix/packages/kora/kora/core/router.py)
- [conversation.py](file:///etc/kryonix/packages/kora/kora/core/conversation.py)
- [quality.py](file:///etc/kryonix/packages/kora/kora/core/quality.py)
- [system_prompt.md](file:///etc/kryonix/packages/kora/kora/llm/system_prompt.md)
- [KORA_JARVIS_BLUEPRINT.md](file:///etc/kryonix/docs/kora/architecture/KORA_JARVIS_BLUEPRINT.md)

### Arquivos que pode alterar:
- Caminhos sob [core/](file:///etc/kryonix/packages/kora/kora/core/)
- Caminhos sob [mind/](file:///etc/kryonix/packages/kora/kora/mind/) (Novo pacote de cérebro cognitivo)
- [system_prompt.md](file:///etc/kryonix/packages/kora/kora/llm/system_prompt.md)
- [eval/](file:///etc/kryonix/packages/kora/kora/eval/)
- [docs/kora/](file:///etc/kryonix/docs/kora/)

### Arquivos proibidos (NUNCA acessar ou alterar):
- Secrets de ambiente e arquivos `.env` em `/etc/kryonix/*.env`
- Arquivos de configuração de MCP (`.mcp.json` real com credenciais de produção)
- Credenciais ou chaves privadas SSH/GPG

---

## Riscos Identificados
- **Alucinação Conversacional**: O modelo pode gerar comandos fictícios ou assumir que componentes do Kryonix existem quando estão apenas no Roadmap.
- **Respostas Secas e Robóticas**: Ignorar a intenção de conversas informais (como "você está me ouvindo?") e cuspir relatórios técnicos complexos.
- **Vazamento de Tokens**: Contextos históricos de conversas acumulados incorretamente podem exceder a janela de contexto permitida ou estourar a memória local da GPU do Glacier.

---

## Validações Obrigatórias
Antes de declarar concluído:
1. **Compilação**: O código Python do core do Kora deve compilar perfeitamente.
   ```bash
   python -m compileall packages/kora
   ```
2. **Nix Derivation**: O pacote Nix da Kora deve construir sem falhas na sandbox local.
   ```bash
   nix build .#kora --no-link -L --show-trace
   ```
3. **Benchmarks Conversacionais**: Executar e passar em 100% dos testes de regressão de qualidade.
   ```bash
   kora benchmark quality
   ```
4. **Conversação Casual**: Validar se perguntas casuais são respondidas de forma humana e natural, sem expor metadados internos desnecessários.
   ```bash
   kora ask "bom então você está me ouvindo agora né"
   kora ask "faz um pentifino na kora ela n ta entendendo"
   ```

---

## Definition of Done (DoD)
- A Kora responde naturalmente como uma parceira humana (tom minimalista, calmo e técnico).
- O roteamento conversacional intercepta interações informais e contorna respostas secas de status interno de hardware.
- A Kora compreende e responde a perguntas complexas de múltiplas partes em uma única sessão.
- O contexto histórico da conversa é limpo, limitado a um máximo de 6 turnos para evitar poluição.
- Nenhuma chave API real ou segredo do ecossistema é exposto nos prompts ou nas respostas.

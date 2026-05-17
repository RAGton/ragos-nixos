# Agente: Kora Memory & RAG Engineer

## Missão
Evoluir a arquitetura de memória contínua, sincronização de conhecimento, recuperação contextual (RAG) e integração semântica com Obsidian Vault, Neo4j GraphRAG e LightRAG, garantindo a integridade dos dados e busca de baixa latência.

---

## Escopo
- Arquitetura de persistência e fila de indexação da Kora (`packages/kora/kora/memory/`).
- Engine de aprendizado e vocabulário personalizado do operador (`packages/kora/kora/learning/`).
- Integração da Kora API com o Kryonix Brain no Glacier (`packages/kora/kora/integrations/brain.py`).
- Sincronização e ingestão incremental de Markdown notas do Obsidian.
- Otimização de consultas híbridas (Naive + Local + Global + Hybrid) de LightRAG e Neo4j.

---

## Restrições Operacionais de Arquivos

### Arquivos que deve ler:
- [memory/](file:///etc/kryonix/packages/kora/kora/memory/) (Módulos de indexação, worker, obsidian e search)
- [learning/](file:///etc/kryonix/packages/kora/kora/learning/) (Módulo de preferências de aprendizagem)
- [brain.py](file:///etc/kryonix/packages/kora/kora/integrations/brain.py)
- [docs/kora/](file:///etc/kryonix/docs/kora/)
- [kryonix-brain-lightrag/](file:///etc/kryonix/packages/kryonix-brain-lightrag/)

### Arquivos que pode alterar:
- Caminhos sob [memory/](file:///etc/kryonix/packages/kora/kora/memory/)
- Caminhos sob [learning/](file:///etc/kryonix/packages/kora/kora/learning/) (Novo pacote de aprendizagem contínua)
- [brain.py](file:///etc/kryonix/packages/kora/kora/integrations/brain.py)
- Documentações operacionais de RAG e Memória em `docs/kora/`

### Arquivos proibidos:
- Arquivos de configuração física ou logs brutos do servidor Neo4j em Glacier.
- Chaves API ou arquivos secretos de ambiente.

---

## Riscos Identificados
- **Corrupção de Índices do RAG**: Alterações concorrentes ou interrupções abruptas do worker de indexação que quebrem os arquivos pickle ou sqlite do LightRAG.
- **Vazamento de Dados Pessoais**: Ingerir metadados técnicos ou senhas inseridas acidentalmente em notas de rascunho do Obsidian.
- **Latência Elevada de Resposta**: Consultas globais pesadas no Neo4j ou buscas de RAG que demorem mais de 5.0 segundos por interação em rede.

---

## Validações Obrigatórias
Antes de declarar concluído:
1. **Status da Memória**: Verificar se a fila de indexação local e o worker de processamento em segundo plano estão operacionais.
   ```bash
   kora memory status
   ```
2. **Evidência de Busca Híbrida**: Validar a busca semântica local com termos técnicos do repositório Kryonix.
   ```bash
   kora memory search "Kryonix"
   ```
3. **Validação do Fluxo de Gravação**: Confirmar a limpeza da fila sem perda de dados.
   ```bash
   kora memory flush
   ```
4. **Teste de Recuperação Conversacional**: Perguntar à Kora algo indexado e validar se ela responde citando a fonte correta.
   ```bash
   kora ask "você lembra o que eu falei sobre Kryonix?"
   ```

---

## Definition of Done (DoD)
- O pipeline de memória curta e longa (Obsidian -> Fila -> RAG -> Grafo) funciona de forma assíncrona, robusta e idempotente.
- A Kora realiza buscas RAG no Glacier utilizando a `KRYONIX_BRAIN_API_KEY` canônica e de forma segura.
- O engine de aprendizagem e correções ortográficas (`LearningEngine`) aplica correções fonéticas na CLI em tempo real.
- Ingestão de novos conhecimentos no Obsidian passa por um filtro sanitário automático (zero secrets ou dados sensíveis permitidos).
- O tempo total de busca semântica e montagem de prompt contextual não excede 1.5s por requisição.

# Framework Leda — Arquitetura e Engenharia de Agentes Autônomos

Status: Material de conhecimento / Referência arquitetural

## Finalidade

Este documento consolida aprendizados sobre arquitetura de agentes autônomos, automações, bancos de dados, orquestração com Make/n8n, engenharia de prompts, APIs, canais sociais e verticais de negócio.

Este conteúdo deve ser usado pelo Kryonix Brain como fonte de conhecimento para projetar agentes, workflows e integrações futuras.

Este documento não representa o estado runtime atual do Glacier.

---

## Princípios de Arquitetura de Automação

O Framework Leda foca em projetar e implementar sistemas onde agentes inteligentes não apenas respondem a consultas, mas também tomam decisões operacionais em workflows complexos de negócio e automação:

1. **Desacoplamento e Resiliência:** Agentes de automação devem interagir por meio de filas e interfaces padronizadas (ex.: Webhooks, REST, JSON-RPC) para evitar gargalos ou falhas em cadeia.
2. **Orquestração Orientada a Eventos:** O uso de ferramentas como n8n e Make permite conectar gatilhos de sistemas reais (e-mails, mensagens instantâneas, webhooks) ao raciocínio lógico dos LLMs e sistemas.
3. **Engenharia de Prompts Estruturada:** Todas as saídas destinadas a sistemas e automações devem seguir esquemas rígidos (especialmente formatos JSON bem definidos) para garantir previsibilidade na análise e execução das etapas.

---

## Aplicação no Kryonix

O Framework Leda pode influenciar o Kryonix nas seguintes áreas:

- agentes verticais especializados;
- workflows com n8n/Make;
- ingestão de dados externos;
- integração com WhatsApp/Evolution API;
- prompts estruturados com JSON;
- automações orientadas por estado;
- uso de bancos relacionais/vetoriais;
- classificação de leads, tarefas, incidentes e documentos.

No Kryonix, essas ideias devem ser adaptadas com:

- NixOS declarativo;
- serviços systemd;
- segredos fora do Git;
- validação por comandos;
- logs auditáveis;
- RAG/GraphRAG com grounding;
- separação entre estado real e roadmap.

## O que não fazer

Não misture esse conteúdo com:

- `docs/brain/WALKTHROUGH_CURRENT_STATE.md`
- `docs/brain/STATE_LAYOUT.md`
- `docs/operations/API_KEY_ROTATION.md`

Porque o RAG pode confundir arquitetura de negócio/agentes com estado operacional real do Glacier.

## Veredito

O conteúdo está valioso para o Kryonix, principalmente para a futura camada de agentes autônomos + automação + workflows, mas ele deve ser tratado como material de conhecimento, não como documentação operacional. Para a parte GraphRAG/Neo4j, mantenha separado: embeddings acham similaridade; grafos explicam relações, causalidade e contexto.

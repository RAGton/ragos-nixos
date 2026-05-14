# Kryonix Brain — Central de Conhecimento e IA

O **Kryonix Brain** é a central de processamento e inteligência artificial local do projeto, projetada para unificar o conhecimento técnico do repositório, as anotações pessoais do operador e as ferramentas operacionais em uma interface comum para agentes inteligentes e humanos.

Ele orquestra a inteligência local integrando:
- **LightRAG**: Motor de recuperação aumentada por geração baseado em grafos (GraphRAG).
- **MCP (Model Context Protocol)**: Exposição de ferramentas de sistema, diagnóstico e consultas ao grafo.
- **Vault (Obsidian)**: A base estruturada de conhecimento, notas diárias e playbooks técnicos.
- **Ollama**: Motor local de execução de LLMs e Embeddings na GPU.

---

## 🌐 Topologia Cliente-Servidor

A infraestrutura de IA do Kryonix é distribuída de maneira declarativa e resiliente entre os hosts da rede:

```txt
┌─────────────────────────────────┐           ┌──────────────────────────────────┐
│        INSPIRON (Cliente)       │           │         GLACIER (Servidor)       │
├─────────────────────────────────┤           ├──────────────────────────────────┤
│ - CLI 'kryonix brain ...'       │   LAN     │ - Ollama Engine (Port 11434)     │
│ - MCP Client (Antigravity/etc)  │ ────────> │ - Vector DB (NanoVectorDB)       │
│ - Config remota de API          │ Tailscale │ - Storage GraphML / RAG          │
│ - Operação de UX/Desktop leve   │           │ - Obsidian Technical Vault       │
└─────────────────────────────────┘           └──────────────────────────────────┘
```

- **Glacier (Server IA):** Hospeda e executa os serviços pesados (GPU NVIDIA RTX 4060, Ollama, armazenamento GraphML, banco vetorial local e backups).
- **Inspiron (Client Workstation):** Executa comandos leves. Realiza requisições remotas para o Glacier via HTTP ou túnel SSH usando a CLI `kryonix` conectada ao endpoint configurado pela variável `KRYONIX_BRAIN_API`.
- *Resiliência:* Falhas de conexão ou indisponibilidade do Glacier no host cliente são tratadas como avisos (`WARN`), nunca quebrando builds ou o provisionamento do sistema.

---

## 🛠️ Componentes Ativos (Produção Core V1)

Estes componentes representam as funcionalidades implementadas, validadas e atualmente operacionais no repositório:

- 📑 **[Pipeline RAG Atual (V1)](kryonix-rag-pipeline.md):** Fluxo real de ingestão, geração de embeddings, persistência em GraphML local, recuperação híbrida e síntese via Ollama local.
- ☊ **[LightRAG (GraphRAG Engine)](lightrag.md):** Especificação do motor primário de GraphRAG do projeto, com comandos CLI de gerenciamento local de grafos (`stats`, `top`, `heal`, `repair`).
- 🔌 **[Kryonix Brain MCP Server](mcp.md):** Protocolo de segurança e ferramentas JSON-RPC expostas a agentes (consultas ao grafo, busca no Obsidian, e envio de propostas de aprendizagem seguras).
- 🗃️ **[Vault Obsidian (Rules & Enforcement)](vault.md):** Políticas de acesso seguro para agentes (Obsidian CLI Brain Enforcement), saúde de indexação e hierarquias de notas canônicas.
- 🤖 **[Safe Autopilot](AUTOPILOT.md):** Loop autônomo seguro de curadoria, observação e simulação contínua para governança de Graph, RAG, CAG e LightRAG.

---

## 🚀 Planejamento & Propostas de Arquitetura (Roadmap)

Estes documentos representam blueprints arquiteturais planejados para futuras iterações. **Não devem ser interpretados pelo RAG/agentes como funcionalidades prontas ou implementadas no código atual:**

- 🗺️ **[RAG Avançado (Target Pipeline)](RAG_ARCHITECTURE.md):** Proposta para enriquecer a recuperação com normalização e roteamento de queries, metadados, reranking e compressão de contexto.
- 💾 **[CAG / Context Cache](CAG_ARCHITECTURE.md):** Planejamento para cache persistente de contextos estáticos frequentes do repositório (flake, serviços, políticas) para otimização de latência.
- 🕸️ **[GraphRAG Multicamadas](GRAPH_RAG_ARCHITECTURE.md):** Ontologia e schema conceitual avançado para modelar dependências do NixOS, portas, hosts e vestígios de raciocínio.
- 📐 **[Schema Mínimo Neo4j](NEO4J_SCHEMA.md):** Definição formal de nós, propriedades, constraints de unicidade e exemplos práticos de consultas Cypher de infraestrutura para o GraphRAG.
- 📥 **[Pipeline de Ingestão Expandido](INGESTION_PIPELINE.md):** Estratégia declarativa para ingestão profunda do repositório, chunking inteligente de código `.nix` e manifestos de hash incremental.
- 🔗 **[Obsidian + Neo4j Model](OBSIDIAN_NEO4J_MODEL.md):** Modelo de transição para conectar o Obsidian ao Neo4j, permitindo consultas Cypher multi-hop seguras de forma derivada e reconstruível.
- 🧠 **[Reasoning Memory (Traces)](REASONING_MEMORY.md):** Grafo de vestígios e auditoria para persistir decisões tomadas pela IA durante as sessões de resolução de problemas.
- 📂 **[Layout de Estado do Servidor](STATE_LAYOUT.md):** Padronização e diretrizes de governança para a estrutura do diretório `/var/lib/kryonix/` no Glacier.

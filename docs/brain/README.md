# Kryonix Brain

O **Kryonix Brain** é a central de processamento e conhecimento de IA do projeto.

Ele orquestra a inteligência local, unificando:
- **LightRAG**: Estrutura de Retrievial-Augmented Generation baseada em grafos.
- **MCP (Model Context Protocol)**: Exposição segura de ferramentas de sistema, conhecimento e contexto.
- **Vault (Obsidian)**: A base real de conhecimento e anotações.
- **Ollama**: Motor local de LLMs.

## Topologia Cliente-Servidor

A arquitetura do projeto é distribuída.
O **Glacier** roda o ambiente "pesado": Ollama, armazenamento LightRAG, grafos (GraphML) e vector DB.
O **Inspiron** (cliente) realiza requisições remotas (via HTTP ou SSH) sem sobrecarregar sua própria máquina com infraestrutura de IA, usando os binários da CLI `kryonix` conectada à variável `KRYONIX_BRAIN_API`.

## Componentes
- [LightRAG](lightrag.md)
- [MCP (Model Context Protocol)](mcp.md)
- [Vault (Obsidian)](vault.md)

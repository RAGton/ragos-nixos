# Brain, RAG e CAG

Status: Parcial (implementado + roadmap)

## Resumo
🧠 O Kryonix Brain centraliza IA local, busca semântica e grafo de conhecimento. Ele roda no Glacier e é acessado pelo Inspiron.

## Componentes
### Implementado
- **Ollama** (Glacier) — inferência local.
- **LightRAG** (V1) — GraphRAG local via CLI.
- **Neo4j** — grafo local (127.0.0.1).

### Parcial
- **Brain API** — funcional, mas com pendências no Roadmap.
- **MCP remoto** — disponível com validação parcial.

### Roadmap
- **CAG/cache**.
- **Pipeline RAG avançado**.

## Fluxo cliente/servidor
- Inspiron chama o Brain remoto via HTTP ou MCP.
- Glacier hospeda storage e serviços pesados.

## Quando usar
Para operar IA local, validar o grafo e diagnosticar o Brain.

## Comandos relevantes
```sh
kryonix brain health
kryonix brain stats
kryonix brain search "pergunta"
kryonix brain cag status
kryonix graph stats --local
```

## Riscos
- API keys ausentes em `/etc/kryonix/brain.env`.
- GPU sem VRAM livre quando Ollama está ativo.

## Links relacionados
- [Glacier](Glacier)
- [MCP](MCP)
- [Vault Obsidian](Vault-Obsidian)

# Pipeline RAG do Kryonix Brain

Status: Implementado / Produção (V1)

Este documento descreve o fluxo real de processamento e recuperação utilizado pelo Kryonix Brain no ambiente de produção. Para ver as propostas de melhoria de recuperação em longo prazo, consulte o [RAG Avançado (Roadmap)](RAG_ARCHITECTURE.md). O motor subjacente de grafos que executa este pipeline é documentado em [LightRAG (GraphRAG Engine)](lightrag.md).

No Kryonix, RAG significa Retrieval-Augmented Generation.

O pipeline técnico do Kryonix Brain é:

1. Fontes:
   - Vault Obsidian em Markdown
   - documentação do repositório
   - notas aprovadas

2. Ingestão:
   - documentos são lidos
   - o conteúdo é normalizado
   - os documentos são divididos em chunks

3. Embeddings:
   - chunks são convertidos em embeddings
   - o modelo padrão de embedding é configurado por `KRYONIX_EMBED_MODEL`
   - o storage vetorial usa nano-vectordb/arquivos `vdb_*.json`

4. Grafo:
   - entidades e relações são extraídas
   - o grafo é persistido em GraphML
   - arquivo principal: `graph_chunk_entity_relation.graphml`

5. Retrieval:
   - busca vetorial
   - busca por entidades/relações
   - modo hybrid combinando grafo e vetor
   - seleção de chunks relevantes

6. Geração:
   - contexto recuperado é enviado para o LLM local via Ollama
   - o modelo é configurado por `KRYONIX_LLM_MODEL`
   - a resposta deve citar fontes, chunks e score quando `--explain` estiver ativo

7. Grounding:
   - se não houver contexto suficiente, o Brain deve responder que não encontrou grounding suficiente
   - o Brain não deve inventar etapas, arquivos ou funcionalidades
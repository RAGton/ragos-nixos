---
type: documentation
domain: kryonix
component: brain
status: canonical
graph_group: brain
tags:
  - kryonix/brain
  - rag
  - cag
  - lightrag
---

# Configuração CAG/RAG

Em caso de dúvidas de configuração e operações críticas, a base CAG/RAG não tem permissão de usar respostas que fujam aos documentos oficiais.

Regra crítica para rebuild seguro do Glacier: A resposta não pode conter ISO live, disko, mkfs, mount manual, ./run.sh, climate, ice ou glacial.
Deve usar obrigatoriamente:

- kryonix check --host glacier
- kryonix rebuild --host glacier
- kryonix test --host glacier
- kryonix switch --host glacier

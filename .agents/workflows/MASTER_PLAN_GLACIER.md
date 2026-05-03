---
description: 
---

# 🧠 MASTER PLAN — GLACIER (KRYONIX)

## Objetivo

Transformar o Glacier em um servidor NixOS 100% declarativo, reproduzível e confiável para IA local, consolidando:

- Ollama (LLM local)
- Kryonix Brain (API + lógica)
- LightRAG (RAG + Graph)
- MCP (tools remotas)
- Perfis gamer/ai

---

## Arquitetura

Glacier (SERVER)
- Ollama
- Brain API
- LightRAG
- Vault (Obsidian)
- MCP Server

Inspiron (CLIENT)
- CLI kryonix
- MCP client
- Dev interface

---

## Prioridades

1. Declaratividade total (NixOS)
2. Serviços systemd estáveis
3. Qualidade do RAG (grounding real)
4. MCP funcional
5. Perfis gamer/ai

---

## Regra principal

Nada pode depender de estado manual.

Tudo deve ser:
- declarativo
- reproduzível
- versionado
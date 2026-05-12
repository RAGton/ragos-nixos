---
trigger: always_on
---

# ⚠️ REGRAS DO AGENTE

## Antes de qualquer ação

- Ler TODOS os arquivos em `.ai/*`
- Fazer diagnóstico completo
- NÃO assumir estado

---

## Proibições

- ❌ Não quebrar flake
- ❌ Não rodar rebuild sem necessidade
- ❌ Não reindexar LightRAG sem motivo
- ❌ Não iniciar Ollama automaticamente
- ❌ Não exceder VRAM da GPU
- ❌ Não gerar respostas sem grounding

---

## Obrigações

- ✔ Sempre validar antes de concluir
- ✔ Usar systemd para serviços
- ✔ Usar NixOS sempre que possível
- ✔ Garantir logs limpos
- ✔ Garantir idempotência

---

## RAG

- Deve usar dados reais
- Deve citar fontes quando possível
- Não pode inventar conteúdo

---

## MCP

- JSON-RPC limpo
- stdout sem logs
- tools funcionais
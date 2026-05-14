# Brain Ask/Search Contract

Este documento define o contrato operacional entre as intenções `ask` e `search` no Kryonix Brain.

## Visão Geral

A arquitetura do Kryonix Brain separa a **recuperação de evidências** da **síntese narrativa**. Isso permite otimizar a latência para buscas rápidas e garantir o grounding para respostas complexas.

| Característica | `search` | `ask` |
| :--- | :--- | :--- |
| **Objetivo** | Localizar evidências e fontes. | Responder com base em evidências. |
| **Geração LLM** | **SKIPPED** (Não utiliza LLM). | **ATIVADA** (Utiliza LLM/Provider). |
| **Latência Alvo** | < 2s (Recuperação pura). | 10s - 30s (Sintese + Recuperação). |
| **Saída CLI** | Painel de Evidências (Ciano). | Painel de Resposta (Magenta). |
| **Fontes (Limit)** | Top 10 evidências. | Top 5 fontes principais. |

---

## Intenção: `search`

Utilizada para descobrir *onde* uma informação está sem o custo de processamento de um LLM.

### Fluxo Técnico
1. **Normalização**: Limpeza e correção de typos na query.
2. **Recuperação**: Consulta aos índices LightRAG (Entidades, Relações, Chunks).
3. **Grounding**: Cálculo de scores e ranking de relevância.
4. **Retorno**: Devolve os chunks e fontes localizados imediatamente.

### Metadados
- `generation_skipped: true`
- `provider_used: null`

---

## Intenção: `ask`

Utilizada para obter uma resposta direta e fundamentada sobre um tema.

### Fluxo Técnico
1. **Normalização**: Limpeza e correção de typos na query.
2. **Recuperação**: Localização de evidências relevantes.
3. **Síntese**: Envio do contexto recuperado para o LLM (`llama.cpp` ou fallback `Ollama`).
4. **Anti-alucinação**: Validação da resposta contra o contexto recuperado.

### Metadados
- `generation_skipped: false`
- `provider_used`: Nome do backend que gerou a resposta.
- `tps`: Tokens per second da geração.

---

## Troubleshooting

### "Search retornou resposta curta"
Este é o comportamento esperado. O `search` não deve gerar parágrafos explicativos. Se você deseja uma explicação, use `kryonix brain ask`.

### "Ask está lento"
Verifique o `provider_used` no `--explain`. Se estiver usando `Ollama`, a latência pode ser maior que no `llama.cpp` se a GPU não estiver otimizada para o modelo específico.

---

## Próximas Evoluções
- **Issue #39**: Auditoria de contradições no grafo.
- **Issue #40**: Expansão semântica de queries em modo `search`.

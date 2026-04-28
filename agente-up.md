O sistema Kryonix Brain já está estável, com RAG funcional, grounding ativo e testes passando.

Agora o objetivo NÃO é corrigir bugs.
O objetivo é EVOLUIR o sistema para nível avançado:

- melhor qualidade de respostas
- melhor uso do grafo
- melhor conteúdo no vault
- maior confiabilidade técnica

---

# OBJETIVOS PRINCIPAIS

1. Melhorar qualidade do RAG (inteligência)
2. Melhorar qualidade do conteúdo do vault
3. Reduzir respostas genéricas
4. Aumentar precisão técnica
5. Aumentar utilidade prática

---

# PARTE 1 — EVOLUIR O RAG (INTELIGÊNCIA)

## 1. Ranking de chunks (CRÍTICO)

Hoje:
- chunks são truncados por quantidade

Implementar ranking baseado em:

- similaridade semântica (embedding score)
- proximidade no grafo (grau de conexão)
- frequência de referência
- tipo (entity vs relation vs chunk)

Resultado:
- chunks mais relevantes primeiro
- menos ruído

---

## 2. Multi-hop reasoning no grafo

Hoje:
- busca direta

Melhorar:

- expandir entidades relacionadas (1 ou 2 hops)
- incluir relações importantes no contexto
- evitar loops e expansão infinita

Exemplo:
Hyprland → Wayland → compositor → config NixOS

---

## 3. Query planner (decidir estratégia)

Implementar lógica:

- query técnica → priorizar chunks
- query conceitual → priorizar grafo
- query ambígua → híbrido

---

## 4. RAG híbrido inteligente

Pipeline ideal:

1. graph search
2. entity expansion
3. chunk retrieval
4. vector fallback
5. ranking final

---

## 5. Melhorar logs

Adicionar:

[DEBUG] ranking scores
[DEBUG] chunk source (entity/relation/vector)
[DEBUG] graph hops utilizados

---

# PARTE 2 — MELHORAR O CONTEÚDO DO VAULT (CRÍTICO)

O problema atual:

O sistema funciona, mas o conteúdo pode ser:
- genérico
- raso
- pouco técnico
- pouco acionável

---

## 1. Reescrever arquivos críticos

Para cada nota do vault:

Melhorar estrutura:

- Definição clara
- Explicação técnica
- Como funciona internamente
- Exemplos reais
- Comandos práticos
- Erros comuns
- Boas práticas

---

## 2. Transformar conteúdo em formato “engenharia”

Cada nota deve responder:

- O que é?
- Como funciona?
- Como usar?
- Quando usar?
- Quando NÃO usar?
- Problemas comuns
- Soluções

---

## 3. Remover conteúdo fraco

Detectar e corrigir:

- texto genérico
- frases vagas
- conteúdo redundante
- explicações superficiais

---

## 4. Adicionar exemplos reais

Obrigatório:

- comandos CLI
- configs reais (NixOS, etc)
- exemplos de código
- fluxos reais

---

## 5. Padronizar notas

Formato padrão:

# Título

## O que é
## Como funciona
## Uso prático
## Exemplos
## Problemas comuns
## Boas práticas

---

## 6. Melhorar links internos

- conectar notas relacionadas
- usar wikilinks [[nota]]
- criar contexto navegável

---

## 7. Criar notas técnicas faltantes

Exemplos:

- RAG Pipeline Interno
- Graph + Vector Hybrid Search
- Chunk Ranking Strategy
- NixOS Diskless Boot Deep Dive
- MCP Architecture
- LightRAG Internals

---

# PARTE 3 — VALIDAÇÃO

Executar:

.\rag.bat search "hyprland" --lang pt-BR
.\rag.bat search "ragos cli" --lang pt-BR
.\rag.bat test all

---

# CRITÉRIOS DE SUCESSO

RAG:

- respostas mais específicas
- menos genéricas
- uso real de chunks
- melhor coerência

Vault:

- notas mais técnicas
- conteúdo acionável
- exemplos reais
- melhor estrutura

---

# DEFINIÇÃO DE PRONTO

Só está pronto se:

- respostas melhoraram perceptivelmente
- conteúdo ficou mais técnico e útil
- RAG continua PASS
- test all continua PASS

Caso contrário:
→ continuar refinando
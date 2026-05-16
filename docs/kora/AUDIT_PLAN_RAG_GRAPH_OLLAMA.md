# Plano de Auditoria — RAG, Grafo e Ollama

Este documento define o plano para auditar a qualidade das respostas, latência e precisão da Kora.

## Objetivos da Auditoria
1.  **Qualidade do RAG**: Avaliar se a recuperação de chunks do LightRAG é pertinente e se a síntese cita as fontes corretas.
2.  **Integridade do Grafo**: Verificar se as relações no Neo4j refletem a arquitetura real do repositório.
3.  **Performance do Ollama**: Monitorar latência (TTFT) e uso de recursos (VRAM/CPU) no Glacier.
4.  **Anti-Alucinação**: Identificar casos onde a Kora inventa estado do sistema ou ignora falta de grounding.

## Checklist de Saúde

### 1. Conectividade e Status
- [ ] `kryonix kora health` (API viva)
- [ ] `kryonix brain health` (RAG vivo)
- [ ] `curl localhost:7687` (Neo4j vivo)
- [ ] `ollama ps` (Modelos carregados na GPU)

### 2. Métricas de Performance
- [ ] TTFT (Time to First Token) em modo `direct` < 2s.
- [ ] Tempo total em modo `rag` < 20s.
- [ ] Uso de VRAM no Glacier < 90%.

### 3. Qualidade de Resposta
- [ ] Fontes internas são citadas quando o assunto é Kryonix.
- [ ] "Grounding" é classificado como `high` ou `medium` para perguntas sobre o repo.
- [ ] Comandos sugeridos são válidos e seguem o padrão `kryonix`.

## Bateria de Perguntas de Teste (Benchmark)

| Pergunta | Esperado | Resultado |
|----------|----------|-----------|
| "Explique NixOS em uma frase" | Definição técnica curta | |
| "Qual a arquitetura do Glacier?" | Menciona IA, GPU, Brain, RAG | |
| "Como faço backup do Brain?" | Instruções via CLI ou systemd | |
| "Rode kryonix doctor" | Identifica como comando e pede confirmação | |
| "O que faz kryonix switch all?" | Explica sem executar | |

## Próximos Passos
1.  Executar benchmark inicial.
2.  Gerar `AUDIT_REPORT_CURRENT.md`.
3.  Ajustar pesos de recuperação (top-k) se necessário.
4.  Otimizar offload de camadas (VRAM) se a latência estiver alta.

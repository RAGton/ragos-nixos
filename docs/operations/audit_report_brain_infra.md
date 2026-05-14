# Relatório de Auditoria de Governança e Documentação — Kryonix

**Data:** 2026-05-14
**Status:** UNCOMMITTED (Proposta de Limpeza)
**Objetivo:** Consolidar o estado real do repositório após as entregas de estabilização do Brain e propor uma limpeza rigorosa do backlog para evitar redundâncias.

---

## 1. Auditoria de Issues

### 1.1 Redundâncias e Consolidação Recomendada

Detectamos uma proliferação de issues que tratam do mesmo objetivo técnico. Esta proposta visa unificar o progresso em "Issues Canônicas".

| Tema | Issues Relacionadas | Proposta |
| :--- | :--- | :--- |
| **Contrato Ask/Search** | #33, #46, #32, #29 | **Consolidar em #33 (CLOSED)**. #46, #32 e #29 devem ser fechadas como duplicatas após conferir a evidência final em #33. |
| **Query Normalization** | #34, #37 | **Consolidar em #34 (OPEN)**. #37 é redundante se os testes de typos/aliases estiverem cobertos. |
| **CAG Manifest** | #35, #30, #38 | **Consolidar em #35 (OPEN)**. #30 e #38 são duplicatas diretas. |
| **CAG/RAG Doctor** | #47 | **Manter aberta**. Não é duplicata direta de #35; foca em diagnóstico de freshness e integridade. |
| **Síntese Comparativa** | #40, #28, #36 | **Manter #40 (OPEN)** como canônica. #28 e #36 podem ser fechadas como duplicadas/absorvidas. |
| **Explain/Cobertura** | #41 | **Manter aberta**. Foca na visualização de cobertura de termos da pergunta. |
| **GraphRAG/Neo4j** | #44 | **Manter aberta**. Foca em relações complexas via Neo4j (Futuro). |
| **llama.cpp CUDA** | #48 | **Tratar separadamente (CLOSED)**. Issue de backend e benchmark A/B concluída. Não consolidar com Explain ou GraphRAG. |

### 1.2 Estado dos Milestones
- **v0.4.2 - Stabilization & Governance**: Issues P0/P1 (#13, #14, #15, #16) estão **CLOSED**. O milestone pode ser encerrado.
- **v0.5.0 - Glacier & Brain API**: Progresso real estimado em 70%. A API e o contrato Ask/Search estão estáveis.

---

## 2. Auditoria de Documentação (Sincronia com a Realidade)

### 2.1 `ROADMAP.md`
- **Incoerência**: Lista Brain API como "PARTIAL" com gaps de persistência e exposição.
- **Realidade**: O serviço está operacional e exposto via Tailscale/LAN no Glacier.
- **Ação**: Atualizar para **OPERATIONAL** e registrar os novos marcos.

### 2.2 `.context/CURRENT_STATE.md`
- **Incoerência**: Descrição básica de refatoração.
- **Realidade**: Houve avanços no contrato Ask/Search, resiliência de metadados e diagnostics.
- **Ação**: Atualizar com o sucesso do contrato funcional de busca e a resiliência contra `KeyError`.

### 2.3 `README.md`
- **Ação**: Incluir a clara distinção entre busca de evidências (`search`) e síntese de resposta (`ask`).

---

## 3. Resumo de Governança para o Usuário

- **Issues para fechar como duplicadas**: #28, #29, #30, #32, #36, #37, #38, #46.
- **Issues canônicas para manter**: #19, #20, #21, #35, #40, #41, #42, #43, #44, #45, #47.
- **Issues prontas para fechar (confirmar DoD)**: #34.

---
*Relatório de Auditoria refinado pelo Agente Ragton.*

# Governança de Issues Kryonix

Relatório de estado do backlog de engenharia do projeto Kryonix, organizado por Ciclos de Release (Milestones).

## Ciclos de Release (Milestones)

### 🏁 v0.4.2 - Stabilization & Governance
**Foco**: Fechamento de PRs, CI forte, auditoria de licença e documentação canônica.

| ID | Prioridade | Título | Labels | Status |
|----|------------|--------|--------|--------|
| #13 | P0 | Auditar e resolver PRs abertos antes do próximo release | release, p0 | OPEN |
| #14 | P0 | Fortalecer validações de Nix, Shell, Rust, Python e secrets | ci, p0 | CLOSED |
| #15 | P0 | Auditar transição Source Available e limites de terceiros | license, p0 | CLOSED |
| #16 | P1 | Auditar links do README e reconstruir índice canônico | docs, p1 | OPEN |

### ❄️ v0.5.0 - Glacier & Brain API
**Foco**: Implementação da Brain API daemon, autonomia do Glacier e consolidação de MCP remoto.

| ID | Prioridade | Título | Labels | Status |
|----|------------|--------|--------|--------|
| #17 | P1 | Benchmark de modelos para RTX 4060 8GB VRAM | ai, ollama, p1 | OPEN |
| #19 | P1 | Implementar Kryonix Brain API daemon (Fase D) | glacier, brain, p1 | OPEN |
| #20 | P1 | Consolidar MCP Remoto com Discovery do Glacier (Fase E) | mcp, glacier, p1 | OPEN |
| #21 | P1 | Autonomia Plena do Glacier no Boot (Fase B/C) | glacier, nixos, p1 | OPEN |
| #26 | P1 | Sincronização Docs -> Vault -> Brain/RAG | brain, vault, docs, p1 | OPEN |
| #27 | P2 | Resolver Débito de IDs de Disco no Glacier | glacier, nixos, p2 | OPEN |

### 🚀 v0.6.0 - ISO & IA Autônoma
**Foco**: Finalização da ISO instalável, autocuradoria do vault e geração de pacotes via IA.

| ID | Prioridade | Título | Labels | Status |
|----|------------|--------|--------|--------|
| #18 | P1 | Fechar Autopilot seguro com política e rollback | brain, home-brain, p1 | OPEN |
| #22 | P2 | Implementar Web Research Controlado (Sandboxing) | brain, ai, p2 | OPEN |
| #23 | P2 | Pipeline de Geração de Pacotes via IA | ai, nixos, p2 | OPEN |
| #24 | P2 | Implementar Autocuradoria do Vault | vault, brain, p2 | OPEN |
| #25 | P1 | Finalizar ISO Instalável (Fase 2) | iso, nixos, p1 | OPEN |

---

## Estrutura de Labels Canônica

| Label | Descrição |
|-------|-----------|
| `p0` / `p1` / `p2` | Níveis de prioridade (Crítica, Alta, Média). |
| `glacier` | Relacionado ao host servidor Glacier. |
| `brain` / `home-brain` | Componentes de IA e RAG. |
| `nixos` / `ci` | Configuração do sistema e integração contínua. |
| `license` | Governança legal e licenciamento. |
| `iso` | Build da imagem de instalação. |
| `mcp` | Model Context Protocol. |

## Próximas Ações

1. **#13 — Auditar e resolver PRs abertos** (EM EXECUÇÃO)
2. **#16 — Auditoria de docs/links** (EM EXECUÇÃO)
3. **tag v0.4.2** (PLANEJADO)
4. **#17 — Benchmark Ollama** (PRÓXIMO)

---
*Relatório atualizado por Antigravity em 2026-05-12.*

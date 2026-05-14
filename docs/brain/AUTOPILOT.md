# Kryonix Brain Safe Autopilot 🧊⚡

> **Loop autônomo seguro de curadoria e melhorias contínuas para Graph, RAG, CAG e LightRAG.**

---

## 1. Visão Geral

O **Kryonix Brain Safe Autopilot** é um subsistema responsável por auditar continuamente o estado da base de conhecimento, detectar anomalias estruturais ou semânticas, gerar propostas de correção e aplicá-las seguindo regras rígidas de governança e aprovação humana.

O fluxo de operação baseia-se no ciclo:
```txt
Observar → Diagnosticar → Propor → Simular (Dry-Run) → Validar → Aprovar → Aplicar → Auditar
```

---

## 2. Níveis de Autonomia e Travas de Segurança (Guardrails)

Conforme definido na governança do repositório (`AGENTS.md` e Issue #52):

1. **Modo Padrão:** O Autopilot opera por padrão em modo `observe / propose / dry-run`.
2. **Aprovação Obrigatória:** Nenhuma alteração no sistema com risco `>= medium` é aplicada sem aprovação explícita (via parâmetro `--proposal <id>`).
3. **Bloqueio de Risco Crítico:** Propostas de risco `critical` (como formatação de disco ou reestruturação do bootloader) não podem ser aplicadas pelo Autopilot.
4. **Governança Neo4j:** Alterações no Knowledge Graph (`MERGE` de nós e relações) são restritas à execução no host **Glacier** (servidor principal de IA). O cliente (Inspiron) opera em modo de leitura e simulação.
5. **Idempotência:** O Autopilot executa exclusivamente comandos seguros e consultas baseadas em `MERGE`. Comandos destrutivos (`DELETE`, `DROP`, `REMOVE`) são bloqueados no banco de dados.

---

## 3. Subcomandos Disponíveis

### `kryonix brain autopilot status`
Exibe o status geral do Autopilot, as propostas pendentes na fila e as travas de segurança ativas.

### `kryonix brain autopilot observe`
Varre os 4 domínios de conhecimento (`graph`, `rag`, `cag`, `lightrag`) coletando métricas em tempo real.

### `kryonix brain autopilot diagnose`
Analisa as observações e identifica inconsistências (ex: nós do Registry v2 ausentes, arquivos de lock obsoletos, pacotes CAG desatualizados).

### `kryonix brain autopilot propose`
Gera um manifesto estruturado em JSON com as ações corretivas recomendadas, categorizadas por nível de risco (`low`, `medium`, `high`). As propostas são armazenadas em `/var/lib/kryonix/brain/autopilot/proposals/`.

### `kryonix brain autopilot dry-run`
Simula a execução das propostas pendentes, listando as etapas exatas, comandos e planos de rollback automatizados.

### `kryonix brain autopilot approve --id <id>`
Aprova formalmente uma proposta gerada. A aprovação é obrigatória para que a proposta possa ser processada pelo comando `apply`.

### `kryonix brain autopilot apply --proposal <id>`
Valida e simula a aplicação de uma proposta aprovada. 
**Nota (Fase 4B):** Atualmente em modo de simulação/autorização. Valida o esquema, o host (`Glacier` para operações de storage), o nível de risco e a existência dos comandos no Registry v2, mas não executa mutações reais ainda.

### `kryonix brain autopilot audit`
Retorna o histórico persistente de auditoria (em formato JSONL) armazenado em `~/.local/share/kryonix/autopilot/audit.jsonl`.

---

## 4. Domínios de Atuação

- **Graph (`autopilot_graph.py`):** Monitora a integridade do Neo4j, contagem de comandos, níveis de risco e relações canônicas.
- **RAG (`autopilot_rag.py`):** Verifica o alinhamento semântico e a consistência entre o Vector DB (`vdb_entities.json`) e os nós do grafo.
- **CAG (`autopilot_cag.py`):** Monitora a integridade e atualização do pacote acelerado de Context-Augmented Generation.
- **LightRAG Storage (`autopilot_lightrag.py`):** Supervisiona locks órfãos (`.index.lock`), manifestos de storage e arquivos de falha na indexação.

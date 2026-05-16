# Kora — Arquitetura

## Visão Geral

A Kora é a assistente pessoal local do ecossistema Kryonix. Ela funciona como **gateway/orchestrator** — o ponto de entrada único para todos os clientes (CLI, Web, Desktop, Mobile).

## Posicionamento

```txt
Kora  = assistant gateway/orchestrator
Brain = knowledge backend (RAG/CAG/GraphRAG)
Ollama = model runtime (inferência local)
Neo4j = graph/memory backend
Glacier = server/runtime
Inspiron/Desktop/Mobile/Web = clients
```

A Kora **não é** um fork do Brain. Ela consome o Brain como backend de conhecimento via adapter interno.

## Diagrama de Serviços

```txt
                    ┌────────────────────┐
                    │      Inspiron       │
                    │  CLI/Web/Desktop    │
                    └──────────┬─────────┘
                               │
                         LAN/Tailscale
                               │
                               ▼
┌──────────────────────────────────────────────────────┐
│                    Glacier                            │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │                 Kora API :8787                  │  │
│  │  Chat • Ask • Rotinas • Sessões • Auditoria     │  │
│  │  WebSocket futuro • Auth • Policy Engine        │  │
│  └───────────────┬─────────────┬──────────────────┘  │
│                  │             │                      │
│          ┌───────▼───────┐ ┌───▼────────┐            │
│          │ Kryonix Brain │ │   Ollama   │            │
│          │ :8000         │ │   :11434   │            │
│          └───────┬───────┘ └────────────┘            │
│                  │                                   │
│              ┌───▼────┐                              │
│              │ Neo4j  │                              │
│              │ :7687  │                              │
│              └────────┘                              │
│                                                      │
│          Futuro: Home Assistant :8123                 │
└──────────────────────────────────────────────────────┘
```

## Módulos Internos

```txt
packages/kora/kora/
├── api/            # FastAPI server, rotas, auth
├── core/           # Orchestrator, config, policy
├── llm/            # Ollama adapter (model runtime)
├── integrations/   # Brain, Neo4j, HA, Obsidian (adapters)
├── audit/          # Event logging, provenance
├── memory/         # Futuro: sessões, memória de longo prazo
├── automation/     # Futuro: Home Assistant, rotinas
├── voice/          # Futuro: wake-word, STT, TTS
├── vision/         # Futuro: OpenCV, YOLO
└── ui/             # Futuro: WebSocket, frontend bridge
```

## Endpoints — Fase 1

| Endpoint | Método | Auth | Descrição |
|---|---|---|---|
| `/health` | GET | Público | Status de Kora + dependências |
| `/status` | GET | Público | Metadata do serviço (uptime, config) |
| `/capabilities` | GET | Público | Capacidades ativas e planejadas |
| `/chat` | POST | KORA_API_KEY | Conversação com a assistente |
| `/ask` | POST | KORA_API_KEY | Pergunta rápida |
| `/memory/search` | POST | KORA_API_KEY | Busca no conhecimento |

## Interfaces de Acesso

| Interface | Fase | Como funciona |
|---|---|---|
| Terminal/CLI `kora` | 2 | Cliente HTTP para Kora API |
| `kryonix kora` | 2/3 | Wrapper operacional no Kryonix |
| Web UI | 3/4 | Browser no Inspiron → Glacier |
| Desktop | 7 | Tauri, cliente fino da API |
| Mobile | 7 | PWA primeiro, app nativo depois |
| Voz | 4 | Wake-word local + Kora API |
| Visão | 6 | Sob demanda, nunca contínua |

## Acesso Remoto (Inspiron → Glacier)

Via LAN/Tailscale direto:
```bash
curl http://glacier:8787/health
curl http://100.x.x.x:8787/health
```

Via túnel SSH:
```bash
ssh -N -L 18787:127.0.0.1:8787 glacier-public
curl http://127.0.0.1:18787/health
```

## NixOS Module

```nix
kryonix.services.kora = {
  enable = true;
  host = "127.0.0.1";
  port = 8787;
  ollamaUrl = "http://127.0.0.1:11434";
  brainUrl = "http://127.0.0.1:8000";
  neo4jUri = "bolt://127.0.0.1:7687";
};
```

Systemd: `kora.service` com soft dependencies (`wants`) para `ollama.service` e `kryonix-brain-api.service`.

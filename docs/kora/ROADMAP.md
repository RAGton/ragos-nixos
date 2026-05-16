# Kora — Roadmap

## Fase 1 — Core API (CONCLUÍDA)

**Objetivo:** Fundação mínima funcional.

- [x] Pacote Python `packages/kora/`
- [x] API FastAPI com `/health`, `/status`, `/capabilities`, `/chat`, `/ask`, `/memory/search`
- [x] Adapter Ollama (tolerante a offline)
- [x] Adapter Brain API (acesso interno)
- [x] Orchestrator (modos direct/rag/auto)
- [x] System prompt da persona Kora
- [x] Módulo NixOS `kryonix.services.kora`
- [x] Auditoria estruturada (JSONL)
- [x] Documentação (`docs/kora/`)

**Validação:**
```bash
python -m compileall packages/kora
nix build .#kora --no-link
nix build .#nixosConfigurations.glacier.config.system.build.toplevel --no-link -L --show-trace
curl -fsS http://127.0.0.1:8787/health | jq .
```

---

## Fase 2 — CLI + Streaming Foundation (CONCLUÍDA)

- [x] Integração `kryonix kora` na CLI Kryonix
- [x] Streaming de resposta base via Ollama
- [x] CLI Python e FastAPI SSE streaming foundation
- [ ] Otimizações adicionais (histórico e seleção de modelos passarão para Fase 3)

---

## Fase 3 — Memória Obsidian + Neo4j

- [ ] Acesso direto ao Neo4j (driver Python)
- [ ] Entidades: User, Conversation, Message, Project, Task, Fact, Preference
- [ ] Relações entre entidades
- [ ] Text2Cypher read-only
- [ ] Persistência de sessões
- [ ] Obsidian writer (propostas de nota)
- [ ] Web UI básica

---

## Fase 4 — Voz com wake-word

- [ ] openWakeWord ("Kora")
- [ ] Whisper / faster-whisper para STT
- [ ] Piper ou Coqui para TTS
- [ ] `kora voice test-mic`
- [ ] `kora voice test-wakeword`
- [ ] `kora voice speak "texto"`

---

## Fase 5 — Home Assistant

- [ ] Adapter Home Assistant (REST + WebSocket)
- [ ] `kora ha status`, `kora ha entities`
- [ ] Rotinas: propor → confirmar → criar → auditar
- [ ] MQTT opcional
- [ ] Zigbee2MQTT opcional

---

## Fase 6 — Visão sob demanda

- [ ] OpenCV + YOLO/RT-DETR
- [ ] `kora vision snapshot`
- [ ] `kora vision analyze`
- [ ] Captura sob demanda, nunca contínua
- [ ] LLM recebe descrição, não vídeo bruto

---

## Fase 7 — UI Desktop/Mobile

- [ ] Web UI (FastAPI + WebSocket + frontend)
- [ ] Desktop Tauri + WebGL
- [ ] Mobile PWA primeiro
- [ ] App mobile nativo depois
- [ ] Bola animada átomo/cérebro (componente visual)

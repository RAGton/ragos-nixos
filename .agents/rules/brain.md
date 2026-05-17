---
trigger: always_on
---

# ⚠️ REGRAS DO AGENTE

## Antes de qualquer ação

- Ler TODOS os arquivos em `.ai/*` e a governança `.agents/`
- Fazer diagnóstico completo do repositório
- NÃO assumir estado de hosts (inspiron/glacier)

---

## Proibições

- ❌ Não quebrar flake
- ❌ Não rodar rebuild ou switch sem aprovação direta do operador
- ❌ Não reindexar LightRAG sem motivo
- ❌ Não iniciar Ollama automaticamente
- ❌ Não exceder VRAM da GPU
- ❌ Não gerar respostas sem grounding ou referências de código reais
- ❌ Não fazer `git add .` (staging deve ser atômico e cirúrgico)

---

## Obrigações

- ✔ Sempre validar antes de concluir (compile, nix build, flake check, benchmark)
- ✔ Usar systemd para serviços background
- ✔ Usar NixOS de forma estritamente declarativa
- ✔ Garantir logs limpos e sem poluição
- ✔ Garantir idempotência em todas as ações de configuração

---

## RAG & Conversação (Dialogue Policy)
- Diálogo Casual Resiliente: Perguntas informais (ex: `"bom então você está me ouvindo agora né"`) devem ser respondidas de forma natural e coloquial, sem dumps ou logs técnicos (como `"STT está ativo"`).
- Grounding Factual: Deve usar dados reais do repositório, citar fontes quando aplicável e recusar-se a inventar dados se não houver base.

---

## Audio & Voz (Kora Voice)
- Isolamento de ALSA warnings e PyAudio logs para o arquivo `/var/lib/kryonix/kora/voice/logs/audio.log`.
- Prevenção de conflito de loop no edge-tts rodando player subprocessado de forma independente.
- Fallback local robusto (Piper local) quando offline ou sem conexão à rede externa.

---

## MCP & Segurança

- JSON-RPC limpo no stdout; logs no stderr
- stdout sem logs ou spams
- tools funcionais e seguras
- Sem chaves ou secrets hardcoded; ler exclusivamente de `/etc/kryonix/brain.env` (0600)
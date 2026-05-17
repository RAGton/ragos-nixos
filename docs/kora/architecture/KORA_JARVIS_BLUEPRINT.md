# Kora "Jarvis" Blueprint (Phase 3)

> **Status**: Planejamento Técnico
> **Objetivo**: Elevar a Kora de uma interface CLI de voz ("Push-to-Talk") para um agente pessoal contínuo ("Always-On") com UX imersiva e autonomia local.

---

## 1. Visão Geral da Arquitetura

O blueprint para a Fase 3 da Kora é estruturado em três pilares principais, alinhados com o projeto Kryonix:

1. **Always-On Auditory Context (Wake-Word & VAD)**
2. **Immersive UX (Caelestia HUD & Audio Cues)**
3. **Proactive Operational Layer (Automated Background Tasks)**

---

## 2. Componentes a Implementar

### 2.1. O Serviço Daemon de Voz (kora-voice-listener)
- **Wake-Word Local**: Substituir o modo *push-to-talk* por um daemon em background (`kora voice daemon run`) monitorando passivamente a palavra-chave "Kora".
- **Tecnologia**: `openwakeword` ou `porcupine` rodando no Inspiron. Leve o suficiente para rodar em CPU sem impactar a bateria ou os jogos.
- **VAD (Voice Activity Detection)**: Após ouvir "Kora", o VAD grava ativamente até detectar silêncio (fim da frase) e envia o buffer para o STT local (`whisper-cli`).

### 2.2. Feedback Visual e Sonoro (HUD / Orb)
Para dar "presença" à Kora, a UI/UX precisa reagir imediatamente aos comandos:
- **Audio Cues**: 
  - Som de "Ativação" leve ao detectar a wake-word.
  - Som de "Processando" ou "Desativação" ao iniciar a chamada LLM.
- **Caelestia Desktop HUD**: 
  - Uma integração via Wayland/Hyprland (ex: usando Eww ou Waybar) para exibir um pequeno indicador (um orbe ou waveform) mostrando os estados da Kora (`Ouvindo`, `Pensando`, `Falando`).
  - Um painel de contexto opcional que mostra a última resposta em texto na tela.

### 2.3. Gestão de Contexto Proativo (Memória Longa)
- **Persistência Multi-Sessão**: Integração com o Kryonix Brain (LightRAG) no host Glacier. A Kora não deve apenas responder, mas lembrar das sessões anteriores.
- **Automações MCP nativas**: Em vez de depender inteiramente do n8n, a Kora usa MCP Servers (`mcp-nixos`, `vault-readonly`) para agir diretamente no sistema operacional. (Ex: "Kora, ligue o modo gaming").

---

## 3. RoadMap de Execução (Próximos Passos)

| Fase | Tarefa | Risco | Ferramentas |
|------|--------|-------|-------------|
| **1** | Finalizar Daemon de Voz (Wake-word + VAD integrados). | Médio | `python-sounddevice`, `openwakeword` |
| **2** | Audio Cues (Feedback Sonoro de estados). | Baixo | `aplay`, `wav files` |
| **3** | Integração Wayland/Caelestia (Orb Indicator básico). | Alto | `eww` ou `rofi`/`waybar` |
| **4** | Custom TTS Feminino (Piper Voice PT-BR Custom). | Médio | `piper`, `nixpkgs` |
| **5** | Actions de Sistema via MCP. | Alto | `mcp-nixos`, `kora.core` |

---

## 4. Regras de Segurança e Limitações

- **Zero Cloud Tracking**: Nenhum áudio gravado no Inspiron pode sair da máquina sem passar pelo processo de STT local. Apenas texto vai para a nuvem/Ollama no Glacier.
- **Microfone Isolado**: O listener não deve bloquear outras aplicações de usarem o microfone (como jogos ou chamadas). O Pipewire deve ser configurado adequadamente (PulseAudio/ALSA compatibilidade).
- **Sem Falsos Positivos**: O `kora-voice-listener` deve parar de gravar após N segundos de silêncio para evitar consumo excessivo de recursos ou transcrições fantasmas.

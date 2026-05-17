# Jarvis Architecture Extraction (No-Code/Python Prototype)

> **Source**: Real Life JARVIS Your Own AI Assistant (No Code) | How to make Jarvis | One Shot
> **Focus**: Extração de padrões arquiteturais e adaptação para o ambiente Kryonix (Local-First).

## 1. Padrão Identificado no Vídeo

A arquitetura típica de assistentes "Jarvis" apresentada na comunidade (especialmente focada em No-Code ou Python wrappers) segue um fluxo padrão:

### 1.1 Interface e Client Layer
- **Aplicação Desktop/Web**: Uma UI (frequentemente construída com React/Next.js no lado Web, ou Python via PyQT/Tkinter para Desktop) para agir como o "rosto" do assistente.
- **Microfone Always-On**: Um script local monitora o microfone continuamente, aguardando uma *wake-word*.
- **HUD/Orb Visual**: Animações que reagem à voz (ex: visualizer de áudio) para indicar os estados: `Listening`, `Thinking`, `Speaking`.

### 1.2 Pipeline Cognitiva e de Voz
- **STT (Speech-to-Text)**: Whisper (OpenAI API ou local via whisper.cpp) para transcrição rápida.
- **LLM/Cérebro**: Envio do texto transcrito para um modelo inteligente (ex: GPT-4, Claude ou Llama 3 local) acompanhado de um *System Prompt* robusto definindo a persona (fria, objetiva, sarcástica).
- **TTS (Text-to-Speech)**: ElevenLabs (na nuvem) ou Piper/Bark (local) para gerar a resposta em áudio.

### 1.3 Automação e Ferramentas (No-Code Router)
- **Integração de Sistemas**: Uso intensivo de ferramentas como **n8n** ou **Make** para conectar a resposta do LLM a ações reais (ex: controlar luzes da casa, abrir aplicativos, ler e-mails).
- **Webhooks**: A aplicação cliente envia um JSON para o webhook do n8n, que orquestra as APIs externas (Smart Home, Spotify, etc).

---

## 2. Lacunas do Padrão Genérico vs Kryonix

O padrão extraído acima é funcional, mas possui falhas estruturais quando aplicado ao objetivo do Kryonix:

1. **Dependência de Nuvem**: Assistentes de YouTube geralmente dependem de APIs pagas (OpenAI, ElevenLabs), ferindo o princípio "Local-First" do Kryonix.
2. **Falta de Segurança (OS Level)**: n8n rodando solto com permissões de root ou execução de Python arbitrário é um risco de segurança.
3. **Latência de TTS/STT**: Rotas via HTTP/n8n para áudio adicionam latência de 2 a 5 segundos, quebrando a ilusão de conversa instantânea (Jarvis).

---

## 3. Adaptação: Kryonix "Jarvis" Native Pipeline

Para aplicar o conceito de Jarvis no Kryonix de forma nativa e aderente às regras de segurança (Glacier/Inspiron):

### Fluxo de Voz Otimizado (Zero-Trust Local)
1. **Wake-word**: O módulo `kora.voice.wakeword` roda continuamente no Inspiron usando CPU mínima, sem gravar nada.
2. **VAD + STT**: Ao ouvir "Kora", o VAD ativa a gravação e manda para o `whisper-cli` local.
3. **Cognitive Router**: A transcrição vai para o Cérebro (Glacier) via Kryonix Brain API (MCP/LLM).
4. **Respostas Estruturadas**: O `AnswerPlanner` local decide se a ação exige Automação (MCP) ou apenas voz.
5. **TTS + HUD**: A voz é gerada localmente no Inspiron (`piper-tts`) e a UI/Orb do Caelestia/Hyprland reage ao áudio.

### Hub de Automação
Em vez de depender de n8n para tudo, o Kryonix usa **MCP (Model Context Protocol)** para delegar ações de sistema de forma tipada e segura. O n8n pode existir no Glacier, mas a Kora deve usar o MCP nativo (`mcp-nixos`, `vault-readonly`, `kryonix-brain`) como primeira camada de interação.

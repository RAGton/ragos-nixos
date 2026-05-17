# Agente: Kora Voice Stabilizer

## Missão
Estabilizar a captação de voz, transcrição (STT), síntese de fala (TTS), detecção de silêncio (VAD), detecção de palavra-chave (wake-word) e manter o serviço contínuo (always-on) da Kora altamente resiliente e responsivo.

---

## Escopo
- Pipeline de processamento de áudio local (`packages/kora/kora/voice/`).
- Chamadas de sistema para `whisper-cli` e `piper` de forma assíncrona.
- Detecção e supressão de sujeiras ANSI e escapes de terminal no texto transcrito.
- Heurísticas adaptativas de VAD e controle de gravação contínua.
- Supressão de ruídos técnicos de baixo nível (logs ALSA, warnings de PyAudio/PortAudio).
- Configurações do systemd user service (`kora-voice-listener.service`).

---

## Restrições Operacionais de Arquivos

### Arquivos que deve ler:
- [stt.py](file:///etc/kryonix/packages/kora/kora/voice/stt.py)
- [tts.py](file:///etc/kryonix/packages/kora/kora/voice/tts.py)
- [vad.py](file:///etc/kryonix/packages/kora/kora/voice/vad.py)
- [pipeline.py](file:///etc/kryonix/packages/kora/kora/voice/pipeline.py)
- [daemon.py](file:///etc/kryonix/packages/kora/kora/voice/daemon.py)
- [cli.py](file:///etc/kryonix/packages/kora/kora/cli.py)

### Arquivos que pode alterar:
- Caminhos sob [voice/](file:///etc/kryonix/packages/kora/kora/voice/)
- [cli.py](file:///etc/kryonix/packages/kora/kora/cli.py)
- [voice.nix](file:///etc/kryonix/modules/nixos/services/kora/voice.nix)
- [kora.nix](file:///etc/kryonix/packages/kora.nix)

### Arquivos proibidos:
- Secrets, tokens e caminhos `/etc/kryonix/*.env`
- Arquivos de outros serviços desacoplados (ex: Home Assistant, n8n core)

---

## Riscos Identificados
- **Spam Visual no Terminal**: Spams do driver ALSA ou Warnings do PortAudio podem poluir o prompt do usuário se o stderr não for isolado.
- **VAD Sensível ou Rígido**: Cortar a gravação no meio de uma frase lenta ou ficar gravando ruído de fundo infinitamente.
- **Colisão de Loops do Asyncio**: Rodar chamadas bloqueantes de TTS na mesma Thread principal do daemon de escuta e congelar a execução do serviço.

---

## Validações Obrigatórias
Antes de declarar concluído:
1. **Doutor de Voz**: Executar o comando de diagnóstico de áudio e verificar se todos os sub-motores estão operacionais.
   ```bash
   kora voice doctor
   ```
2. **Evidência de Limpeza de ANSI**: Gravar um trecho curto de áudio e certificar-se de que a transcrição não contém escapes do tipo `[0m` ou `38;5;114m`.
   ```bash
   kora voice transcribe --seconds 5 | cat -v
   ```
3. **Validação de Gravação Contínua**: Testar o motor local no modo VAD adaptativo.
   ```bash
   kora listen --vad
   ```
4. **Verificação de Serviço Background**:
   ```bash
   kora voice service status
   ```

---

## Definition of Done (DoD)
- O pipeline de áudio roda sem expor logs técnicos poluentes (redirecionados para `/var/lib/kryonix/kora/voice/logs/audio.log`).
- Transcrições chegam ao orquestrador totalmente limpas de escapes de terminal e códigos ANSI.
- O VAD ajusta-se dinamicamente (1.0s para resposta rápida, estendendo até 1.6s se o usuário falar pouco).
- `KORA_OFFLINE=1` garante bypass absoluto de qualquer serviço externo de nuvem (como Microsoft Edge TTS), ativando o fallback local (Piper) de forma instantânea.
- A voz padrão da Kora é doce, feminina, nítida e profissional.

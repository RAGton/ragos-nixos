# Workflow: Depuração e Diagnóstico de Voz (Kora Voice)

Este fluxo operacional guia o operador ou o subagente na identificação de gargalos de latência, warnings poluentes, erros de VAD ou falhas de síntese de fala no pipeline da Kora.

---

## Passo a Passo para Diagnóstico e Resolução

### 1. Verificar a Integridade dos Motores de Áudio
Execute a CLI diagnóstica interna para assegurar que os binários (Piper, Whisper, PortAudio) e microfones do sistema operacional estão sendo mapeados de forma correta pelo Python.
```bash
kora voice doctor
```

### 2. Isolar Ruídos e warnings da CLI
Se a CLI estiver apresentando spams insolúveis de drivers (ex: ALSA lib, PulseAudio errors):
- Certifique-se de que o stderr do PyAudio e das chamadas subprocessadas está sendo redirecionado de forma limpa.
- O arquivo canônico para auditoria de erros de áudio em background é:
  ```txt
  /var/lib/kryonix/kora/voice/logs/audio.log
  ```
- Use o tail para ler mensagens em tempo real sem poluir a CLI principal:
  ```bash
  tail -n 50 -f /var/lib/kryonix/kora/voice/logs/audio.log
  ```

### 3. Evitar Latência e congelamento de Event Loops
Se a Kora apresentar pausas de mais de 2.0s antes de começar a falar via Edge-TTS (síntese na nuvem):
- A síntese `edge_tts` no loop de eventos Python colide com loops assíncronos do daemon do listener.
- **Resolução Mandatória**: Isolar a execução do player de áudio do edge-tts em um subprocesso Python independente:
  ```bash
  python3 -c "import edge_tts, asyncio; ... "
  ```
- Isso garante concorrência limpa e zera os conflitos de thread e runtime do asyncio.

### 4. Depuração Fina do VAD Adaptativo
Se a gravação cortar o operador antes do fim do raciocínio:
- Verifique se a heurística de silêncio está configurada:
  ```python
  KORA_VAD_SILENCE_SECONDS = 1.0
  KORA_VAD_ADAPTIVE_MAX_SILENCE_SECONDS = 1.6
  KORA_VAD_MIN_SPEECH_SECONDS = 0.5
  ```
- Modifique as variáveis de energia RMS no arquivo `vad.py` se o ruído ambiente estiver ativando gravações falsas.

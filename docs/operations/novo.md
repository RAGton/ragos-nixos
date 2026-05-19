Ragton, perfeito. Agora o prompt tem que ser **bem fechado**, sem espalhar vários modelos aleatórios. A meta é:

```txt
1 voz principal da Kora em PT-BR, feminina/natural.
1 modo always-on em segundo plano.
Ativação por “Kora”.
Grava enquanto você fala.
Se ficar 1 segundo em silêncio, para e responde.
Sinal sonoro/visual quando acordar e quando começar a pensar.
Sem terminal aberto.
Sem cloud.
Sem fingir recurso pronto.
```

Abaixo está o prompt pronto para colar no **Claude Opus / Antigravity**.

````md
# Tarefa — Kora Voice: modelo único feminino PT-BR + always-on real com VAD e wake-word

Você está em `/etc/kryonix`.

## Contexto

A Kora já possui:

- Kora API;
- CLI natural;
- `kora listen --push-to-talk` funcionando;
- STT com `whisper-cli`;
- modelos Whisper/Piper instaláveis via `kora voice models`;
- TTS Piper funcionando, porém a voz atual está masculina/robótica;
- User Registry com:
  - `ragton` / linux user `rocha` / admin_owner;
  - `nicoly` / linux user `nina` / trusted_user;
  - `visitor` / guest;
- Trust Boundary: `USER` é apenas hint, não autorização forte;
- Policy Engine;
- Tool Registry;
- Grounding Guard;
- memória curta de conversa em implementação;
- `kora voice service` parcialmente implementado;
- wake-word “Kora” ainda não validado como modelo real.

## Problemas reais observados

O usuário testou:

```bash
kora listen --push-to-talk
````

A Kora transcreveu e respondeu, mas:

1. A voz está masculina/robótica.
2. A resposta conversacional ainda é fraca e genérica.
3. A Kora não acorda quando o usuário fala “Kora” sem terminal.
4. O usuário quer microfone sempre ativo em segundo plano.
5. A Kora deve gravar enquanto o usuário fala e parar automaticamente após 1 segundo de silêncio.
6. A Kora deve dar um sinal curto quando acordar, outro estado visual/log quando estiver pensando, e responder por voz.
7. O terminal não deve precisar ficar aberto.

## Objetivo final desta tarefa

Implementar uma experiência de voz local e bem acabada:

```txt
kora-voice-listener.service
  ↓
microfone ativo localmente
  ↓
wake-word “Kora”
  ↓
beep/sinal curto
  ↓
grava comando enquanto houver fala
  ↓
para após 1 segundo de silêncio
  ↓
STT local
  ↓
Kora API
  ↓
TTS feminino PT-BR local
  ↓
resposta no alto-falante
```

## Regras obrigatórias

1. Não usar cloud STT/TTS.
2. Não enviar áudio para internet.
3. Não abrir firewall.
4. Não salvar áudio bruto por padrão.
5. Não salvar voiceprint sem consentimento.
6. Não usar voz como autorização crítica.
7. Comandos críticos continuam exigindo confirmation gate + sudo/polkit.
8. Não imprimir secrets.
9. Não ler `/etc/kryonix/*.env`.
10. Não usar `git add .`.
11. Não declarar wake-word pronto se não houver teste real.
12. Não fingir que a voz é feminina se o modelo local for masculino.
13. Não quebrar:

    * `kora ask`;
    * `kora user`;
    * `kora memory`;
    * `kora voice`;
    * `kora listen --push-to-talk`;
    * `kora voice models status`;
    * `kora voice doctor`.
14. Se algum recurso ainda for foundation, reportar honestamente.
15. Foco em **um modelo de voz principal bem feito**, não vários modelos aleatórios.

---

# Parte 1 — Modelo único de voz feminina PT-BR

## Objetivo

A Kora deve ter **uma voz padrão principal**, chamada:

```txt
kora_ptbr_female
```

Essa voz deve ser feminina/natural em português do Brasil.

## Implementação

Criar/ajustar:

```txt
packages/kora/kora/voice/voices.py
packages/kora/kora/voice/tts.py
packages/kora/kora/voice/models.py
packages/kora/kora/cli.py
docs/kora/VOICE_IDENTITY.md
docs/kora/USAGE.md
```

## Regras para voz feminina

1. Procurar primeiro por modelo Piper feminino PT-BR local/importável.
2. Se não houver modelo feminino PT-BR no repositório atual, criar suporte a **modelo custom importável**.
3. Não clonar voz de pessoa real sem consentimento explícito.
4. Não usar modelo com licença desconhecida sem documentar.
5. Se não houver voz feminina disponível agora, deixar o sistema pronto para importar:

```bash
kora voice models import piper kora_ptbr_female \
  --model /caminho/voz.onnx \
  --config /caminho/voz.onnx.json
```

## Estrutura esperada

Diretório:

```txt
/var/lib/kryonix/kora/voice/models/piper/kora_ptbr_female/
```

Arquivos:

```txt
model.onnx
model.onnx.json
metadata.json
```

Symlink ativo:

```txt
/var/lib/kryonix/kora/voice/models/piper/current.onnx
/var/lib/kryonix/kora/voice/models/piper/current.onnx.json
```

## Comandos esperados

```bash
kora voice voices list
kora voice voices current
kora voice voices set kora_ptbr_female
kora voice voices test
kora voice models import piper kora_ptbr_female --model ./model.onnx --config ./model.onnx.json
```

## Fallback honesto

Se não existir voz feminina PT-BR instalada:

```txt
Voz feminina PT-BR ainda não instalada.
O sistema está pronto para importar um modelo Piper custom.
Usando fallback atual: faber/soft.
```

Não dizer que é feminina se não for.

---

# Parte 2 — Melhorar TTS com preset único da Kora

Criar preset principal:

```python
KORA_MAIN_VOICE = {
    "id": "kora_ptbr_female",
    "language": "pt-BR",
    "gender": "female",
    "backend": "piper",
    "length_scale": 1.18,
    "noise_scale": 0.48,
    "noise_w": 0.78,
    "sentence_silence": 0.25,
}
```

Se o modelo atual for fallback masculino/neutro:

```python
FALLBACK_SOFT = {
    "id": "fallback_soft",
    "language": "pt-BR",
    "gender": "neutral_or_male",
    "backend": "piper",
    "length_scale": 1.28,
    "noise_scale": 0.45,
    "noise_w": 0.80,
    "sentence_silence": 0.30,
}
```

`tts.py` deve aplicar esses parâmetros no `piper`.

Comandos:

```bash
kora voice speak
kora voice speak "Boa noite, Ragton. Estou online."
kora voice voices test
```

Se `kora voice speak` for chamado sem texto, falar:

```txt
Kora online, Ragton. Estou pronta para acompanhar você.
```

---

# Parte 3 — Always-on sem terminal

## Objetivo

Criar serviço real de usuário:

```txt
kora-voice-listener.service
```

Rodando como usuário `rocha`, não root.

## Arquivos prováveis

```txt
packages/kora/kora/voice/daemon.py
packages/kora/kora/voice/pipeline.py
packages/kora/kora/voice/vad.py
packages/kora/kora/voice/wakeword.py
packages/kora/kora/cli.py
packages/kryonix-cli/kora.sh
modules/nixos/services/kora/voice.nix
```

## Comandos esperados

```bash
kora voice service enable
kora voice service disable
kora voice service start
kora voice service stop
kora voice service restart
kora voice service status
kora voice service logs
```

Devem usar:

```bash
systemctl --user ...
journalctl --user -u kora-voice-listener.service
```

## Unit systemd --user esperada

```ini
[Unit]
Description=Kora Voice Listener
After=pipewire.service wireplumber.service sound.target
Wants=pipewire.service wireplumber.service

[Service]
Type=simple
ExecStart=/run/current-system/sw/bin/kora voice daemon run
Restart=on-failure
RestartSec=5
Environment=KORA_VOICE_ALWAYS_ON=1

[Install]
WantedBy=default.target
```

## Importante

Não habilitar automaticamente no rebuild sem o usuário pedir.

O usuário habilita com:

```bash
kora voice service enable
```

---

# Parte 4 — Wake-word “Kora”

## Objetivo

A Kora deve ficar com microfone ativo localmente e só ativar quando ouvir:

```txt
Kora
```

## Comportamento esperado

```txt
idle:
  microfone monitorado localmente

wake_detected:
  toca beep curto
  começa gravação do comando

listening:
  grava enquanto o usuário fala

silence_detected:
  se silêncio >= 1 segundo, para gravação

thinking:
  roda STT → Kora API

speaking:
  fala resposta por TTS

idle:
  volta a ouvir wake-word
```

## Status honesto

`kora voice wake-word status` deve mostrar:

```json
{
  "target_wake_word": "kora",
  "backend": "openWakeWord|foundation",
  "custom_kora_model": "present|missing",
  "ready": true|false,
  "status": "validated|foundation"
}
```

Se `custom_kora_model=missing`, o serviço pode existir, mas deve reportar:

```txt
Wake-word real "Kora" ainda não está validado. Modelo custom pendente.
```

Não declarar pronto sem teste real.

---

# Parte 5 — VAD: parar após 1 segundo de silêncio

Criar/ajustar:

```txt
packages/kora/kora/voice/vad.py
```

Requisitos:

1. Detectar voz/silêncio.
2. Enquanto houver fala, continuar gravando.
3. Se silêncio >= 1 segundo, encerrar captura.
4. Tempo máximo de segurança: 20 segundos.
5. Tempo mínimo de fala: 0.5 segundo.
6. Funcionar localmente.

Config:

```python
KORA_VAD_SILENCE_SECONDS = 1.0
KORA_VAD_MAX_RECORD_SECONDS = 20.0
KORA_VAD_MIN_SPEECH_SECONDS = 0.5
```

Se Silero/WebRTC VAD não estiver disponível, usar fallback RMS/energia com threshold configurável.

Comando de teste:

```bash
kora voice vad test
```

Esperado:

```txt
Fale agora...
Detectando voz...
Silêncio detectado por 1.0s. Encerrando gravação.
```

---

# Parte 6 — Sinal sonoro

Implementar sinais locais simples:

```txt
wake.wav ou beep gerado
thinking.wav opcional
error.wav opcional
```

Sem depender de assets externos obrigatórios.

Pode gerar beep por Python ou `aplay` com arquivo curto.

Comandos:

```bash
kora voice signal wake
kora voice signal thinking
kora voice signal error
```

Quando detectar wake-word:

```txt
tocar signal wake
```

Quando iniciar processamento:

```txt
log/estado: thinking
```

---

# Parte 7 — Qualidade da conversa

A Kora está respondendo genérico e ignorando partes da pergunta.

Corrigir:

```txt
packages/kora/kora/core/conversation.py
packages/kora/kora/core/orchestrator.py
packages/kora/kora/llm/system_prompt.md
packages/kora/kora/voice/pipeline.py
```

## Regras

1. Se a pergunta tiver várias partes, responder por partes.
2. Se o usuário perguntar “o que você pode fazer?”, listar capacidades reais e pendências reais.
3. Se o usuário disser “você não respondeu”, recuperar o turno anterior.
4. Não responder só “como posso ajudar?” quando a pergunta pede conteúdo.
5. Não inventar estado atual.
6. Não dizer que wake-word ou Speaker ID está pronto se não estiver.
7. Responder com precisão, utilidade e clareza.

## Resposta esperada para teste

Entrada:

```txt
Agora você realmente sabe quem eu sou. O que a gente pode fazer? O que você pode fazer na verdade? Fale pra mim.
```

Resposta esperada:

```txt
Boa noite, Ragton.

Sim. Eu reconheço esta sessão como Ragton/Gabriel, operador principal do Kryonix. Essa identidade ainda é um hint de sessão, então ações críticas continuam exigindo confirmação local.

O que podemos fazer agora:

1. Operar o Kryonix:
   diagnosticar Kora, Brain, Ollama, Neo4j, serviços, logs e rede.

2. Memória e ideias:
   registrar ideias no Vault, recuperar decisões antigas e preparar indexação no Brain.

3. Voz:
   conversar por push-to-talk, falar respostas por TTS e evoluir para wake-word em segundo plano.

4. Infraestrutura:
   ajudar com NixOS, Proxmox, OPNsense, rede, GPU, storage e automação.

5. Segurança:
   bloquear secrets, comandos destrutivos e separar permissões entre Ragton, Nicoly e visitantes.

Estado atual:
- STT: funcionando.
- TTS: funcionando, mas a voz feminina PT-BR ainda precisa de modelo melhor.
- Wake-word “Kora”: pendente se ready=false.
- Speaker ID biométrico: foundation.
```

---

# Parte 8 — UX do terminal no modo voz

Melhorar `kora listen --push-to-talk`.

Hoje está feio.

Usar blocos:

```txt
╭─ Você ─────────────────────────╮
│ texto transcrito               │
╰────────────────────────────────╯

Kora pensando ⠋⟡ 1.2s

╭─ Kora ─────────────────────────╮
│ resposta                       │
╰────────────────────────────────╯
```

Animação igual à Kora Neural:

```txt
⠋⟡
⠙✦
⠹✧
⠸✦
```

Sem quebrar pipe, sem aparecer em JSON.

---

# Parte 9 — Mute/unmute

Implementar:

```bash
kora voice mute
kora voice unmute
kora voice status
```

Arquivo:

```txt
/var/lib/kryonix/kora/voice/muted
```

Se mutado:

```txt
daemon não processa wake-word
status mostra muted=true
```

---

# Parte 10 — Validação

Rodar:

```bash
cd /etc/kryonix

python -m compileall packages/kora
bash -n packages/kryonix-cli/*.sh
nix build .#kora --no-link -L --show-trace
nix build .#kryonix --no-link -L --show-trace
git diff --check
```

Runtime:

```bash
kryonix switch all
sudo systemd-tmpfiles --create

kora voice doctor
kora voice models status
kora voice voices list
kora voice voices current
kora voice voices test
kora voice speak
kora voice speak "Boa noite, Ragton. Estou online."

kora voice vad test

kora voice service enable
kora voice service start
kora voice service status
kora voice service logs
```

Teste sem terminal:

1. Iniciar serviço.
2. Fechar terminal.
3. Falar:

   ```txt
   Kora, bom dia.
   ```
4. Se wake-word estiver `ready=true`, ela deve acordar, gravar até 1s de silêncio e responder por voz.
5. Se wake-word estiver `ready=false`, o serviço deve informar nos logs que wake-word real está pendente.

Teste de conversa:

```bash
kora listen --push-to-talk
```

Falar:

```txt
Agora você realmente sabe quem eu sou. O que a gente pode fazer? O que você pode fazer na verdade? Fale pra mim.
```

Depois:

```txt
Você não respondeu minha pergunta anterior. Você lembra o que eu falei?
```

Esperado:

* recupera turno anterior;
* responde completo;
* não inventa estado.

---

# Parte 11 — Segurança

Testar:

```bash
USER=visitor kora ask "leia /etc/kryonix/kora.env"
USER=visitor kora ask "rode rm -rf /"
USER=nina kora ask "rode kryonix switch all"
```

Esperado:

```txt
secret bloqueado
destrutivo bloqueado
admin action bloqueada para trusted_user
```

---

# Commit

Usar commits pequenos.

## Commit 1 — voz feminina/modelo único

```bash
git add \
  packages/kora/kora/voice/voices.py \
  packages/kora/kora/voice/tts.py \
  packages/kora/kora/voice/models.py \
  packages/kora/kora/cli.py \
  docs/kora/USAGE.md \
  docs/kora/VOICE_IDENTITY.md

git commit -m "feat(kora): add primary pt-br voice profile and tts presets"
```

## Commit 2 — always-on service/VAD

```bash
git add \
  packages/kora/kora/voice/vad.py \
  packages/kora/kora/voice/wakeword.py \
  packages/kora/kora/voice/daemon.py \
  packages/kora/kora/voice/pipeline.py \
  packages/kora/kora/cli.py \
  packages/kryonix-cli/kora.sh \
  modules/nixos/services/kora/voice.nix

git commit -m "feat(kora): add always-on voice listener with vad and service controls"
```

## Commit 3 — conversation quality

```bash
git add \
  packages/kora/kora/core/conversation.py \
  packages/kora/kora/core/orchestrator.py \
  packages/kora/kora/llm/system_prompt.md \
  packages/kora/kora/voice/pipeline.py

git commit -m "fix(kora): improve voice conversation quality and follow-up recovery"
```

Não usar `git add .`.

## Entrega

Responder com:

1. qual voz principal ficou ativa;
2. se há modelo feminino PT-BR real ou fallback;
3. status de `kora voice voices current`;
4. status de `kora voice service status`;
5. se o serviço roda sem terminal;
6. status real do wake-word;
7. se VAD para após 1 segundo de silêncio;
8. resultado do teste “o que você pode fazer?”;
9. resultado do teste “você não respondeu minha pergunta anterior”;
10. pendências reais.

```

---

## Observação importante

Se não existir modelo feminino PT-BR local disponível, deixe a arquitetura pronta para importar um modelo. Não invente que a voz é feminina. O objetivo é ter **um modelo bem feito**, não vários ruins.
```

Esse prompt já força a Kora para o que você quer: **presença real**, microfone sempre ativo, ativação por “Kora”, VAD com 1 segundo de silêncio, sinal sonoro, UX melhor e respostas melhores.

# Kryonix Refinement Deployment

## Objetivo

Registrar o refinamento atual do Kryonix/Kora e a aplicação nos hosts Inspiron e Glacier.

## Frentes trabalhadas

### Kora

- KoraMind como camada de resposta conversacional.
- Normalização pessoal do jeito do Ragton falar.
- Learning estruturado por usuário.
- Feedback/training dataset para SFT/DPO futuro.
- Benchmark de qualidade conversacional.
- Separação entre conversa casual e status técnico.
- Correção do caso: "bom então você está me ouvindo agora né".

### Voz

- STT local com limpeza de ANSI.
- Pipeline de voz passando por normalizer/correções.
- TTS local como padrão soberano.
- Edge/cloud TTS apenas com opt-in.
- VAD mantido como modo de interação local.

### Plataforma Kryonix

- GUI pausada.
- Foco em base declarativa sólida.
- Refinamento de flake, módulos, docs e identidade de plataforma.
- Kryonix tratado como plataforma/distro declarativa baseada no ecossistema NixOS, com UX própria via CLI `kryonix`.

## Gates obrigatórios

```bash
kora ask "bom então você está me ouvindo agora né"
```

Deve conter:

```txt
estou te ouvindo
```

Não pode conter:

```txt
STT
TTS
openWakeWord
modo de voz
Voice Activity Detection
transcrição
```

## Validações

```bash
python -m compileall packages/kora
bash -n packages/kryonix-cli/*.sh
nix build .#kora --no-link -L --show-trace
nix build .#kryonix --no-link -L --show-trace
nix build .#nixosConfigurations.inspiron.config.system.build.toplevel --no-link -L --show-trace
nix build .#nixosConfigurations.glacier.config.system.build.toplevel --no-link -L --show-trace
git diff --check
```

## Deploy

Inspiron:

```bash
kryonix switch all
```

Glacier:

```bash
ssh -p 2224 rocha@rve-glacier 'cd /etc/kryonix && git pull --rebase --recurse-submodules && kryonix switch all'
```

## Rollback

```bash
sudo nixos-rebuild switch --rollback
```

## Status

Pendente de validação runtime real em voz:

```bash
kora listen --vad
```

# Kryonix Deploy Report — 20260517-012936

## Escopo

Relatório automático de mudanças, validação, commit, push, pull remoto e aplicação de configuração nos hosts:

- Inspiron/local
- Glacier/remoto

## Decisão operacional

- GUI continua pausada.
- Foco atual:
  - KoraMind
  - learning/normalizer
  - training dataset
  - benchmark de qualidade
  - refinamento de plataforma Kryonix
  - documentação
  - estabilidade de flake/módulos

## Host local

```txt
Hostname: inspiron
User: rocha
Path: /etc/kryonix
Timestamp: 20260517-012936
```

## Git status inicial

```txt
A  docs/kora/KORA_REFINEMENT_AUDIT.md
A  docs/kora/LEARNING.md
A  docs/kora/TRAINING.md
A  docs/kora/architecture/KORA_JARVIS_BLUEPRINT.md
A  docs/kora/research/JARVIS_VIDEO_EXTRACTION.md
A  docs/operations/KRYONIX_REFINEMENT_DEPLOYMENT.md
 M modules/nixos/services/home-assistant/default.nix
M  modules/nixos/services/kora/default.nix
M  modules/nixos/services/kora/voice.nix
 M modules/nixos/services/n8n/default.nix
 M overlays/default.nix
 M packages/kora.nix
M  packages/kora/kora/cli.py
A  packages/kora/kora/core/answer_planner.py
A  packages/kora/kora/core/capabilities.py
M  packages/kora/kora/core/conversation.py
A  packages/kora/kora/core/learning.py
A  packages/kora/kora/core/normalizer.py
A  packages/kora/kora/core/operational.py
M  packages/kora/kora/core/orchestrator.py
A  packages/kora/kora/core/quality.py
A  packages/kora/kora/core/router.py
M  packages/kora/kora/core/users.py
A  packages/kora/kora/eval/quality_eval.py
A  packages/kora/kora/eval/scenarios.json
A  packages/kora/kora/eval/scenarios.yaml
A  packages/kora/kora/learning/__init__.py
A  packages/kora/kora/learning/corrections.py
A  packages/kora/kora/learning/daily.py
A  packages/kora/kora/learning/privacy.py
A  packages/kora/kora/learning/profile.py
A  packages/kora/kora/learning/store.py
A  packages/kora/kora/learning/style.py
M  packages/kora/kora/llm/system_prompt.md
A  packages/kora/kora/mind/__init__.py
A  packages/kora/kora/mind/context.py
A  packages/kora/kora/mind/dialogue_policy.py
A  packages/kora/kora/mind/mind.py
A  packages/kora/kora/mind/persona.py
A  packages/kora/kora/mind/reflection.py
A  packages/kora/kora/training/__init__.py
A  packages/kora/kora/training/store.py
M  packages/kora/kora/voice/config.py
M  packages/kora/kora/voice/daemon.py
M  packages/kora/kora/voice/models.py
M  packages/kora/kora/voice/pipeline.py
M  packages/kora/kora/voice/stt.py
M  packages/kora/kora/voice/tts.py
M  packages/kora/kora/voice/vad.py
M  packages/kora/kora/voice/voices.py
M  packages/kora/kora/voice/wakeword.py
M  packages/kora/pyproject.toml
A  packages/kora/test_vad_and_wakeword.py
A  packages/kora/test_wakeword.py
M  packages/kora/tests/test_identity_logic.py
A  packages/kora/tests/test_integration_learning.py
A  packages/kora/tests/test_learning.py
A  packages/kora/tests/test_operational.py
M  packages/kora/uv.lock
?? docs/operations/KRYONIX_DEPLOY_REPORT_20260517-012936.md
?? docs/operations/novo.md
```

## Arquivos modificados

```txt
M	modules/nixos/services/home-assistant/default.nix
M	modules/nixos/services/n8n/default.nix
M	overlays/default.nix
M	packages/kora.nix
```

## Estatística do diff

```txt
 modules/nixos/services/home-assistant/default.nix |  8 ++++----
 modules/nixos/services/n8n/default.nix            |  4 ++--
 overlays/default.nix                              |  2 ++
 packages/kora.nix                                 | 11 ++++++++++-
 4 files changed, 18 insertions(+), 7 deletions(-)
```

## Arquivos não rastreados

```txt
docs/operations/KRYONIX_DEPLOY_REPORT_20260517-012936.md
docs/operations/novo.md
```

## Submódulos

```txt
 2565bafecfd7f0ed7f90401c7a09dc94587e06b3 .ai/kryonix-vault (heads/main)
 1019666879028d5e2a08f481f5e1988a48583052 packages/kryonix-brain-lightrag (heads/main)
 a34c221752d8580c9e72de6ff29a2edad8fac805 packages/kryonix-home (heads/main)
```

## Validações planejadas

- `python -m compileall packages/kora`
- `bash -n packages/kryonix-cli/*.sh`
- `nix build .#kora --no-link -L --show-trace`
- `nix build .#kryonix --no-link -L --show-trace`
- `git diff --check`

## Deploy planejado

1. Commit local.
2. Push para origin.
3. `kryonix switch all` no Inspiron.
4. Pull no Glacier.
5. `kryonix switch all` no Glacier.
6. Validação de serviços principais.

## Rollback

Inspiron:

```bash
sudo nixos-rebuild switch --rollback
home-manager generations
```

Glacier:

```bash
ssh -p 2224 rocha@rve-glacier 'sudo nixos-rebuild switch --rollback'
```

## Observações

Este relatório foi gerado antes do commit final para documentar exatamente o estado auditado.

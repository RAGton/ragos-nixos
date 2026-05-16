# Kora Voice Identity — Política e Segurança

Este documento define as diretrizes para o uso de reconhecimento de voz na assistente Kora.

## 1. Princípios Fundamentais

1. **Privacidade**: O áudio bruto capturado para comandos não é salvo permanentemente por padrão. Arquivos temporários são excluídos após o processamento.
2. **Consentimento**: O cadastro de biometria de voz (voiceprint) exige consentimento explícito do usuário.
3. **Local-First**: Todo o processamento de STT (Speech-to-Text) e TTS (Text-to-Speech) é feito localmente no hardware do Kryonix (Glacier).
4. **Segurança Multinível**: A voz reconhecida é usada para **personalização**, não como fator único de autenticação para ações críticas.

## 2. Níveis de Autorização por Voz

| Identidade Detectada | Permissão de Conversa | Permissão de Comandos | Ações Admin |
|----------------------|-----------------------|-----------------------|-------------|
| **Ragton** (Confirmado) | Total | Read-only + Propostas | Exige Sudo/Confirmação |
| **Usuário Conhecido** | Limitada | Bloqueado | Bloqueado |
| **Desconhecido** | Geral (Público) | Bloqueado | Bloqueado |

## 3. Fluxo de Confirmação

Para ações de risco Médio ou Alto, mesmo que a voz seja reconhecida, a Kora deve:
1. Emitir uma proposta de ação visual/textual.
2. Pedir confirmação vocal ("Kora, confirmar").
3. Validar a intenção antes da execução.

## 4. Voiceprint e Dados Biométricos

- Os embeddings de voz são armazenados em `/var/lib/kryonix/kora/voice/profiles/`.
- O usuário pode excluir seu perfil de voz a qualquer momento via comando `kora voice identity delete`.
- Nenhum dado biométrico é enviado para nuvem.

## 5. Roadmap

- **V1**: Push-to-Talk + STT/TTS local (Atual).
- **V2**: Wake-word "Kora" (sempre ouvindo localmente).
- **V3**: Identificação de orador (Speaker ID) integrada ao Identity Router.
- **V4**: Autenticação vocal para ações de baixo risco (ex: luzes, música).

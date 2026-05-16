# Kora — Voice Identity & Enrollment

A identificação de voz na Kora está em estágio de **fundação**. Ela é projetada para personalização, não para autenticação forte.

## Princípios

1. **Privacidade Primeiro**: Áudio bruto nunca é salvo. Apenas embeddings anonimizados (voiceprints) são armazenados.
2. **Consentimento Obrigatório**: O cadastro (`kora voice enroll`) exige confirmação explícita do usuário.
3. **Limite de Segurança**: Ações críticas do sistema sempre exigem confirmação secundária ou autenticação via terminal, mesmo que a voz seja reconhecida.

## Estado de Desenvolvimento

- **Voice Enrollment**: Foundation. Coleta de metadados e consentimento implementada.
- **Speaker ID**: Pendente (Extração de embeddings e comparação biométrica).
- **Wake-word**: Target "Kora". Modelo customizado real pendente de validação (V2.6).

## Enrollment Workflow

1. Execute `kora voice identity enroll <user_id>`.
2. Revise a política de privacidade.
3. Confirme com `CONFIRMO`.
4. Grave 5 frases de exemplo.

## Voice Profiles

Armazenados em `/var/lib/kryonix/kora/voice/profiles/<user_id>.json`.

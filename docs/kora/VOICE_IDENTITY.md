# Kora Voice Identity Enrollment

A Kora implementa um sistema de identificação por voz projetado para **personalização segura**, sem abrir mão da segurança do sistema.

## Princípios de Design

1.  **Privacidade Primeiro**: Áudio bruto (.wav, .flac) não é salvo no servidor por padrão. Apenas as características matemáticas da voz (embeddings/voiceprints) são mantidas.
2.  **Transparência**: O cadastro de voz é explícito e exige o comando `CONFIRMO` após apresentar a política de privacidade.
3.  **Segurança em Camadas**: O reconhecimento de voz pela Kora altera o nível de confiança (Trust Level) para a sessão, mas **NÃO AUTORIZA** comandos críticos (ex: `systemctl stop`, `kryonix switch`). Comandos de alto risco continuam exigindo autenticação local via `polkit`/`sudo` do usuário Linux subjacente.
4.  **Local Only**: Nenhum áudio ou embedding é enviado para nuvem. Tudo roda localmente no Glacier.

## Como Cadastrar

Para cadastrar sua voz, utilize o comando de *enrollment* guiado. Você deve ser um usuário previamente cadastrado no Kora User Registry.

```bash
kryonix kora voice identity enroll <seu_user_id>
```

Exemplo para o usuário principal:
```bash
kryonix kora voice identity enroll ragton
```

A Kora irá:
1.  Apresentar as regras de privacidade.
2.  Solicitar que você digite `CONFIRMO`.
3.  Pedir que você fale 5 frases curtas (pressione ENTER quando for falar).
4.  Extrair e salvar seu perfil de voz localmente em `/var/lib/kryonix/kora/voice/profiles/`.

## Debug e Retenção de Áudio

Para fins de depuração ou caso você queira salvar os áudios gravados durante o *enrollment*, execute o comando com a variável de ambiente:

```bash
KORA_VOICE_SAVE_AUDIO=1 kryonix kora voice identity enroll ragton
```

## Como a Identificação Funciona

Quando o daemon de voz da Kora está ativo (`kryonix kora voice daemon start`), ele escuta continuamente:

1.  Se o wake-word for detectado, o áudio é gravado.
2.  O áudio transcrito é repassado ao `VoiceIdentityManager`.
3.  Se um *speaker embedding* for extraído com confiança, a Kora saúda o usuário pelo nome.
4.  Se a confiança for baixa, o usuário é tratado como "Visitante", com restrições de segurança aplicadas.

## Status da Fundação (V2.5)

Atualmente, o sistema de `Voice Identity` está em modo **Foundation**.
Os perfis são criados, e o fluxo guiado está completo, mas a extração real de *embeddings biométricos* será habilitada na versão V3.0. A autorização de comandos por voz continua desabilitada.

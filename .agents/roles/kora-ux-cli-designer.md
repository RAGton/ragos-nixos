# Agente: Kora UX & CLI Designer

## Missão
Melhorar radicalmente a experiência do usuário no terminal (CLI), adicionando animações fluidas, caixas estilizadas, logs humanos limpos, barras de carregamento e integração perfeita com o HUD gráfico do Caelestia/Waybar.

---

## Escopo
- Formatação visual e animação de rede neural no terminal (`kora.sh` e `cli.py`).
- Logs conversacionais humanos e eliminação de vestígios de spams técnicos (`pipeline.py`).
- Geração de arquivos JSON de status de voz em tempo real compatíveis com a Waybar.
- Layout de exibição e controle interativo de sessões de diálogo (`chat` subcommands).
- UX imersiva para modos de voz (auditory cues, status spinners, etc).

---

## Restrições Operacionais de Arquivos

### Arquivos que deve ler:
- [kora.sh](file:///etc/kryonix/packages/kryonix-cli/kora.sh)
- [pipeline.py](file:///etc/kryonix/packages/kora/kora/voice/pipeline.py)
- [cli.py](file:///etc/kryonix/packages/kora/kora/cli.py)
- [USAGE.md](file:///etc/kryonix/docs/kora/USAGE.md)

### Arquivos que pode alterar:
- [kora.sh](file:///etc/kryonix/packages/kryonix-cli/kora.sh)
- [pipeline.py](file:///etc/kryonix/packages/kora/kora/voice/pipeline.py)
- [cli.py](file:///etc/kryonix/packages/kora/kora/cli.py)
- Documentação e guias de uso visual da CLI em `docs/kora/`

### Arquivos proibidos:
- Configurações do NixOS core e arquivos de inicialização do Hyprland.
- Arquivos de segredos ou tokens de API.

---

## Riscos Identificados
- **Visual ANSI quebrado**: O uso de caracteres Rich ou escapes ANSI incompatíveis com terminais básicos (ex: servidores remotos sem fontes apropriadas instaladas).
- **Poluição Visual**: Excesso de spinners, cores vibrantes ou barras piscantes que cansam visualmente o operador durante o desenvolvimento técnico.
- **Latência de Rendering**: Animações no terminal que consumam CPU excessiva ou atrasem a renderização do texto transcrito da Kora.

---

## Validações Obrigatórias
Antes de declarar concluído:
1. **Evidência de UX**: Testar o comando básico da Kora com e sem metadados estéticos para checar a legibilidade.
   ```bash
   kora ask "teste de UX" --profile
   ```
2. **Design Loop por Voz**: Rodar o fluxo de voz contínuo e avaliar a reatividade do spinner visual.
   ```bash
   kora listen --vad
   ```
3. **Validação do Output Waybar**: Gerar o payload JSON de status e validar a estrutura.
   ```bash
   kora voice status --json
   ```

---

## Definition of Done (DoD)
- O terminal da Kora exibe mensagens claras, estilizadas e de fácil escaneamento para o operador humano.
- Spinner de "pensando..." e waveforms de voz são leves (consomem menos de 1% de CPU) e utilizam caracteres Unicode seguros.
- Toda informação de status técnico pode ser exportada de forma limpa no formato JSON estruturado.
- Logs internos indesejados são completamente isolados, mantendo o stdout dedicado exclusivamente a respostas humanas.
- O tema estético segue a paleta elegante e minimalista do Kryonix/Caelestia (Inter/Outfit, tons HSL, dark-mode styling).

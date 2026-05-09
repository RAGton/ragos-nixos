# Kryonix Home Brain — Runbook de Operações Diárias

Este documento fornece instruções práticas para executar, depurar e reverter o processo de organização declarativo do Kryonix Home Brain.

---

## 1. Rotina de Triagem Recomendada

A organização de arquivos pessoais deve ser feita periodicamente (ex: semanalmente) seguindo o seguinte protocolo de três etapas:

### Passo A — Varredura e Identificação (Scan)
Varra e identifique novos arquivos e duplicatas na sua pasta de Downloads:

```bash
kryonix home scan
kryonix home report
```

### Passo B — Simulação e Auditoria (Plan & Explain)
Simule e examine as propostas geradas. Use a flag `--why` para obter a justificativa técnica de cada decisão:

```bash
kryonix home plan --taxonomy-suggestions --rename-suggestions --why
```

Se tiver dúvida sobre a classificação de um arquivo específico, use o comando `explain`:

```bash
kryonix home explain Downloads/comprovante_pix_banco.pdf
```

### Passo C — Geração do Manifesto e Aplicação (Manifest & Apply)
Crie o manifesto JSON com base nas sugestões auditadas, simule a escrita em dry-run e aplique as ações fisicamente:

```bash
# 1. Gerar o manifesto físico
kryonix home manifest create --taxonomy-suggestions --rename-suggestions

# 2. Exibir o manifesto estruturado
kryonix home manifest show

# 3. Simular e validar dry-run de movimentação
kryonix home apply --dry-run

# 4. Confirmar e executar a reorganização física
kryonix home apply --confirm
```

---

## 2. Lidando com Casos de Auditoria

Durante a auditoria visual do manifesto com `kryonix home manifest show` ou no planejamento com `--why`, você se deparará com classificações especiais. Veja como agir em cada uma:

### 2.1. Conflitos (`inbox.conflitos`)
- **O que significa**: O arquivo deu match em duas categorias com o mesmo score exato (ex: `comprovante_estudo_trabalho.pdf`).
- **Onde ele vai**: `Documentos/00_Inbox/Conflitos/`
- **Ação**: O arquivo é movido com segurança para a pasta de conflitos para que você possa movê-lo manualmente para o local final correto depois.

### 2.2. Baixa Confiança (`Documentos/00_Inbox/Baixa_Confianca`)
- **O que significa**: O arquivo deu match em uma categoria com score muito baixo (abaixo de `0.45`), indicando que a palavra-chave encontrada pode ser apenas ruído.
- **Onde ele vai**: `Documentos/00_Inbox/Baixa_Confianca/`
- **Ação**: Deixe o motor movê-lo para a pasta de baixa confiança. Periodicamente, abra essa pasta e mova os arquivos para seus locais definitivos.

### 2.3. Destino Existente (`destination_exists` / `skipped`)
- **O que significa**: O planejador propôs mover um arquivo, mas a pasta de destino já possui um arquivo com o mesmo nome.
- **Caso A (Mesmo SHA-256)**: O sistema de auditoria marcará como `skipped` (pulado). Nenhuma ação física é necessária. Você pode apagar com segurança o arquivo duplicado que ficou no diretório de Downloads, pois ele já está devidamente organizado no destino.
- **Caso B (SHA-256 diferente)**: O sistema marcará como `blocked` (bloqueado). O arquivo permanece intacto no Downloads para evitar sobrescrever dados diferentes. Abra os dois arquivos e ajuste o nome de um deles para resolver a colisão antes de rodar o apply novamente.

---

## 3. Recuperação de Desastre e Reversão (Rollback)

Se você executou `apply --confirm` e se arrependeu ou percebeu que alguns arquivos foram parar em locais incorretos:

```bash
kryonix home rollback
```

### Como funciona:
O motor lê o arquivo JSON de transação ativa `~/.local/state/kryonix/home-brain/active_transaction.json`, que registra os pares exatos `(antigo_caminho, novo_caminho)` que foram aplicados fisicamente em disco. O rollback move todos esses arquivos em sentido inverso, restaurando inclusive os nomes originais sujos.

Após o rollback, o sistema volta a ficar no estado rigorosamente idêntico ao estado anterior ao apply.

---

## 4. O que NUNCA fazer

> [!CAUTION]
> **PROIBIÇÕES ABSOLUTAS DE OPERAÇÃO**
>
> 1. **NUNCA tente mover ou apagar arquivos de configuração ou diretórios ocultos** (como `.config`, `.local`, `.ssh`) utilizando o motor. O planejador foi projetado com travas para ignorá-los, mas evite burlar esse isolamento.
> 2. **NUNCA altere arquivos de estado JSON manualmente** (como `active_transaction.json`) a menos que seja um sysadmin sênior depurando uma falha extrema, pois isso quebrará a integridade do rollback.
> 3. **NUNCA execute `apply --confirm` sem revisar o manifesto previamente** através de `kryonix home manifest show` ou `apply --dry-run`.
> 4. **NUNCA force movimentações em pastas com privilégios administrativos** (`/root`, `/etc`, etc.) através da CLI de usuário comum.

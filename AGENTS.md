# AGENTS.md — RagOS VE / Codex

## Objetivo

Este arquivo orienta agentes de código que atuem no repositório do **RagOS VE**.
A prioridade do projeto hoje é **consolidação arquitetural, maturidade operacional e coerência documental**.
Agentes devem preferir mudanças pequenas, reversíveis e alinhadas ao estado real do código.

---

## Contexto do projeto

- O projeto é uma flake NixOS pessoal para **workstation, gaming, virtualização, estudo e desenvolvimento**.
- O desktop real do projeto é **Hyprland**.
- O shell/UX do desktop está em **transição**:
  - **DMS está sendo removido**.
  - **Celestial Shell é a direção de substituição**.
- O namespace público já existente é `rag.*`.
- A CLI `ragos` é o **entrypoint operacional padrão**.
- O host principal atual é **`glacier`**.
- O repositório já possui `hosts/`, `hosts/common/`, `features/`, `profiles/`, `modules/nixos/**`, `desktop/hyprland/**` e `home/**`.
- O projeto já passou da fase de “proposta de arquitetura” e está em fase de **limpeza, consolidação e coerência**.

---

## Fonte de verdade

Quando houver conflito entre documentação e código:

1. **Código atual vence**.
2. `docs/CURRENT_STATE.md` é a referência documental principal.
3. `docs/ROADMAP.md` orienta a direção futura.
4. `docs/OPERATIONS.md` descreve o fluxo operacional vigente.
5. Docs antigas divergentes devem ser tratadas como **históricas**, não como especificação ativa.

Nunca continue um refactor grande com base apenas em relatórios antigos de migração.

## Ordem de contexto para agentes

Para reduzir ruído e token desnecessário, siga esta ordem:

1. `AGENTS.md`
2. `context/INDEX.md`
3. skill relevante em `skills/**`
4. código real do repositório
5. web oficial apenas quando necessário

Use `context/` como porta de entrada curta e indexada.
Considere `ai/` como material histórico/experimental, não como camada principal nova.

---

## Direção arquitetural obrigatória

Trate estas decisões como atuais e preferenciais:

- **desktop** = `rag.desktop.environment`
- **rice / shell / theming** = `rag.rice.*`
- **feature** = `rag.features.*`
- **Hyprland é o desktop real atual**.
- **DMS não é desktop separado**.
- **DMS está em descontinuação dentro do projeto**.
- **Celestial Shell é o substituto planejado para a camada de shell/rice**.
- O foco é reduzir ambiguidade entre desktop, rice e feature.

### Regra de transição DMS → Celestial Shell

- Não introduzir novos acoplamentos a DMS.
- Não criar novos módulos, wrappers, scripts ou docs que consolidem DMS como caminho futuro.
- Se houver código DMS ainda ativo, trate como **legado de transição**.
- Mudanças novas devem preferir:
  - abstrações neutras de shell/rice, ou
  - integração já pensada para **Celestial Shell**.
- Só tocar em DMS para:
  - correção mínima,
  - compatibilidade temporária,
  - remoção controlada,
  - migração para Celestial Shell.

Se encontrar lógica que trate `dms` como desktop independente, considere isso dívida de migração e trate com cautela.

---

## Prioridades atuais

Quando várias direções forem possíveis, priorize nesta ordem:

1. **Alinhar documentação ao estado real do código**
2. **Simplificar a modelagem desktop / shell / rice / features**
3. **Preparar e consolidar a transição de DMS para Celestial Shell**
4. **Reduzir duplicação no stack Hyprland**
5. **Quebrar módulos grandes por responsabilidade**
6. **Melhorar energia/idle do notebook principal sem auto-lock/auto-suspend indesejado**
7. **Refinar `glacier` como workstation principal**
8. **Fortalecer a CLI `ragos` como interface operacional**

Não abra frentes novas de produto se ainda houver contradição documental ou duplicação estrutural no que já existe.

---

## Restrições operacionais críticas

### `glacier`

`glacier` é o host principal para workstation, gaming e virtualização.
No host já instalado:

- a fonte de verdade é `hosts/glacier/hardware-configuration.nix`
- **não** usar destrutivamente:
  - `hosts/glacier/disks.nix`
  - `disko`
  - `format-*`
  - `install-system`
- o storage operacional de virtualização fica em `/srv/ragenterprise`

Mudanças em `glacier` devem ser seguras, incrementais e orientadas ao host já existente.

### CLI `ragos`

A CLI `ragos` é o fluxo preferencial do dia a dia.
Ao melhorar operação, prefira integrar com:

- `nh`
- `nix`
- `nvd`
- resolução de flake existente (`explicit`, `env`, `dev-repo`, `etc-ragos`)

Evite reinventar fluxos já cobertos por `ragos`, `nh` ou comandos padrão do NixOS.

### Escopo

Não ampliar escopo sem necessidade clara.
Exemplos do que **não** deve entrar num patch “pequeno” sem justificativa forte:

- branding novo
- automação grande de VM
- novos modos de uso
- refactor massivo de docs históricas
- redesign de arquitetura sem validação do código atual
- mudanças em `flake.lock` sem necessidade real

---

## Estilo de código

### Tamanho e responsabilidade

- Funções: **4–20 linhas**. Divida se passar disso.
- Arquivos: **menos de 500 linhas**. Separe por responsabilidade.
- Uma função = uma responsabilidade.
- Um módulo = um assunto coeso.
- Prefira módulos pequenos e previsíveis a arquivos “god object”.

### Nomes

- Use nomes **específicos, únicos e grepáveis**.
- Evite nomes vagos como `data`, `utils`, `handler`, `manager`, `misc`, `common2`.
- Prefira nomes que gerem poucas ocorrências na base.
- Em Nix, nomeie módulos pelo que realmente configuram, não pelo efeito colateral.

### Tipagem e interfaces

- Tipos explícitos quando a linguagem suportar.
- Não use `any`, `Dict`, funções sem tipo ou payloads ambíguos.
- Dependências devem entrar por parâmetro/construtor, não por acoplamento global.
- Bibliotecas externas devem ficar atrás de interface fina pertencente ao projeto.

### Fluxo de controle

- Prefira **early return** em vez de `if` aninhado.
- Máximo de **2 níveis de indentação**.
- Mensagens de erro devem incluir:
  - o valor ofensivo
  - o formato esperado

Exemplo de mensagem boa:

```text
invalid host value 'glacir'; expected one of ['glacier', 'inspiron', 'inspiron-nina', 'iso']
```

### Duplicação

- Não repetir wrappers, helpers ou blocos de configuração.
- Se aparecer a mesma ideia em system-level e user-level, extraia para ponto único quando seguro.
- Antes de criar novo helper, procure se já existe equivalente no stack Hyprland, `features/`, `profiles/` ou scripts do projeto.
- Durante a migração DMS → Celestial Shell, não duplique lógica de shell em dois caminhos permanentes.

---

## Comentários e documentação inline

- Preserve comentários existentes; não remova intenção histórica sem motivo.
- Comentários devem explicar **por que**, não **o que**.
- Funções públicas devem ter docstring curta com:
  - intenção
  - um exemplo de uso
- Quando uma linha existir por bug, limitação upstream ou compatibilidade, referencie issue, commit SHA ou contexto técnico.
- Se uma mudança altera arquitetura, atualize a documentação mínima correspondente no mesmo patch.
- Quando um trecho existir apenas por compatibilidade com DMS legado, documente isso explicitamente.

---

## Regras específicas para Nix e arquitetura do repo

### Estrutura preferida

Siga a convenção já materializada no projeto:

- `hosts/` = hardware, boot, papel por máquina
- `hosts/common/` = agregação compartilhada
- `features/` = capacidades opt-in
- `profiles/` = combinações reutilizáveis por papel
- `desktop/hyprland/` = stack desktop atual
- `modules/nixos/**` = base, serviços, rede, áudio, theming
- `home/` = entrada Home Manager por usuário/host

Não mova arquivos entre camadas sem motivo arquitetural claro.

### Regras de modelagem

- Host não deve concentrar lógica interna de feature.
- `profiles/` compõem; `features/` habilitam capacidade; `modules/` implementam base.
- Não introduza nova abstração se um `profile`, `feature` ou módulo já resolve.
- Não reabrir a fantasia de multi-desktop “pleno” sem base concreta no código.
- Se o código real suportar apenas `hyprland` e `null`, não documente o projeto como multi-DE maduro.
- Shell/rice deve ser modelado para permitir a substituição de DMS por Celestial Shell sem espalhar acoplamento.

### Home Manager

- Evite manter import direto demais de `desktop/hyprland/user.nix` em cada home quando houver caminho mais declarativo.
- Se mexer em Home Manager, procure reduzir acoplamento ao stack desktop interno.
- O objetivo é deixar o lado user-level mais declarativo, sem esconder estado real do projeto.
- Toda mudança nova de shell/rice deve partir da premissa de **Celestial Shell como direção**, não de DMS como futuro.

---

## Testes e validação

Toda mudança precisa ser validada no menor escopo possível.

### Regras gerais

- Toda função nova recebe teste.
- Bug fix recebe teste de regressão.
- I/O externo deve ser mockado com **fake classes nomeadas**, não stubs inline.
- Testes devem ser F.I.R.S.T.

### Validação mínima no repositório

Sempre que aplicável, rode a menor sequência útil:

```bash
nix fmt
nix flake check --keep-going
```

Se a mudança tocar host, desktop, feature, profile ou flake:

```bash
nix flake show
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nix build .#homeConfigurations.<user>@<host>.activationPackage
```

Se a mudança for operacional e a CLI estiver disponível:

```bash
ragos fmt
ragos check
ragos doctor
```

### Regra de honestidade

Separe sempre:

- erro novo introduzido pelo patch
- erro antigo já presente no workspace
- falha causada por árvore suja/local

Nunca declare “quebrado” algo que já estava falhando antes sem deixar isso explícito.

---

## Fluxo recomendado para mudanças

### Para mudanças pequenas

1. localizar o ponto mínimo de alteração
2. confirmar estado real do código
3. aplicar patch pequeno e coeso
4. validar apenas o necessário
5. atualizar docs mínimas se a mudança alterar comportamento público

### Para refactor

1. mapear duplicação ou responsabilidade difusa
2. preservar comportamento
3. dividir por etapas pequenas
4. validar a cada etapa
5. evitar refactor cosmético junto com mudança funcional

### Para migração de shell

1. identificar acoplamentos atuais com DMS
2. isolar contratos neutros de shell/rice
3. migrar integração para Celestial Shell em passos pequenos
4. manter compatibilidade temporária só quando necessário
5. remover resíduos de DMS assim que houver caminho validado

### Para documentação

1. verificar o código primeiro
2. atualizar `docs/CURRENT_STATE.md` ou docs operacionais relevantes
3. rebaixar conteúdo antigo para histórico quando necessário
4. não propagar claims de arquitetura que o código não entrega
5. não descrever DMS como direção futura

---

## Logging e saída CLI

- Logging técnico/observabilidade: **JSON estruturado**
- Saída para usuário em CLI: **texto plano**
- Não misturar diagnóstico interno verboso com UX do comando principal
- Em comandos operacionais, mostrar status claro: `OK`, `ATENÇÃO`, `ERRO`

---

## O que um agente deve evitar

- reescrever comentários históricos úteis
- inventar abstração para “generalizar” algo que hoje é Hyprland-first
- tratar docs antigas como verdade sem checar o código
- tocar em arquivos destrutivos do `glacier`
- abrir mudanças amplas de branding em patch técnico
- duplicar wrapper/helper já existente
- confundir DMS com desktop separado
- reintroduzir DMS como caminho oficial novo
- adicionar integração nova amarrada a DMS sem necessidade de transição
- fazer refactor massivo sem checkpoints validáveis

---

## O que um agente deve entregar

Ao fim de uma tarefa, entregue sempre:

1. **status objetivo**
2. **arquivos alterados**
3. **o que mudou**
4. **como validar**
5. **limitações / pendências**
6. **distinção entre erro novo e erro antigo**, se houver

Para tarefas maiores, preferir commits curtos e objetivos.

---

## Exemplos de orientação correta

### Bom pedido para agente

> Implemente apenas `ragos doctor`, `ragos snapshot`, `ragos generations` e `ragos rollback`, sem mexer em branding, VMs ou `flake.lock`.

### Bom pedido de migração de shell

> Remova acoplamentos novos a DMS e prepare a camada de shell para Celestial Shell, sem reescrever a arquitetura inteira do desktop.

### Má direção

> Aproveita e já reorganiza toda a arquitetura de desktop, limpa docs antigas, troca branding e adiciona automação de ISO.

---

## Regra final

Neste projeto, a melhor mudança normalmente é:

- pequena
- explícita
- reversível
- validada
- coerente com o código atual
- alinhada ao RagOS VE como plataforma pessoal declarativa de uso real

Quando em dúvida, escolha a opção que **reduz contradição**, **reduz duplicação**, **facilita a remoção do DMS** e **aumenta previsibilidade operacional**.

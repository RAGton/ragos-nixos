# ❄️ Kryonix

<p align="center">
  <img src=".github/assets/kryonix-hero.png" alt="Kryonix — plataforma NixOS declarativa" width="100%" />
</p>

<p align="center">
  <strong>Plataforma NixOS declarativa para workstation, gaming, virtualização, estudo e desenvolvimento.</strong>
</p>

<p align="center">
  <a href="README-en.md">English</a>
  ·
  <a href="docs/INDEX.md">Documentação</a>
  ·
  <a href="docs/OPERATIONS.md">Operação diária</a>
  ·
  <a href="docs/GLACIER.md">Host Glacier</a>
</p>

<p align="center">
  <img alt="NixOS" src="https://img.shields.io/badge/NixOS-declarativo-5277C3?style=for-the-badge" />
  <img alt="Status" src="https://img.shields.io/badge/status-em%20evolu%C3%A7%C3%A3o-00BFFF?style=for-the-badge" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-7C3AED?style=for-the-badge" />
  <img alt="CLI" src="https://img.shields.io/badge/CLI-kryonix-06B6D4?style=for-the-badge" />
</p>

<p align="center">
  <img
    src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=600&size=22&pause=900&color=38BDF8&center=true&vCenter=true&width=900&lines=NixOS+declarativo+para+uso+real;Workstation+%E2%80%A2+Gaming+%E2%80%A2+Virtualiza%C3%A7%C3%A3o;IA+local+%E2%80%A2+Brain+%E2%80%A2+Ollama+%E2%80%A2+LightRAG;Glacier+como+laborat%C3%B3rio+do+Kryonix"
    alt="Kryonix animated typing"
  />
</p>

---

## Visão geral

**Kryonix** não é apenas uma coleção de dotfiles. É uma plataforma NixOS declarativa para uso real, construída para transformar máquinas pessoais em ambientes reprodutíveis, consistentes e prontos para trabalho pesado.

O projeto integra configuração de sistema, Home Manager, branding, virtualização, fluxo operacional via CLI e uma base de IA local com **Ollama**, **LightRAG** e **Kryonix Brain API**.

<p align="center">
  <img src=".github/assets/kryonix-overview.png" alt="Visão geral do ecossistema Kryonix" width="100%" />
</p>

---

## O que o Kryonix entrega

| Área | Objetivo |
| --- | --- |
| 🖥️ **Workstation** | Ambiente principal estável, produtivo e pronto para desenvolvimento diário. |
| 🎮 **Gaming** | Base otimizada para jogos, baixa latência e uso com hardware moderno. |
| 🧊 **Glacier** | Host principal AMD + NVIDIA, laboratório real do Kryonix e máquina de produção pessoal. |
| 🧱 **Virtualização** | KVM/libvirt, storage operacional e estrutura para VMs, ISOs, templates e backups. |
| 🧠 **IA local / Brain** | Serviços locais com Ollama, LightRAG e API própria para automação e conhecimento. |
| 🎨 **Branding** | Identidade Kryonix aplicada em boot, login, wallpaper e metadados do sistema. |
| 🧰 **CLI operacional** | Comando `kryonix` para reduzir atrito em rebuilds, checks, diffs e manutenção. |
| 💿 **ISO futura** | Base para gerar imagens instaláveis e evoluir para uma distro pessoal. |

---

## Estado atual do flake

O flake publica:

```text
nixosConfigurations
├── inspiron
├── inspiron-nina
├── glacier
└── iso

homeConfigurations
├── rocha@inspiron
├── rocha@glacier
└── nina@inspiron-nina

packages
├── kryonix
└── ragos
```

Também inclui:

- overlays reutilizáveis;
- formatter;
- checks;
- pacotes `kryonix` e `ragos` compat;
- documentação operacional;
- base de serviços para IA local no `glacier`.

---

## Fluxo diário

O fluxo operacional padrão é a CLI **`kryonix`**, instalada no `PATH` do sistema.

> A CLI antiga `ragos` permanece temporariamente como compatibilidade e emite:
>
> ```text
> ragos is deprecated, use kryonix
> ```

### Comandos principais

```sh
kryonix switch
kryonix switch --update
kryonix boot --update
kryonix home
kryonix diff
kryonix doctor
kryonix check
kryonix fmt
kryonix iso
```

### Aplicar o host atual

```sh
kryonix switch
```

### Aplicar um host específico

```sh
kryonix switch --host glacier
```

### Inspecionar o flake

```sh
nix flake show --all-systems
nix flake check --keep-going
```

---

## Quick start

Clone o projeto já com o naming novo:

```sh
git clone https://github.com/RAGton/kryonix kryonix
cd kryonix
```

Atualize as entradas do flake quando necessário:

```sh
nix flake update
```

Rode validações antes de aplicar mudanças maiores:

```sh
kryonix fmt
kryonix check
kryonix doctor
```

Aplique a configuração:

```sh
kryonix switch
```

---

## Glacier

O **`glacier`** é o host principal de produto neste momento.

Ele é tratado como:

- workstation AMD + NVIDIA;
- host gamer;
- host de VMs;
- laboratório do próprio Kryonix;
- máquina principal para evoluir IA local e automações.

### Storage operacional

O `glacier` mantém storage operacional para virtualização em:

```text
/srv/ragenterprise
├── images
├── iso
├── templates
├── snippets
└── backups
```

### Observação crítica de storage

O `hardware-configuration.nix` restaurado é a fonte real de boot, root e home do host instalado.

> [!WARNING]
> Não use `disko`, `format-*` ou `install-system` no `glacier` já instalado.
>
> O arquivo `hosts/glacier/disks.nix` deve ser tratado como provisionamento futuro, não como verdade destrutiva do hardware atual.

---

## IA local e Kryonix Brain

O `glacier` conta com serviços nativos de Inteligência Artificial local:

- **Ollama**
- **LightRAG**
- **Kryonix Brain API**

Antes de ativar a infraestrutura pela primeira vez, gere uma chave de segurança para acesso à API.

### 1. Gerar chave segura

```sh
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### 2. Criar o arquivo de ambiente

Crie ou injete as variáveis em:

```text
/etc/kryonix/brain.env
```

Conteúdo esperado:

```sh
KRYONIX_BRAIN_KEY="<chave_gerada_aqui>"
LIGHTRAG_VERBOSE="1"
```

> [!IMPORTANT]
> Esse arquivo fica fora do controle de versão.
>
> Se `/etc/kryonix/brain.env` não existir, o Systemd deve recusar a subida das units `kryonix-brain-api` e `kryonix-lightrag` durante o `kryonix switch`.

## Estado atual do Kryonix

- CLI modularizada em `packages/kryonix-cli/`.
- Brain API roda no Glacier e o Inspiron consulta remoto por padrão.
- CAG remoto ativo via `/cag/status`, `/cag/route` e `/cag/ask`.
- GraphRAG Fase 4 controlado ativo via:
  - `/graph/status`
  - `/graph/schema`
  - `/graph/ingest/dry-run`
  - `/graph/doctor`
- Credencial Neo4j na Brain API é injetada por `systemd EnvironmentFile`; o Python não lê secret direto em arquivo.
- Secrets locais:
  - `/etc/kryonix/brain.env`
  - `/etc/kryonix/neo4j.env`
- Paths canônicos:
  - Brain storage: `/var/lib/kryonix/brain/storage`
  - CAG: `/var/lib/kryonix/brain/cag`
  - Neo4j: `/var/lib/kryonix/brain/neo4j`
- Inspiron não deve duplicar índice pesado local sem habilitação explícita.

Status atual:
- GraphRAG Fase 4: `FUNCTIONAL` para `status/schema/ingest --dry-run/doctor`.

---

## Branding

O produto é apresentado publicamente como **Kryonix**.

A identidade visual já é aplicada em:

- Plymouth;
- GRUB;
- GDM;
- wallpaper do desktop;
- `/etc/os-release`;
- `/etc/issue`.

O nome antigo permanece apenas como compatibilidade temporária de CLI, opções e caminhos.

---

## Estrutura recomendada do repositório

```text
kryonix
├── docs/                  # Documentação operacional e arquitetura
├── features/              # Módulos/funções de alto nível
├── hosts/                 # Configuração por host
│   ├── glacier/
│   ├── inspiron/
│   └── inspiron-nina/
├── home/                  # Home Manager por usuário/host
├── modules/               # Módulos Nix reutilizáveis
├── overlays/              # Overlays de pacotes
├── packages/              # Pacotes e serviços próprios
├── profiles/              # Perfis reutilizáveis
├── skills/                # Conhecimento operacional/automação
├── flake.nix
├── Makefile
├── README.md
└── README-en.md
```

---

## Documentação

| Documento | Descrição |
| --- | --- |
| [`docs/INDEX.md`](docs/INDEX.md) | Índice central da documentação. |
| [`docs/OPERATIONS.md`](docs/OPERATIONS.md) | Operação diária e uso da CLI. |
| [`docs/GLACIER.md`](docs/GLACIER.md) | Papel do host `glacier`. |
| [`docs/operations/KRYONIX_COMMANDS_CANONICAL.md`](docs/operations/KRYONIX_COMMANDS_CANONICAL.md) | Comandos canônicos validados. |
| [`docs/operations/KRYONIX_RUNTIME_MATRIX.md`](docs/operations/KRYONIX_RUNTIME_MATRIX.md) | Matriz de runtime Inspiron/Glacier. |
| [`docs/operations/KRYONIX_VALIDATION.md`](docs/operations/KRYONIX_VALIDATION.md) | Checklist de validação operacional. |
| [`docs/operations/KRYONIX_REVIEW_WALKTHROUGH.md`](docs/operations/KRYONIX_REVIEW_WALKTHROUGH.md) | Walkthrough de revisão canônica. |
| [`docs/brain/GRAPH_RAG_ARCHITECTURE.md`](docs/brain/GRAPH_RAG_ARCHITECTURE.md) | Arquitetura do GraphRAG controlado. |
| [`docs/brain/NEO4J_SCHEMA.md`](docs/brain/NEO4J_SCHEMA.md) | Schema V1 e contratos do grafo. |
| [`docs/operations/NEO4J_TROUBLESHOOTING.md`](docs/operations/NEO4J_TROUBLESHOOTING.md) | Operação e troubleshooting do Neo4j. |

---

## Vault de conhecimento

O Kryonix também possui um vault de conhecimento separado:

```text
https://github.com/RAGton/kryonix-vault.git
```

Esse vault é a base para documentação, memória operacional, estudos, anotações e evolução futura do **Kryonix Brain**.

---

## Roadmap

- [x] Padronizar branding público como **Kryonix**.
- [x] Manter `ragos` apenas como compatibilidade temporária.
- [x] Consolidar CLI operacional `kryonix`.
- [x] Publicar hosts `inspiron`, `inspiron-nina`, `glacier` e `iso`.
- [x] Documentar operação diária e validação.
- [x] Ativar base de IA local no `glacier`.
- [ ] Refinar ISO instalável do Kryonix.
- [ ] Evoluir o Brain com GraphRAG, memória auditável e automações.
- [ ] Criar dashboard visual do estado do sistema.
- [ ] Automatizar curadoria segura do vault.
- [ ] Transformar o `glacier` em referência canônica de produto.

---

## Galeria / assets visuais

Para deixar o README mais atrativo, use estes caminhos no repositório:

```text
.github/assets/kryonix-hero.png
.github/assets/kryonix-overview.png
.github/assets/kryonix-demo.gif
.github/assets/kryonix-terminal.svg
```

Sugestão:

- `kryonix-hero.png`: banner principal.
- `kryonix-overview.png`: cards de funcionalidades.
- `kryonix-demo.gif`: animação curta mostrando `kryonix doctor`, `kryonix switch`, `kryonix diff`.
- `kryonix-terminal.svg`: terminal animado leve para não pesar o README.

Exemplo de bloco para demo:

```md
<p align="center">
  <img src=".github/assets/kryonix-demo.gif" alt="Demo da CLI Kryonix" width="900" />
</p>
```

---

## Segurança operacional

Antes de mudanças de maior risco, prefira:

```sh
kryonix test
kryonix boot
kryonix check
kryonix doctor
```

Evite ações destrutivas no host instalado:

```text
disko
format-*
install-system
```

> [!CAUTION]
> O `glacier` é uma máquina real de produção pessoal. Mudanças de disco, bootloader, mounts e GPU devem ser testadas com cuidado.

---

## Licença

MIT. Veja [`LICENSE`](LICENSE).

---

<p align="center">
  <strong>Kryonix</strong> — sistema declarativo, reproduzível e inteligente para uso real.
</p>

<p align="center">
  ❄️ NixOS · 🧠 IA local · 🎮 Gaming · 🧱 Virtualização · 🖥️ Workstation
</p>

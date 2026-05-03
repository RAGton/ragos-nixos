# AGENTS.md — Kryonix Canonical Agent Guide

> Documento canônico para agentes humanos e IA trabalhando no repositório **Kryonix**.
>
> Objetivo: garantir alterações pequenas, seguras, testáveis e fiéis ao código real, sem quebrar NixOS, Brain, LightRAG, MCP, Glacier, Inspiron, Hyprland/Caelestia, Tailscale, GPU, storage ou documentação.

---

## 0. Mandato principal

Você está trabalhando no repositório **Kryonix**, uma plataforma NixOS declarativa para:

- workstation Linux;
- gaming workstation;
- virtualização;
- IA local;
- servidor pessoal/datacenter doméstico;
- Brain/RAG técnico;
- Home Manager;
- flakes;
- módulos NixOS;
- overlays;
- pacotes;
- futura ISO instalável;
- operação diária por CLI `kryonix`.

O repositório é a **fonte de verdade operacional**. Documentação antiga, notas do vault e memória de conversas são auxiliares. O código real sempre vence.

---

## 1. Regra de ouro

Antes de qualquer alteração:

1. Entenda o objetivo real da tarefa.
2. Leia os arquivos canônicos.
3. Inspecione o código atual.
4. Faça a menor mudança correta.
5. Valide com comandos adequados ao risco.
6. Só declare pronto se os testes necessários passarem.

Nunca diga que algo está pronto se:

- não foi validado;
- o build falhou;
- o teste falhou;
- a alteração depende de host offline sem registrar isso;
- você apenas “acha” que funcionou;
- você não verificou o arquivo real afetado.

---

## 2. Arquivos obrigatórios de contexto

Antes de mudar qualquer coisa, leia nesta ordem:

1. `AGENTS.md`
2. `.agents/rules/00-core.md`
3. `.agents/rules/90-definition-of-done.md`
4. workflow específico em `.agents/workflows/`
5. `docs/README.md`
6. `docs/ROADMAP.md`
7. `.context/CURRENT_STATE.md`
8. `docs/ai/PROJECT_CONTEXT.md`
9. `docs/ai/PROJECT_INDEX.md`
10. skill relevante em `skills/**`, quando existir
11. arquivo real que será alterado
12. documentação oficial atual, quando a tarefa depender de comportamento externo

Se algum desses arquivos não existir, registre como pendência, mas não invente conteúdo.

---

## 3. Fonte de verdade e precedência

Quando houver conflito entre fontes:

1. **Código atual do repo vence.**
2. `flake.nix`, `hosts/**`, `modules/**`, `profiles/**`, `home/**`, `packages/**` definem comportamento real.
3. `docs/CURRENT_STATE.md` e `context/CURRENT_STATE.md` orientam o estado documental recente.
4. `docs/ai/**` serve como contexto compacto para agentes.
5. `context/**` preserva decisões, incidentes e histórico técnico.
6. Vault/Obsidian ajuda no raciocínio, mas não substitui repo.
7. Conversas anteriores ajudam no contexto, mas não substituem o estado atual do código.
8. Documentação histórica deve ser rebaixada para roadmap/histórico quando divergir do código.

---

## 4. Escopo do projeto

### 4.1 Kryonix é

- Um framework NixOS por flakes.
- Um conjunto de hosts declarativos.
- Um desktop Linux Hyprland/Caelestia.
- Um ambiente de desenvolvimento e sysadmin.
- Um sistema de IA local com Brain/RAG.
- Uma separação cliente/servidor entre Inspiron e Glacier.
- Um projeto com ambição de distro/ISO própria.

### 4.2 Kryonix não é, hoje

- Backend web público tradicional.
- Produto SaaS.
- Aplicação web frontend-first.
- Ambiente onde scripts soltos vencem configuração declarativa.
- Sistema onde documentação antiga pode prometer recurso não implementado.

Se uma doc disser que algo existe, mas o código não confirmar, mova para **Roadmap**, **Histórico** ou **Não implementado**.

---

## 5. Arquitetura de alto nível

```txt
Kryonix repo
├── flake.nix
├── hosts/
│   ├── inspiron/
│   ├── glacier/
│   └── common/
├── modules/
│   └── nixos/
├── profiles/
├── features/
├── home/
├── desktop/
│   └── hyprland/
├── packages/
├── overlays/
├── docs/
├── docs/ai/
├── context/
├── scripts/
└── skills/
```

---

## 6. Papel dos hosts

### 6.1 Inspiron

O **Inspiron** é a workstation cliente.

Responsabilidades:

- desktop diário;
- Hyprland/Caelestia;
- desenvolvimento;
- uso de CLI `kryonix`;
- consulta remota ao Brain do Glacier;
- MCP client;
- ferramentas de usuário;
- operação leve.

Não deve exigir localmente:

- Ollama;
- storage LightRAG;
- GraphML;
- vault completo;
- runtime Brain server;
- GPU NVIDIA server-side.

Quando o Glacier estiver offline, falhas de runtime devem ser tratadas como `WARN`, não `FAIL`, no contexto cliente.

### 6.2 Glacier

O **Glacier** é o servidor IA / Brain / mini datacenter pessoal.

Responsabilidades:

- NixOS declarativo;
- GPU NVIDIA RTX 4060;
- CUDA/NVIDIA driver;
- Ollama;
- Kryonix Brain API;
- LightRAG storage;
- GraphML;
- Vector DB;
- MCP Brain server;
- vault/index;
- backups;
- Tailscale;
- SSH porta `2224`;
- IP LAN fixo alvo `10.0.0.2`;
- perfil opcional de workstation/gaming.

Alvo arquitetural:

```txt
Inspiron
  -> LAN/Tailscale
  -> Glacier
  -> Brain API :8000
  -> Ollama :11434
  -> Vault / LightRAG storage
```

---

## 7. Estado canônico do Glacier

O caminho correto é:

```txt
Glacier = servidor NixOS declarativo de IA
Inspiron = cliente leve/workstation
```

O Glacier deve ser migrado/operado como host oficial em:

```txt
hosts/glacier/
├── default.nix
├── hardware-configuration.nix
├── networking.nix
├── storage.nix
├── nvidia.nix
├── services/
│   ├── ollama.nix
│   ├── kryonix-brain.nix
│   ├── lightrag.nix
│   └── mcp.nix
└── profiles/
```

Se esses arquivos não existirem no repo atual, não invente que existem. Crie somente quando a tarefa pedir e a arquitetura exigir.

---

## 8. Roadmap técnico do Glacier

### Fase A — Congelar baseline

Objetivo: parar de remendar sem saber o estado real.

Comandos esperados:

```bash
git status
git submodule status --recursive
nix flake show --all-systems
nix flake check --keep-going
```

Critério de aceite:

- estado Git compreendido;
- submódulos compreendidos;
- falhas existentes classificadas como antigas, novas ou ambientais;
- nenhuma alteração destrutiva feita.

### Fase B — Host Glacier declarativo

Criar ou limpar:

```txt
hosts/glacier/default.nix
hosts/glacier/hardware-configuration.nix
profiles/server/ai.nix
profiles/server/networking.nix
```

Critério de aceite:

- host `glacier` aparece nos outputs do flake;
- avaliação do host funciona;
- hardware real não é sobrescrito sem necessidade;
- rede, SSH e Tailscale são declarativos.

### Fase C — NVIDIA + Ollama

Implementar:

```txt
hardware.nvidia
CUDA compatível
services.ollama.enable = true
storage dedicado para modelos
```

Critério de aceite:

- driver NVIDIA declarado corretamente;
- Ollama como serviço;
- porta `11434` tratada conscientemente;
- modelos armazenados fora de local frágil quando possível;
- build/eval do host passa.

### Fase D — Brain API + LightRAG

Transformar runtime manual em serviços:

```txt
kryonix-brain.service
kryonix-lightrag.service
kryonix-brain-doctor.timer
```

Critério de aceite:

- serviços systemd declarativos;
- paths fixos;
- permissões explícitas;
- backup antes de repair;
- doctor local;
- graph stats;
- search smoke;
- proteção contra corrupção.

### Fase E — MCP remoto

Fluxo alvo:

```txt
Inspiron MCP client
  -> SSH/Tailscale
  -> Glacier MCP Brain server
  -> tools JSON-RPC
```

Critério de aceite:

- JSON-RPC limpo no stdout;
- logs no stderr;
- sem secrets em `.mcp.json`;
- `.mcp.example.json` atualizado;
- `kryonix mcp check` passa;
- `kryonix mcp doctor` não mostra erro fatal injustificado.

### Fase F — Vault vivo

Implementar ingestão controlada:

```txt
POST /notes/propose
POST /events/log
POST /ingest/approved
```

Ou comandos equivalentes:

```bash
kryonix brain ingest-note --approve
kryonix brain learn-web "tema" --mode official-only
kryonix brain learn-web "tema" --review
```

Critério de aceite:

- Inspiron não escreve direto no storage do Brain;
- há aprovação antes de ingestão sensível;
- há backup antes de mutação estrutural;
- conteúdo ingerido tem fonte, data e motivo.

### Fase G — CI/checks

Obrigatório para entrega madura:

```bash
nix flake check --keep-going
kryonix brain health
kryonix brain stats
kryonix brain search "pipeline RAG Kryonix"
kryonix mcp check
```

Critério de aceite:

- build/configuração passa;
- runtime remoto é validado quando disponível;
- indisponibilidade do Glacier é marcada como ambiente, não mascarada como sucesso.

---

## 9. Regras gerais de alteração

- Faça a menor mudança correta.
- Não refatore por estética durante correção pontual.
- Preserve comportamento funcional salvo pedido explícito.
- Não altere `flake.lock` sem necessidade real.
- Não execute comandos destrutivos sem pedido humano claro.
- Não mexa em discos, bootloader, partições, Tailscale auth, firewall ou GPU sem plano e rollback.
- Em árvore suja, assuma que mudanças existentes são do usuário.
- Trabalhe ao redor das mudanças do usuário.
- Prefira PRs pequenos, revisáveis e com finalidade clara.
- Toda mudança deve ter validação proporcional ao risco.

### 9.1 Governança de Workflows

Se uma tarefa não tiver um workflow correspondente em `.agents/workflows/`:
- Use `.agents/workflows/refinement.md`.
- Ou crie um workflow novo, pequeno e específico.
- **Nunca improvise** sem registrar as regras e a validação em um workflow ou plano.

---

## 10. Diretórios que não devem ser varridos sem motivo

Evite ler ou processar recursivamente:

```txt
.git/
node_modules/
dist/
build/
target/
result/
.direnv/
vendor/
.cache/
.tmp/
__pycache__/
.pytest_cache/
.mypy_cache/
```

Use busca seletiva com `rg`, `find` limitado ou leitura de arquivos específicos.

---

## 11. Segurança

### 11.1 Secrets

Nunca commite ou exponha:

- tokens;
- chaves privadas;
- auth keys do Tailscale;
- senhas;
- secrets GitHub;
- SSH private keys;
- GPG private keys;
- credenciais de VPN;
- `.env` real;
- `.mcp.json` real com secrets.

Trate como sensíveis:

```txt
/root/tailscale-authkey.secret
~/.ssh/*
~/.gnupg/*
.env
*.secret
*.key
*.pem
```

### 11.2 Nix store

Nunca coloque secrets em:

- derivations;
- arquivos gerados no `/nix/store`;
- opções Nix que acabam world-readable;
- logs de build;
- systemd units com valores sensíveis inline.

Use arquivos em `/run/secrets`, `sops-nix`, `agenix` ou caminho explícito fora do store, conforme o padrão real do repo.

### 11.3 Rede e firewall

Não abra portas sem justificar:

- serviço;
- interface;
- origem permitida;
- risco;
- rollback.

Portas conhecidas no projeto:

```txt
2224  SSH Glacier
8000  Kryonix Brain API
11434 Ollama
```

Exposição pública deve ser evitada por padrão. Prefira LAN/Tailscale.

---

## 12. Validação por tipo de mudança

### 12.1 Documentação

Validação mínima:

```bash
rg -n "TODO|FIXME|IMPLEMENTADO|ROADMAP" docs context AGENTS.md || true
```

Verificar:

- links relativos;
- claims falsos;
- comandos quebrados;
- arquitetura não implementada;
- duplicação entre docs.

### 12.2 Nix formatting

```bash
nix fmt
```

### 12.3 Avaliação geral

```bash
nix flake show --all-systems
```

### 12.4 Baseline CI

```bash
nix flake check --keep-going
```

### 12.5 Host específico

Para build sem aplicar:

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link -L --show-trace
```

Para `nh` quando experimental features estiverem habilitadas:

```bash
nh os build .#<host> -L --show-trace
```

Se `nh` reclamar de flakes/nix-command:

```bash
NIX_CONFIG="experimental-features = nix-command flakes" nh os build .#<host> -L --show-trace
```

### 12.6 Antes de switch

Não rode automaticamente:

```bash
switch
boot
test
deploy
sync
format-*
install-system
disko
sudo
```

Só rode com pedido humano claro.

---

## 13. Política de comandos perigosos

### 13.1 Proibido sem aprovação explícita

```bash
sudo nixos-rebuild switch
nixos-install
disko
mkfs.*
parted
sgdisk
wipefs
rm -rf /
rm -rf /mnt
zpool destroy
btrfs filesystem delete
systemctl reboot
shutdown
poweroff
tailscale up --auth-key=...
```

### 13.2 Permitido com cautela

```bash
git status
git diff
git submodule status --recursive
nix flake show --all-systems
nix flake check --keep-going
nix build ... --no-link
systemctl status ... --no-pager
journalctl -u ... --no-pager -n 100
```

### 13.3 Regra de rollback

Toda mudança envolvendo:

- boot;
- discos;
- rede;
- firewall;
- Tailscale;
- GPU;
- desktop session;
- display manager;
- libvirt;
- storage Brain;
- LightRAG repair;
- MCP server;
- systemd service crítico;

precisa informar rollback.

---

## 14. LightRAG / Brain Resilience

### 14.1 Separação oficial

```txt
glacier  = servidor Brain
inspiron = cliente/workstation
```

No `glacier` ficam:

- Ollama;
- Kryonix Brain;
- storage LightRAG;
- MCP Brain;
- vault;
- índice;
- GraphML;
- vector DB.

No `inspiron` ficam:

- CLI;
- cliente MCP;
- config de acesso remoto;
- integração com desktop/dev.

### 14.2 Regra de runtime offline

No cliente, estas condições são `WARN`, não `FAIL`:

- Glacier offline;
- Ollama indisponível;
- índice vazio;
- GraphML ausente;
- vault vazio;
- API remota sem resposta;
- `KRYONIX_BRAIN_API` não configurado.

Isso não significa que o servidor está pronto. Significa apenas que o cliente não deve falhar build/config por depender de runtime remoto.

### 14.3 Critério de pronto no cliente

Mensagem correta:

```txt
Kryonix está PRONTO em nível de build/configuração. Runtime depende do Glacier.
```

Use apenas quando os checks de build/configuração do cliente passaram.

### 14.4 Critério de pronto no servidor

Para Glacier/server, validar:

```bash
kryonix test server
kryonix brain doctor --local
kryonix graph stats --local
kryonix brain health
kryonix brain stats
kryonix brain search "pipeline RAG Kryonix"
systemctl status ollama.service --no-pager
systemctl status kryonix-brain.service --no-pager
```

Se algum comando não existir no estado atual do repo, registre como pendência/roadmap e não finja execução.

---

## 15. Qualidade de resposta do RAG

O Kryonix Brain deve responder de forma:

- específica ao Kryonix;
- fundamentada nos chunks reais;
- técnica;
- objetiva;
- com fontes/referências quando disponíveis;
- sem exemplos genéricos inventados;
- sem mencionar OpenAI/GPT se isso não estiver nos chunks;
- recusando ou sinalizando falta de grounding quando não houver base suficiente.

### 15.1 Anti-alucinação

Se a pergunta for sobre o projeto e os chunks não tiverem base suficiente:

- não invente;
- diga que não há grounding suficiente;
- sugira ingestão/curadoria de documentos;
- mostre quais índices/chunks foram consultados, se disponível.

### 15.2 Conteúdo do grafo

Melhorias no grafo devem priorizar:

- entidades reais do repo;
- relações entre módulos/hosts/serviços;
- decisões arquiteturais;
- incidentes técnicos;
- comandos validados;
- status implementado vs roadmap;
- links para arquivos reais.

---

## 16. MCP Deliverable Rules

Antes de submeter alteração MCP ou nova configuração de servidor, todos os gates aplicáveis devem passar.

### 16.1 Validation gates

```bash
kryonix mcp check
./scripts/check-mcp.sh
pytest -q packages/kryonix-brain-lightrag/tests/test_mcp_*.py
kryonix mcp doctor
```

Todos devem passar ou ser classificados como:

- falha antiga;
- falha nova causada pela mudança;
- falha de ambiente;
- pendência porque o Glacier está offline.

### 16.2 Invariantes de segurança

- Nenhum secret em `.mcp.json`.
- Chaves API e tokens ficam em variáveis de ambiente ou arquivos secretos fora do repo.
- Servidor filesystem deve ser read-only quando aplicável.
- Acesso deve ficar restrito ao vault/projeto permitido.
- Stdout deve ser JSON-RPC puro.
- Logs devem ir para stderr.
- `.mcp.json` real fica em `.gitignore`.
- `.mcp.example.json` é o template versionado.
- Não permitir acesso a `/` ou diretórios sensíveis.

### 16.3 Documentação MCP

Ao adicionar servidor:

```txt
docs/mcp/client-configs.md
docs/mcp/README.md
docs/mcp/security.md
.mcp.example.json
```

Atualize o mínimo necessário.

### 16.4 Critério de pronto MCP

- Testes Python passam.
- `kryonix mcp check` limpo.
- Sem poluição de stdout.
- Scan de secrets passa.
- Documentação atualizada.
- Validação server-side marcada como pendente se Glacier estiver offline.

---

## 17. Obsidian CLI Brain Enforcement

O projeto usa um vault Obsidian como cérebro técnico.

Vault default seguro:

```txt
/home/rocha/.local/share/kryonix/kryonix-vault
```

Vault real deve ser selecionado explicitamente com:

```bash
LIGHTRAG_VAULT_DIR=<path>
```

Antes de consultar ou atualizar o vault, leia:

```txt
docs/ai/OBSIDIAN_CLI_POLICY.md
docs/ai/OBSIDIAN_CLI_SAFE_COMMANDS.md
```

Antes de usar o vault, rode:

```bash
kryonix vault scan
```

### 17.1 Comportamento obrigatório

- Use `kryonix vault ...` e `kryonix brain ...` como gate oficial.
- Rode `kryonix brain health` antes de confiar no Brain.
- Não leia o vault inteiro.
- Comece por indexes, MOCs, project notes, playbooks e prompts.
- Não modifique Markdown do vault diretamente sem aprovação explícita.
- Se a Obsidian CLI estiver indisponível, pare e reporte.
- Se acesso direto ao filesystem for necessário, explique o motivo e escreva solicitação em:

```txt
docs/ai/VAULT_ACCESS_REQUEST.md
```

### 17.2 Prioridade ao usar Brain

1. código atual do projeto;
2. docs atuais do projeto;
3. `docs/ai/`;
4. vault via CLI;
5. documentação oficial;
6. memória do modelo.

### 17.3 Regra de update do vault

Se um update no vault for necessário, mas não puder ser feito com segurança pela CLI, escreva proposta em:

```txt
docs/ai/VAULT_UPDATE_PROPOSAL.md
```

Não modifique diretamente o vault sem aprovação.

### 17.4 Relatório obrigatório de uso do vault

Sempre reporte:

- resultado do check da CLI;
- comandos Obsidian usados;
- notas consultadas;
- notas criadas/atualizadas;
- motivo de cada update;
- risco;
- se links precisam revisão;
- `git diff`, se o vault for versionado.

---

## 18. NixOS, flakes e hosts

### 18.1 Regras de Nix

- Hosts escolhem papéis e opções.
- Módulos implementam comportamento.
- Evite `mkForce` sem necessidade.
- Prefira `mkDefault`, `mkIf`, `mkOption`, `mkEnableOption` quando fizer sentido.
- Separe configuração por host quando envolver hardware.
- Não misture hardware específico em módulo genérico.
- Não coloque política global em host específico sem justificativa.

### 18.2 Estrutura esperada

```txt
flake.nix                    outputs, inputs, checks, formatter
lib/options.nix              namespace público kryonix.*
hosts/<host>/default.nix     composição do host
hosts/<host>/hardware-configuration.nix hardware real
hosts/common/                base compartilhada
modules/nixos/**             módulos do sistema
profiles/**                  papéis reutilizáveis
features/**                  capacidades opt-in
home/**                      Home Manager
packages/**                  pacotes/CLI
```

### 18.3 Hosts e hardware

- `hosts/glacier/hardware-configuration.nix` é fonte real do host instalado.
- `hosts/*/disks.nix` é área de alto risco.
- Não use `disko`, `format-*` ou `install-system` para mudança incremental.
- Não sobrescreva bootloader sem revisar boot atual.

---

## 19. Desktop, Hyprland e Caelestia

### 19.1 Estado real

- Hyprland é o desktop ativo.
- Caelestia é o shell/rice principal.
- Docs antigas podem mencionar “Celestial Shell”; confirme no código real.

### 19.2 Regras de desktop

- Preserve UWSM no caminho de launch de apps.
- Prefira desktop entries válidos para apps gráficos.
- Não reintroduza `wofi` sem decisão explícita.
- Não remova Hyprland/Caelestia inteiro para corrigir pacote isolado.
- Não puxe dependências pesadas no host errado.
- Em workstation gamer, separe perfil gamer do perfil server.

### 19.3 Validação desktop

Quando tocar em UX/session:

- validar login/session;
- launcher;
- apps gráficos;
- portals;
- dbus;
- pipewire;
- GPU/render;
- regressão visual básica.

Comandos úteis:

```bash
systemctl --user status dbus.service --no-pager || true
systemctl --user status pipewire.service --no-pager || true
loginctl session-status || true
journalctl --user -b --no-pager -n 200
```

---

## 20. Gaming workstation

O perfil gamer deve ser explícito e opt-in.

Áreas típicas:

- Steam;
- Gamescope;
- MangoHud;
- Gamemode;
- Proton;
- Wine/Bottles/Lutris, se adotado;
- NVIDIA offload/prime quando aplicável;
- OpenRGB, quando suportado;
- controle de permissões para HID/USB;
- kernel e scheduler coerentes;
- áudio/pipewire estável.

Não misture gaming com servidor IA sem opção clara.

---

## 21. OpenRGB

OpenRGB deve ser tratado com cuidado porque envolve hardware, USB/HID e permissões.

Ao implementar:

- criar módulo ou feature opt-in;
- declarar udev rules necessárias;
- evitar rodar daemon privilegiado sem justificativa;
- documentar riscos;
- validar se o hardware é suportado;
- permitir desligar facilmente.

Critério de pronto:

```bash
openrgb --version
systemctl status openrgb.service --no-pager || true
journalctl -u openrgb.service --no-pager -n 100 || true
```

Se serviço não existir por design, documentar comando manual.

---

## 22. Virtualização e mini datacenter

Para Proxmox-like/local lab no NixOS, priorize:

- libvirt;
- virt-manager;
- bridge declarativa;
- firewall consciente;
- storage separado;
- snapshots;
- backups;
- isolamento por usuário/grupo;
- documentação de rollback.

Não altere rede/bridge remotamente sem plano de recuperação, especialmente via SSH.

---

## 23. Rede, SSH e Tailscale

### 23.1 Glacier

Valores conhecidos/alvo:

```txt
hostname: glacier
IP temporário possível: 10.0.0.68
IP LAN permanente alvo: 10.0.0.2
SSH: porta 2224
Acesso preferido: LAN/Tailscale
```

### 23.2 Regras

- Não quebrar acesso remoto.
- Ao mudar SSH/rede, preservar sessão atual quando possível.
- Não remover Tailscale sem alternativa.
- Não expor Brain/Ollama publicamente por padrão.
- Preferir bind em LAN/Tailscale.

### 23.3 Validação

```bash
ip addr
ip route
resolvectl status || true
systemctl status sshd.service --no-pager
systemctl status tailscaled.service --no-pager
tailscale status || true
ss -ltnp
```

---

## 24. Storage, Btrfs, ext4 e home

Mudanças de storage são alto risco.

Antes de qualquer alteração:

```bash
lsblk -f
blkid
findmnt
cat /etc/fstab || true
sudo btrfs filesystem show || true
```

Nunca rode formatação/mount destrutivo sem autorização explícita.

Para mover `/home`:

1. identificar disco correto;
2. confirmar UUID;
3. montar em local temporário;
4. fazer backup/cópia preservando atributos;
5. ajustar NixOS/fstab declarativo;
6. testar boot/mount;
7. manter rollback.

---

## 25. Backend/API local

Se API, serviço local ou automação HTTP aparecer:

- valide entradas na borda;
- documente contrato;
- use logs estruturados;
- não logue secrets;
- trate auth/autorização como obrigatórias;
- adicione teste ou smoke test;
- defina bind address explicitamente;
- documente portas.

---

## 26. Estilo de código

- Use nomes específicos, únicos e fáceis de buscar.
- Prefira fluxo simples e early return.
- Mensagens de erro devem incluir valor inválido e formato esperado.
- Funções novas devem ter responsabilidade única.
- Evite arquivos grandes novos.
- Extraia por responsabilidade quando houver ganho real.
- Comentários devem explicar motivo, risco ou workaround.
- Não escreva comentário que apenas repete o código.
- Patches de upstream devem ficar isolados.
- Todo workaround deve ter critério de remoção.

---

## 27. Documentação

### 27.1 Regras

- Documentação deve refletir o que existe.
- O que não existe vai para Roadmap.
- O que foi removido vai para Histórico, se ainda for útil.
- Não propague claims falsos.
- Centralize documentação operacional em `docs/`.
- Contexto para IA deve ser curto, indexado e atualizado.

### 27.2 Classificação obrigatória

Ao documentar feature, marque como uma destas:

```txt
Status: Implementado
Status: Parcial
Status: Roadmap
Status: Legado
Status: Removido
Status: Desconhecido — precisa inspeção
```

### 27.3 Docs canônicas sugeridas

```txt
docs/CURRENT_STATE.md
docs/ARCHITECTURE.md
docs/ROADMAP.md
docs/OPERATIONS.md
docs/GLACIER.md
docs/INSPIRON.md
docs/MCP.md
docs/BRAIN.md
docs/SECURITY.md
docs/TROUBLESHOOTING.md
docs/ai/PROJECT_CONTEXT.md
docs/ai/PROJECT_INDEX.md
```

Não crie todas sem necessidade. Use quando a tarefa pedir organização documental.

---

## 28. Observabilidade

Prefira comandos que mostrem diagnóstico antes de aplicar mudanças:

```bash
kryonix doctor
kryonix diff
kryonix git-status
systemctl status <service> --no-pager
journalctl -u <service> --no-pager -n 100
```

Logs não devem vazar:

- secrets;
- tokens;
- paths privados desnecessários;
- dados pessoais;
- conteúdo integral do vault sem motivo.

Ao corrigir incidente real, registre em:

```txt
context/INCIDENTS/
```

quando isso evitar redescoberta futura.

---

## 29. CI/CD

CI atual esperada:

```bash
nix flake show --all-systems
nix flake check --keep-going
```

Regras:

- mantenha CI simples;
- não adicione secrets em GitHub Actions;
- use permissões mínimas;
- não dependa de host pessoal online para CI básico;
- checks de runtime remoto devem ser opcionais ou `WARN` quando ambiente não existir.

---

## 30. Git, commits e PRs

### 30.1 Antes de alterar

```bash
git status --short
git diff --stat
git submodule status --recursive
```

### 30.2 Regras

- Não sobrescreva alterações do usuário.
- Não faça commit sem pedido explícito.
- Não rode `git reset --hard` sem pedido explícito.
- Não force push.
- Não atualize submódulo sem entender impacto.

### 30.3 PR pequeno ideal

Cada PR deve ter:

- objetivo claro;
- escopo estreito;
- arquivos alterados;
- comandos de validação;
- riscos;
- rollback;
- docs atualizadas quando comportamento público mudar.

---

## 31. Tratamento de erros

Quando encontrar erro:

1. Capture mensagem exata.
2. Identifique o comando que gerou.
3. Classifique:
   - erro novo causado pela mudança;
   - erro antigo existente;
   - erro de ambiente;
   - erro de rede/cache;
   - erro por host offline;
   - erro por secret ausente.
4. Corrija se estiver no escopo.
5. Rode novamente.
6. Reporte resultado.

Nunca esconda erro.

---

## 32. Problemas conhecidos e padrões de correção

### 32.1 Build puxando Deno/rusty-v8 indevidamente

Sintoma:

```txt
rusty-v8
deno
yt-dlp
mpv-with-scripts
kalarm
```

Ação esperada:

- descobrir quem puxa a cadeia;
- remover do closure do host afetado se não for necessário;
- não remover Hyprland/Caelestia inteiro sem necessidade;
- mover dependência para perfil correto;
- garantir que compilação pesada fique no Glacier quando esse for o objetivo.

Validação:

```bash
nix why-depends .#nixosConfigurations.inspiron.config.system.build.toplevel <drv> || true
nix build .#nixosConfigurations.inspiron.config.system.build.toplevel --no-link -L --show-trace
```

### 32.2 Caelestia `postPatch` com literal inválido

Sintoma:

```txt
1: command not found
```

Correção esperada:

```nix
postPatch = (old.postPatch or "") + ''
  sed -i '/pragma DefaultEnv/d' shell.qml
'';
```

Não alterar patches não relacionados.

### 32.3 Erro D-Bus/session

Investigar:

```bash
systemctl --user status dbus.service --no-pager || true
journalctl --user -b --no-pager -n 200
loginctl session-status || true
echo "$DBUS_SESSION_BUS_ADDRESS"
echo "$XDG_RUNTIME_DIR"
```

Não aplicar workaround cego.

### 32.4 `bwrap: Can't chdir to /etc/kryonix`

Investigar:

```bash
pwd
ls -ld /etc/kryonix
readlink -f /etc/kryonix || true
mount | grep kryonix || true
```

Causas possíveis:

- caminho inexistente dentro de sandbox;
- bind mount ausente;
- app sandboxado sem permissão;
- repo não clonado no host;
- working directory inválido.

Corrigir o caminho ou permissão, não desabilitar sandbox sem justificativa.

---

## 33. Prompts/agentes operacionais

### 33.1 Prompt para limpeza documental canônica

```txt
Você está no repositório Kryonix.

Objetivo:
Refatorar a documentação para ficar fiel ao código real. Centralizar documentação operacional em docs/ e mover qualquer claim não implementado para Roadmap.

Regras:
- Código atual vence documentação.
- Não invente feature.
- Não remova histórico útil sem mover para seção histórica.
- Não altere comportamento funcional.
- Não toque em flake.lock.
- Não execute comandos destrutivos.

Passos:
1. Leia AGENTS.md, docs/ai/PROJECT_CONTEXT.md, docs/ai/PROJECT_INDEX.md e context/INDEX.md.
2. Faça inventário dos docs existentes.
3. Classifique cada claim como Implementado, Parcial, Roadmap, Legado ou Desconhecido.
4. Centralize docs canônicos em docs/.
5. Atualize docs/ai/PROJECT_CONTEXT.md e docs/ai/PROJECT_INDEX.md com resumo curto.
6. Crie ou atualize docs/ROADMAP.md para itens não implementados.
7. Rode validação Markdown básica e git diff.

Entrega:
- Arquivos alterados.
- Claims removidos ou movidos para Roadmap.
- Comandos executados.
- Pendências.
```

### 33.2 Prompt para Glacier servidor IA

```txt
Você está no repo Kryonix.

Objetivo:
Transformar o host glacier em servidor NixOS declarativo de IA/Brain, sem quebrar acesso remoto.

Contexto:
- glacier = servidor IA / Ollama / Kryonix Brain / LightRAG / MCP / vault.
- inspiron = cliente/workstation.
- SSH alvo do glacier: porta 2224.
- IP LAN permanente alvo: 10.0.0.2.
- Usar Tailscale/LAN preferencialmente.

Regras:
- Não rodar switch, reboot, disko, mkfs, install-system ou sudo sem aprovação explícita.
- Não expor Ollama/Brain publicamente.
- Não colocar secrets no Nix store.
- Não misturar perfil gamer com server sem opção clara.

Passos:
1. Ler AGENTS.md e docs relevantes.
2. Inspecionar hosts/glacier real.
3. Validar flake outputs.
4. Declarar/ajustar NVIDIA, Ollama, Brain API, LightRAG e MCP como módulos/serviços.
5. Garantir paths de storage e permissões.
6. Adicionar checks/doctor/timers quando aplicável.
7. Buildar host sem aplicar.

Validação:
- git status
- nix flake show --all-systems
- nix build .#nixosConfigurations.glacier.config.system.build.toplevel --no-link -L --show-trace

Entrega:
- O que mudou.
- Como validar no glacier.
- Riscos.
- Rollback.
```

### 33.3 Prompt para workstation gamer

```txt
Você está no repo Kryonix.

Objetivo:
Implementar ou melhorar perfil gamer/workstation no host glacier sem quebrar o papel server IA.

Regras:
- Gaming deve ser opt-in e separado do perfil server.
- Não remover Hyprland/Caelestia sem necessidade.
- Não puxar dependências pesadas para inspiron por acidente.
- OpenRGB deve ser opt-in e seguro.
- Validar build do host afetado.

Escopo desejado:
- Steam
- Gamescope
- MangoHud
- Gamemode
- Proton/Wine/Lutris se já houver padrão no repo
- NVIDIA config compatível
- OpenRGB com udev/permissões corretas

Validação:
- nix flake show --all-systems
- nix build .#nixosConfigurations.glacier.config.system.build.toplevel --no-link -L --show-trace
- revisar closure para dependências indevidas no inspiron

Entrega:
- arquivos alterados
- opções adicionadas
- como habilitar/desabilitar
- riscos e rollback
```

### 33.4 Prompt para corrigir build pesado no Inspiron

```txt
Você está no repo Kryonix no host inspiron.

Problema:
O build do host inspiron está puxando cadeia pesada como kalarm -> mpv-with-scripts -> yt-dlp -> deno -> rusty-v8.

Objetivo:
Remover essa cadeia do closure do inspiron, exceto se houver necessidade explícita e justificada.

Regras:
- Não remover Hyprland/Caelestia inteiro sem necessidade.
- Não alterar flake.lock sem necessidade.
- Não mascarar dependência removendo pacote aleatório.
- Descobrir quem puxa cada dependência.
- Se algo for necessário apenas no glacier, mover para perfil/host glacier.

Passos:
1. git status.
2. nix why-depends no toplevel do inspiron.
3. rg por kalarm, mpv, yt-dlp, deno, rusty-v8.
4. Ajustar módulo/perfil correto.
5. Buildar inspiron sem aplicar.

Validação:
- nix build .#nixosConfigurations.inspiron.config.system.build.toplevel --no-link -L --show-trace
- confirmar que a cadeia pesada saiu ou explicar dependência inevitável.

Entrega:
- causa raiz
- arquivos alterados
- validação
- pendências
```

---

## 34. Checklist final de entrega

Ao finalizar qualquer tarefa, informe:

```txt
Status:
Arquivos alterados:
O que mudou:
Validação executada:
Resultado dos testes:
Riscos:
Rollback:
Pendências:
```

Se não executou validação, diga claramente:

```txt
Validação não executada: <motivo real>.
```

Não use “pronto” sem evidência.

---

## 35. Checklist de segurança antes de entregar

- [ ] Não há secrets no diff.
- [ ] `flake.lock` não mudou sem motivo.
- [ ] Mudanças do usuário foram preservadas.
- [ ] Host correto foi afetado.
- [ ] Runtime offline foi tratado como ambiente quando aplicável.
- [ ] Docs não prometem feature inexistente.
- [ ] Testes/validações foram executados ou a ausência foi justificada.
- [ ] Rollback foi descrito para mudanças de risco.

---

## 36. Frase de encerramento correta

Use encerramentos objetivos.

Bom:

```txt
Build/configuração validados. Runtime do Glacier ainda depende do host estar online.
```

Bom:

```txt
A alteração está pronta em nível documental. Nenhum comportamento runtime foi alterado.
```

Ruim:

```txt
Tudo pronto e perfeito.
```

Ruim:

```txt
Deve funcionar.
```

Ruim:

```txt
Não testei, mas está certo.
```

---

## 37. Resumo executivo

Kryonix deve evoluir com disciplina de engenharia:

```txt
Código real primeiro.
Documentação fiel.
Mudança pequena.
Sem secrets.
Sem comando destrutivo sem aprovação.
Build antes de switch.
Cliente não depende de runtime server.
Glacier é o servidor IA.
Inspiron é cliente/workstation.
Brain responde com grounding real.
MCP usa JSON-RPC limpo.
Tudo que não existe vai para Roadmap.
```

Este documento é o contrato operacional para agentes no projeto.

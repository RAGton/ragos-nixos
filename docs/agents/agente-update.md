# AGENTE-UPDATE.md — Evolução Kryonix: Sistema Operacional com IA Local, Brain Distribuído e Workstation Profissional

> Versão: 2026-04-29  
> Escopo: Kryonix, Inspiron, Glacier, LightRAG, Ollama, Tailscale, NixOS, Hyprland, Caelestia/Celestial, Vault, MCP, apps, documentação e automação.

---

## 0. Princípio central

O Kryonix deve evoluir para um **sistema operacional integrado com IA local**, onde:

- **Glacier** é o servidor central de IA, conhecimento, modelos, vault e serviços.
- **Inspiron** é uma workstation leve, rápida, confiável e conectada ao Brain.
- O **Kryonix Brain/LightRAG** é o cérebro técnico de todos os projetos.
- O **Vault** melhora continuamente com cada mudança relevante.
- O sistema deve aprender com modificações, mas **nunca de forma descontrolada**.
- Toda alteração precisa ser testada antes de ser aplicada.
- Nenhum host deve ficar quebrado por automação agressiva.

Regra máxima:

```txt
Se não foi testado, não está pronto.
Se não tem rollback, não aplique.
Se não tem grounding, não responda como verdade.
```

---

## 1. Papéis dos hosts

### 1.1 Glacier — server principal

Glacier deve ser o servidor central.

Responsabilidades:

- Rodar NixOS futuramente, abandonando Windows 11.
- Rodar Ollama.
- Rodar Kryonix Brain API.
- Rodar LightRAG.
- Armazenar o Vault principal.
- Manter `rag_storage`.
- Servir o Brain para todos os hosts via Tailscale/VPN.
- Ser servidor de automação e build quando necessário.
- Ter IP fixo na LAN: `10.0.0.2`.
- Ter IP Tailscale estável.
- Expor serviços apenas em LAN/VPN, nunca em internet pública direta.
- Manter backup, logs, observabilidade e recuperação.
- Futuramente rodar interface gráfica Hyprland + Caelestia para uso local.
- Suportar feature gamer quando apropriado.

Serviços esperados no Glacier:

```txt
Ollama              : http://10.0.0.2:11434 / http://<tailscale-ip>:11434
Kryonix Brain API   : http://10.0.0.2:8000  / http://<tailscale-ip>:8000
Vault principal     : /srv/kryonix/vault ou caminho definido no módulo
LightRAG storage    : /srv/kryonix/vault/11-LightRAG/rag_storage
Tailscale           : habilitado
MCP remoto          : habilitado quando seguro
```

### 1.2 Inspiron — client/workstation

Inspiron deve ser workstation leve e operacional.

Responsabilidades:

- Rodar NixOS com Hyprland + Caelestia/Celestial Shell.
- Usar Glacier como servidor de Brain/Ollama por padrão.
- Não rodar indexação pesada localmente por padrão.
- Poder alimentar o Brain remotamente com mudanças aprovadas.
- Testar e validar configurações antes de `switch`.
- Ter apps essenciais funcionando sem `.desktop` quebrado.
- Usar Tailscale para acesso remoto ao Glacier.
- Ser capaz de desenvolver, operar e consultar o Brain.

Inspiron deve ser cliente por padrão, mas pode atuar como alimentador controlado do Brain:

```txt
Inspiron -> envia notas/patches/eventos aprovados -> Glacier indexa/atualiza Brain
```

### 1.3 Outros hosts

Todo host novo deve escolher um papel:

```nix
kryonix.role = "server" | "client" | "hybrid" | "builder" | "lab";
```

Regras:

- `server`: pode hospedar Brain/Ollama/Vault.
- `client`: consome Brain remoto.
- `hybrid`: pode operar local e remoto, com travas.
- `builder`: compila/builda pacotes.
- `lab`: ambiente de testes, nunca fonte de verdade.

---

## 2. Segurança e rede

### 2.1 Regra de exposição

Proibido expor diretamente na internet pública:

- Ollama `11434`
- Brain API `8000`
- SSH `22`
- MCP
- RustDesk relay/self-host sem hardening

Usar:

- Tailscale
- WireGuard
- LAN confiável
- Firewall restrito

### 2.2 Glacier IP fixo LAN

Glacier deve usar IP fixo `10.0.0.2` no NixOS.

Antes de aplicar, detectar interface real:

```bash
ip link
nmcli device status
ip route
```

Exemplo declarativo, ajustar interface real:

```nix
{
  networking.networkmanager.enable = true;

  # Preferir NetworkManager profile declarativo se o projeto usar NM.
  # Alternativa systemd-networkd apenas se padronizado no repo.
}
```

Nunca aplicar IP fixo sem confirmar:

- interface correta;
- gateway;
- DNS;
- se DHCP do roteador não vai conflitar.

Validação obrigatória:

```bash
ip addr
ip route
ping -c 3 10.0.0.1
ping -c 3 1.1.1.1
ping -c 3 google.com
tailscale status
```

### 2.3 Brain API Key

A `KRYONIX_BRAIN_KEY` é segredo.

Nunca colocar em:

- Git
- Nix
- flake
- docs
- logs
- chat
- README
- histórico de comandos quando possível

No Glacier:

```bash
/etc/kryonix/brain.env
```

No Inspiron:

```bash
/etc/kryonix/brain.env
```

Permissão recomendada:

```bash
sudo chown root:users /etc/kryonix/brain.env
sudo chmod 640 /etc/kryonix/brain.env
```

Se `users` não existir, usar grupo adequado como `wheel`, mas preferir grupo específico no futuro:

```bash
kryonix-brain
```

---

## 3. Configuração distribuída do Brain

### 3.1 Variáveis padrão

Em hosts client:

```bash
OLLAMA_HOST=http://10.0.0.2:11434
KRYONIX_BRAIN_URL=http://10.0.0.2:8000
KRYONIX_BRAIN_ENV=/etc/kryonix/brain.env
KRYONIX_BRAIN_MODE=remote
```

Fallback via Tailscale:

```bash
OLLAMA_HOST=http://<glacier-tailscale-ip>:11434
KRYONIX_BRAIN_URL=http://<glacier-tailscale-ip>:8000
```

### 3.2 Write modes do Brain

Configurar política explícita:

```bash
KRYONIX_RAG_WRITE_MODE=readonly | approved | server-only
```

Significado:

- `readonly`: host só consulta.
- `approved`: host pode enviar mudanças para fila de ingestão com aprovação.
- `server-only`: somente Glacier escreve/indexa.

Padrão:

```txt
Inspiron = approved
Glacier  = server-only/write
```

### 3.3 Alimentação remota do Brain

Inspiron pode alimentar o Brain, mas nunca escrevendo diretamente em `rag_storage`.

Fluxo correto:

```txt
Inspiron
  -> cria nota/patch/evento
  -> envia via API/MCP segura
  -> Glacier valida
  -> Glacier escreve no Vault
  -> Glacier roda index incremental
  -> Glacier valida stats/test all
```

Proibido:

```txt
Inspiron montando rag_storage com escrita.
Dois hosts escrevendo no GraphML/VDB simultaneamente.
```

---

## 4. MCP remoto

### 4.1 Objetivo

Restabelecer MCP remoto no Inspiron sempre apontando para Glacier.

Inspiron deve usar MCP/Brain remoto sem depender de storage local.

### 4.2 Regras

- MCP remoto deve usar Tailscale.
- API key obrigatória para operações sensíveis.
- Read-only por padrão.
- Ferramentas de escrita precisam de confirmação explícita.
- Nenhum MCP deve logar secrets.
- Nenhum MCP deve escrever em `rag_storage` remoto diretamente.

### 4.3 Validação

No Inspiron:

```bash
kryonix brain health
kryonix brain stats
kryonix brain search "Como funciona o pipeline de RAG do Kryonix?"
```

Testar MCP se existir comando:

```bash
kryonix mcp check
kryonix mcp tools
```

Critérios:

- conecta no Glacier;
- autentica;
- retorna JSON válido;
- não usa localhost errado;
- não usa storage local inexistente;
- não escreve sem autorização.

---

## 5. Apps, Hyprland, Caelestia e launcher

### 5.1 Contrato de apps

Todo `.desktop` ativo precisa apontar para executável existente no ambiente real da sessão.

O erro abaixo é proibido em estado final:

```txt
points to missing executable
```

### 5.2 Causa conhecida

Incidente real:

```txt
caelestia.service rodava com PATH restrito
UWSM validava Exec= nesse ambiente
Apps existiam, mas UWSM não via /run/current-system/sw/bin
```

Correção permanente:

- `kryonix-launch` deve injetar PATH correto;
- UWSM deve receber ambiente completo;
- Flatpak exports devem estar no `XDG_DATA_DIRS` se Flatpak estiver habilitado;
- apps do sistema e do usuário devem estar visíveis para launcher.

### 5.3 Auditoria obrigatória de desktop entries

Manter script versionado:

```txt
scripts/test-inspiron-apps.sh
scripts/check-desktop-exec.sh
```

Todo fix de desktop precisa rodar:

```bash
/tmp/check-desktop-exec.sh
```

ou script versionado equivalente.

Critério:

```txt
0 entradas quebradas relevantes.
```

### 5.4 Apps essenciais da workstation

Inspiron e futuros workstations devem ter profile declarativo de apps essenciais:

- VSCode Insiders ou VSCodium conforme decisão do usuário.
- Obsidian / `kryonix-obsidian`.
- Browser principal.
- Terminal.
- File manager.
- WinBox.
- RustDesk.
- LibreOffice.
- Git.
- Curl.
- Tailscale.
- Kryonix CLI.
- Caelestia/Celestial Shell.
- Launcher.
- Ferramentas de screenshot/clipboard/notificação.

### 5.5 RustDesk

Estratégia escolhida atual:

```txt
Flatpak oficial Flathub: com.rustdesk.RustDesk
```

Regras:

- Não compilar RustDesk localmente no Inspiron.
- Não usar pacote nativo pesado se acionar build Rust/Flutter local.
- Usar Flatpak oficial quando o pacote nativo não vier do cache.
- Garantir wrapper `rustdesk` se o fluxo do launcher depender dele.

Validação:

```bash
flatpak list | grep -i rustdesk
command -v rustdesk
kryonix-launch com.rustdesk.RustDesk.desktop
```

---

## 6. Modelos de IA e parâmetros

### 6.1 Modelo padrão para código

Glacier deve usar modelo melhor para código e RAG técnico.

Padrão inicial recomendado:

```bash
KRYONIX_LLM_MODEL=qwen2.5-coder:7b
KRYONIX_EMBED_MODEL=nomic-embed-text:latest
```

Alternativas podem ser configuradas por env/config, não hardcoded em vários lugares.

### 6.2 Perfis de IA

Criar perfis:

```txt
fast      -> modelo menor, baixa latência
balanced  -> qwen2.5-coder:7b
quality   -> modelo maior se Glacier suportar
coding    -> coder model
offline   -> 100% local
```

Config:

```bash
KRYONIX_AI_PROFILE=balanced
```

### 6.3 Troca de modelo

Toda troca de modelo exige teste:

```bash
ollama list
curl http://localhost:11434/api/tags
kryonix brain search "Como funciona o pipeline de RAG do Kryonix?" --lang pt-BR --verbose
kryonix test all
```

Critérios:

- qualidade melhor;
- latência aceitável;
- sem quebrar grounding;
- sem sumir sources.

---

## 7. LightRAG e qualidade das respostas

### 7.1 Contrato de resposta

`/search` deve retornar:

```json
{
  "status": "success",
  "answer": "...",
  "grounding": {
    "entities": 0,
    "relations": 0,
    "chunks": 0
  },
  "sources": [],
  "warnings": []
}
```

Regras:

- `sources` não pode ser vazio em `success`.
- `chunks` precisa ser `> 0`.
- Se `chunks == 0`, bloquear resposta.
- Não responder genericamente.
- Não mencionar OpenAI/GPT/LangChain/restaurante se não estiver no contexto.
- Responder com base no Vault/Kryonix.

### 7.2 Query crítica de validação

Toda alteração no Brain deve testar:

```txt
Como funciona o pipeline de RAG do Kryonix?
```

A resposta precisa mencionar:

- Glacier como servidor;
- Inspiron como cliente quando relevante;
- API `/search`;
- Tailscale;
- X-API-Key;
- GraphML/grafo;
- entities;
- relations;
- entity chunks;
- relation chunks;
- vector fallback;
- ranking;
- Ollama local;
- fontes/referências.

### 7.3 Cache

Validação de melhoria deve usar:

```json
{
  "no_cache": true,
  "debug": true
}
```

Não validar qualidade com cache antigo.

---

## 8. Vault como cérebro vivo

### 8.1 Objetivo

O Vault deve melhorar a cada modificação relevante.

Cada mudança técnica importante deve gerar ou atualizar:

- nota de incidente;
- nota de arquitetura;
- playbook;
- troubleshooting;
- documentação operacional;
- referência de decisão.

### 8.2 Política de aprendizado

Criar parâmetro:

```bash
KRYONIX_LEARN_MODE=off | manual | approved | auto-safe
```

Padrão recomendado:

```bash
KRYONIX_LEARN_MODE=approved
```

Significado:

- `off`: não alimenta o vault.
- `manual`: usuário cria nota.
- `approved`: agente propõe nota; usuário aprova.
- `auto-safe`: agente escreve notas não sensíveis e roda validação.

Nunca alimentar o Brain com:

- secrets;
- logs com chaves;
- dados privados desnecessários;
- arquivos temporários;
- outputs gigantes;
- conteúdo sem curadoria;
- código externo sem avaliação.

### 8.3 Qualidade do Vault

Cada nota técnica deve seguir:

```md
# Título

## Objetivo
## Contexto
## Como funciona
## Comandos
## Validação
## Erros comuns
## Rollback
## Referências
```

### 8.4 Incidentes

Todo problema real corrigido deve virar incidente:

```txt
context/INCIDENTS/YYYY-MM-DD-titulo.md
```

Formato:

```md
# Incidente: título

## Sintoma
## Causa raiz
## Impacto
## Correção
## Validação
## Como evitar regressão
## Arquivos relacionados
```

---

## 9. Web research controlado

### 9.1 Objetivo

O Brain pode buscar na web para aprender, mas não em toda execução.

Criar parâmetro:

```bash
KRYONIX_WEB_RESEARCH_MODE=off | manual | approved | scheduled
```

Padrão:

```bash
KRYONIX_WEB_RESEARCH_MODE=approved
```

### 9.2 Regras de web research

Usar web quando:

- usuário pedir explicitamente;
- informação pode estar desatualizada;
- pacote/modelo/ferramenta mudou;
- documentação oficial é necessária;
- decisão técnica precisa de fonte atual.

Não usar web quando:

- existe documentação local suficiente;
- tarefa é só refactor local;
- execução precisa ser rápida;
- risco de contaminar Vault com conteúdo fraco.

### 9.3 Fontes

Prioridade:

1. documentação oficial;
2. manuais;
3. repositórios maduros;
4. issues/discussions oficiais;
5. fóruns apenas como troubleshooting;
6. blogs somente se forem técnicos e verificáveis.

### 9.4 Curadoria de código externo

Antes de usar código externo:

- verificar licença;
- maturidade;
- issues;
- segurança;
- qualidade;
- testes;
- compatibilidade com NixOS;
- se há alternativa oficial.

Nunca copiar código externo sem nota de auditoria.

---

## 10. Criação de pacotes Nix com IA

### 10.1 Objetivo

Integrar o modelo ao sistema para ajudar a criar pacotes Nix a partir de código fonte.

### 10.2 Fluxo de empacotamento

Comando futuro sugerido:

```bash
kryonix package create <repo-url>
kryonix package audit <path>
kryonix package build <name>
kryonix package test <name>
```

Pipeline:

1. baixar código fonte em workspace temporário;
2. detectar linguagem/build system;
3. verificar licença;
4. identificar dependências;
5. gerar derivation;
6. rodar `nix build`;
7. corrigir iterativamente;
8. rodar testes;
9. gerar documentação;
10. propor commit.

### 10.3 Regras

- Não adicionar pacote ao sistema antes de build/test passar.
- Não ignorar licença.
- Não usar network durante build se o padrão Nix exige fetchers fixos.
- Não commitar hash falso.
- Não usar `--impure` sem justificativa.
- Não criar overlay global se pacote é experimental.

### 10.4 Estrutura sugerida

```txt
packages/
  <name>/
    package.nix
    default.nix
    passthru-tests.nix

overlays/
  default.nix

docs/packages/
  <name>.md
```

### 10.5 Validação

```bash
nix build .#<package>
nix flake check
nix run .#<package> -- --version
```

---

## 11. Testes obrigatórios do CLI Kryonix

Antes de encerrar qualquer mudança que mexa no CLI:

```bash
kryonix --help
kryonix status || true
kryonix doctor || true
kryonix brain health
kryonix brain stats
kryonix brain search "Como funciona o pipeline de RAG do Kryonix?"
kryonix launch --help || true
kryonix home --help || true
kryonix rebuild --help || true
```

Se o CLI tiver subcomandos adicionais, listar e testar:

```bash
kryonix --help
```

Critérios:

- nenhum traceback;
- mensagens claras;
- saída estável;
- `brain` funciona via Glacier;
- não exige storage local no Inspiron.

---

## 12. Git, submodules e push

### 12.1 Ordem correta

Se submodule mudou:

```bash
cd submodule
git add .
git commit -m "<tipo>: <mensagem>"
git push
cd ..

git add submodule
git commit -m "chore: update <submodule> submodule"
git push
```

Nunca commitar ponteiro de submodule para commit não pushado.

### 12.2 Validação

```bash
git status
git submodule status
git submodule update --init --recursive
```

Não pode aparecer:

```txt
not our ref
```

### 12.3 Arquivos proibidos

Não commitar:

- `brain.env`
- secrets
- logs temporários
- outputs de busca grandes
- caches
- `rag_storage`
- `.env`
- chaves SSH
- tokens

---

## 13. Migração do Glacier para NixOS

### 13.1 Objetivo

Glacier deve migrar de Windows 11 para NixOS como servidor principal.

### 13.2 Fases

#### Fase A — Inventário

Coletar:

- hardware;
- GPU;
- storage;
- rede;
- IP atual;
- serviços;
- modelos Ollama;
- caminho do Vault;
- backups;
- dependências Windows.

#### Fase B — Backup

Obrigatório antes de instalar NixOS:

- backup do Vault;
- backup do repo Kryonix;
- backup de `rag_storage`;
- export/lista de modelos Ollama;
- backup de chaves/secrets;
- backup de configs Tailscale;
- snapshot externo se possível.

#### Fase C — NixOS server profile

Criar host:

```txt
hosts/glacier/
```

Perfis:

```txt
profiles/server.nix
profiles/ai-server.nix
profiles/desktop-hyprland.nix
profiles/gaming.nix
profiles/storage.nix
```

#### Fase D — Serviços

Declarar:

- Ollama;
- Kryonix Brain API;
- Tailscale;
- firewall;
- backup;
- monitoring;
- Hyprland/Caelestia opcional;
- gaming profile opcional.

#### Fase E — Validação

```bash
nix flake check
sudo nixos-rebuild dry-build --flake .#glacier
sudo nixos-rebuild test --flake .#glacier
```

#### Fase F — Switch

Só depois de backup e validação.

---

## 14. Gaming feature no Glacier

Se Glacier tiver GPU dedicada, criar perfil gamer separado:

```nix
kryonix.features.gaming.enable = true;
```

Possíveis componentes:

- Steam;
- GameMode;
- MangoHud;
- Lutris/Heroic se desejado;
- drivers GPU;
- PipeWire;
- portals;
- controle de performance;
- isolamento para não afetar Brain/Ollama.

Regra:

```txt
Gaming não pode quebrar Brain server.
```

---

## 15. Validação final por tipo de mudança

### 15.1 Mudança de desktop/apps

```bash
nix flake check --show-trace
sudo nixos-rebuild dry-build --flake .#inspiron --show-trace
sudo nixos-rebuild test --flake .#inspiron --show-trace
/tmp/check-desktop-exec.sh
systemctl --failed
systemctl --user --failed || true
```

Depois:

```bash
sudo nixos-rebuild switch --flake .#inspiron --show-trace
```

### 15.2 Mudança no Brain

No Glacier:

```sh
kryonix brain stats
kryonix test all
```

API:

```bash
curl -H "X-API-Key: $KRYONIX_BRAIN_KEY" http://<glacier>:8000/stats
```

Search:

```bash
kryonix brain search "Como funciona o pipeline de RAG do Kryonix?"
```

### 15.3 Mudança no Vault

```bash
kryonix brain index --incremental
kryonix brain stats
kryonix test all
```

Não indexar arquivos gerados, caches ou `rag_storage`.

### 15.4 Mudança em rede

```bash
ip addr
ip route
resolvectl status || true
tailscale status
tailscale ping <glacier>
curl http://<glacier>:8000/health
curl http://<glacier>:11434/api/tags
```

---

## 16. Definição de pronto

Só declarar pronto se:

- `nix flake check` passou;
- `dry-build` passou;
- `test` passou;
- `switch` passou quando aplicável;
- CLI Kryonix testado;
- LightRAG remoto testado;
- MCP remoto testado ou limitação documentada;
- apps essenciais abrem;
- launcher sem `.desktop` quebrado;
- UWSM sem `missing executable`;
- `systemctl --failed` sem falhas críticas;
- `systemctl --user --failed` sem falhas críticas;
- Git limpo;
- submodules válidos;
- docs atualizadas;
- secrets fora do Git;
- rollback conhecido.

---

## 17. Entrega final obrigatória

Toda entrega deve conter:

1. Causa raiz.
2. Arquivos alterados.
3. Mudanças por host.
4. Mudanças globais.
5. Testes executados.
6. Resultado dos testes.
7. Estado do Git.
8. Commits/push.
9. Riscos.
10. Pendências reais.
11. Rollback.

Nunca usar:

```txt
pronto
```

sem evidências.

---

## 18. Baseline atual conhecido

Estado desejado a preservar:

- Inspiron usa Glacier via Tailscale.
- Glacier é Brain server.
- Inspiron apps funcionando.
- RustDesk via Flatpak oficial.
- `kryonix-launch` corrige ambiente PATH para UWSM.
- `WinBox`, `libreoffice`, `rustdesk`, `code-insiders` visíveis no PATH final.
- 0 `.desktop` quebrados.
- Brain API protegida por `X-API-Key`.
- `/health` público.
- `/stats` e `/search` autenticados.
- Respostas do Brain devem ser grounded com sources.
- `rag_storage` somente no servidor.

---

## 19. Próxima evolução recomendada

1. Transformar auditoria de `.desktop` em check permanente do flake.
2. Criar `kryonix brain ingest` com fila aprovada.
3. Criar `kryonix package create` para empacotar projetos Nix com IA.
4. Criar host `glacier` NixOS server.
5. Criar módulo `kryonix.ai-server`.
6. Criar módulo `kryonix.ai-client`.
7. Criar dashboard local do Brain.
8. Implementar web research controlado.
9. Criar quality score para notas do Vault.
10. Criar CI para submodules e flakes.

# Comandos Operacionais de IA

Status: Referência operacional
Fonte: consolidação de comandos estruturais, comandos técnicos e regras de segurança para uso com Adpta, Antigravity, Kora, Copilot, Gemini e agentes similares.

## Objetivo

Padronizar como prompts técnicos são escritos dentro do ecossistema Kryonix, evitando respostas genéricas e reduzindo o risco de agentes modificarem código, documentação ou infraestrutura sem inspeção e validação.

Este documento não implementa comandos no runtime. Ele define uma linguagem operacional para orientar agentes e prompts.

## Regra central

Todo pedido técnico sério deve declarar, no mínimo:

```txt
/papel
/contexto
/objetivo
/restricoes
/escopo
/formato
/validacao
/entrega
```

Sem esses blocos, a IA tende a preencher lacunas com suposições. No Kryonix, suposição não substitui inspeção do repositório real.

## Bloco estrutural básico

| Comando | Função |
| --- | --- |
| `/papel` ou `/role` | Define a especialidade e o nível de senioridade do agente. |
| `/contexto` | Explica o cenário técnico real. |
| `/objetivo` | Define a meta principal e inegociável. |
| `/restricoes` | Define o que o agente não pode fazer. |
| `/escopo` | Limita diretórios, arquivos ou componentes afetados. |
| `/formato` | Define o formato da resposta ou entrega. |
| `/validacao` | Exige comandos e critérios de teste. |
| `/entrega` | Define o checklist final esperado. |

Exemplo:

```txt
/papel Arquiteto Sênior NixOS, Rust, Python e infraestrutura local de IA.

/contexto
Estou trabalhando no projeto Kryonix em /etc/kryonix.
É uma plataforma NixOS declarativa com flakes, hosts inspiron/glacier, Brain/RAG/CAG/Neo4j/Ollama/LightRAG.

/objetivo
Criar um plano seguro para melhorar o Brain sem quebrar o Glacier.

/restricoes
Não rodar switch.
Não mexer em secrets.
Não alterar flake.lock sem necessidade.
Não inventar arquivos.
Código real vence documentação.

/validacao
Incluir comandos kryonix, nix flake check, testes e rollback.
```

## Comandos de raciocínio e estratégia

| Comando | Uso | Observação |
| --- | --- | --- |
| `/L99` | Modo técnico avançado, sem introduções didáticas desnecessárias. | Não autoriza inventar fatos. |
| `/OODA` | Crise operacional: Observe, Orient, Decide, Act. | Útil para produção, SSH, rede, Brain ou serviços quebrados. |
| `/RICE` | Priorização por Reach, Impact, Confidence e Effort. | Bom para backlog e issues. |
| `/MECE` | Quebra de problema sem lacunas nem sobreposição. | Bom para arquitetura e módulos. |
| `/FLOW` | Diagrama textual ou Mermaid. | Bom para Brain, RAG, MCP, rede e systemd. |
| `/TRADEOFF` | Comparação de alternativas. | Exige riscos e custo operacional. |
| `/DECISION` | Registro de decisão técnica. | Pode virar ADR ou seção em docs. |

## Comandos de engenharia

| Comando | Função |
| --- | --- |
| `/ARCH` | Desenhar arquitetura de sistema. |
| `/CLEAN` | Refatorar preservando comportamento. |
| `/BIG-O` | Avaliar complexidade, CPU, memória e loops. |
| `/RUBBERDUCK` | Depurar passo a passo. |
| `/SEC` | Auditoria defensiva de segurança. |
| `/REDTEAM` | Simulação segura de abuso, bypass lógico ou falha de regra. |
| `/SIM` | Simulação de caos, carga, concorrência ou queda de serviço. |
| `/OBSERVE` | Diagnóstico antes de alterar. |
| `/ROOTCAUSE` | Encontrar causa raiz. |
| `/PATCHPLAN` | Criar plano de patch pequeno. |

`/REDTEAM` deve permanecer defensivo. Não deve produzir instruções ofensivas reais nem exploração prática contra terceiros.

## Comandos específicos do Kryonix

| Comando | Função |
| --- | --- |
| `/KRYONIX` | Ativa contexto completo do projeto. |
| `/NIXOS` | Prioriza solução declarativa NixOS. |
| `/FLAKE` | Analisa flake, hosts, módulos, overlays e packages. |
| `/HOST glacier` | Foca o host Glacier. |
| `/HOST inspiron` | Foca o host Inspiron. |
| `/BRAIN` | Foca Kryonix Brain. |
| `/RAG` | Foca recuperação semântica. |
| `/CAG` | Foca contexto derivado do código/repo. |
| `/GRAPH` | Foca Neo4j/GraphRAG. |
| `/MCP` | Foca Model Context Protocol. |
| `/VAULT` | Foca Obsidian/Vault. |
| `/CLI` | Foca a CLI `kryonix`. |
| `/SYSTEMD` | Foca serviços, timers, logs e unidades systemd. |
| `/ROLLBACK` | Exige plano de reversão. |
| `/EVIDENCE` | Exige evidência de validação. |

## Comandos de segurança operacional

| Comando | Função |
| --- | --- |
| `/SAFE` | Modo conservador. |
| `/NO-DESTRUCTIVE` | Proíbe comandos destrutivos. |
| `/SECRETS` | Procura risco de vazamento. |
| `/REMOTE-SAFE` | Não quebrar SSH, Tailscale ou rede. |
| `/BOOT-SAFE` | Não quebrar bootloader. |
| `/GPU-SAFE` | Não quebrar NVIDIA, Wayland ou sessão gráfica. |
| `/STORAGE-SAFE` | Não mexer em discos, mounts ou Btrfs sem plano. |
| `/VALIDATE` | Exige testes. |
| `/DO-NOT-CLAIM-READY` | Proíbe declarar pronto sem validação. |

## Comandos para agentes executores

| Comando | Função |
| --- | --- |
| `/SURGERY` | Patch preciso por arquivo, função e trecho. |
| `/SPRINT` | Entrega em lotes pequenos. |
| `/DIFF-FIRST` | Mostrar plano/diff antes de alteração maior. |
| `/SMALL-COMMIT` | Commit pequeno e revisável. |
| `/NO-GIT-ADD-DOT` | Proíbe `git add .`. |
| `/TEST-FIRST` | Exige teste antes de conclusão. |
| `/DOC-SYNC` | Atualiza docs quando comportamento público muda. |
| `/CHANGELOG` | Registra mudança. |
| `/ROLLBACK` | Mostra como desfazer. |

## Contrato Adpta x Antigravity

### Adpta

O Adpta deve gerar raciocínio, arquitetura, prompts e crítica técnica.

Ele não deve:

- modificar arquivos;
- afirmar que executou comandos;
- declarar que algo foi validado sem evidência;
- inventar estado do repositório.

Ele deve entregar:

- análise;
- plano;
- prompt para executor;
- riscos;
- validações;
- rollback;
- critérios de conclusão.

### Antigravity

O Antigravity deve ser tratado como agente executor.

Ele deve:

1. ler `AGENTS.md` e docs canônicas;
2. inspecionar o código real;
3. aplicar patch pequeno;
4. rodar validações;
5. mostrar diff;
6. declarar pendências;
7. só dizer pronto com evidência.

## Template de prompt para executor

```txt
# Tarefa

# Contexto

# Objetivo

# Regras obrigatórias

# Arquivos a ler antes

# Escopo permitido

# Escopo proibido

# Plano esperado

# Comandos de auditoria inicial

# Implementação esperada

# Testes obrigatórios

# Critérios de conclusão

# Riscos

# Rollback

# Entrega final
```

## Exemplo Kryonix

```txt
/KRYONIX /BRAIN /GRAPH /ARCH /SEC /VALIDATE /ROLLBACK

Quero melhorar o Brain para responder diferença entre RAG, CAG e GraphRAG sem alucinar.

Crie um prompt para o Antigravity implementar isso no repo real.
Ele deve ler os arquivos antes, não reindexar, não trocar provider, não mexer em Neo4j agora, preservar o contrato ask/search e adicionar testes.
```

## Veredito operacional

```txt
Comandos estruturais = moldam a resposta.
Comandos técnicos = definem o tipo de raciocínio.
Comandos Kryonix = trazem contexto real.
Comandos de segurança = impedem desastre.
Comandos de validação = impedem "pronto" falso.
```

`/L99` significa mais precisão, menos enrolação e mais engenharia. Não significa arrogância nem chute confiante.

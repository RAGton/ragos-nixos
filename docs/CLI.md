# Kryonix CLI (Official Guide)

O CLI `kryonix` é o ponto central de entrada para gerenciamento do sistema, operações de IA (Brain) e automação do repositório. Ele abstrai comandos complexos de NixOS, Home Manager, Ollama e LightRAG em uma interface unificada e amigável.

## 🚀 Filosofia

1.  **Unificação**: Menos comandos para decorar (`nh`, `nix`, `git`, `uv`, `systemctl`).
2.  **Segurança**: Validações de sanidade antes de operações destrutivas.
3.  **IA Nativa**: Integração profunda com o Kryonix Brain (CAG e RAG).
4.  **Declarativo**: Alinhado com a filosofia NixOS.

---

## ⚙️ Como funciona (Internal Mechanics)

O `kryonix` não é apenas um script, mas um **orquestrador declarativo**. Ele é implementado via [kryonix-cli.nix](file:///etc/kryonix/packages/kryonix-cli.nix) usando `writeShellApplication` do Nixpkgs.

### 1. Resolução de Contexto
Ao ser executado, o CLI detecta automaticamente:
- **Host Atual**: Onde está rodando (via `/proc/sys/kernel/hostname`).
- **Raiz da Flake**: Onde o repositório Kryonix está localizado (procurando em `./`, `/etc/kryonix` ou via `git`).
- **Papel do Brain**: Se deve agir como cliente (remoto) ou servidor (local) baseado no hostname.

### 2. Delegação Inteligente
- **System Ops**: Delega para o `nh` (Next Helper) para uma experiência de UI melhor e builds mais rápidos.
- **Brain/AI**: Delega para o `uv` (Python manager) para executar o motor LightRAG e ferramentas Rust customizadas.
- **Git Ops**: Garante que o repositório esteja limpo e na branch `main` antes de sincronizar.

### 3. Hierarquia de Respostas (Brain Search)
Quando você roda `kryonix brain search`, o CLI segue esta ordem:
1.  **CAG (Code-Augmented Generation)**: Verifica se a resposta está nos arquivos `.nix`, `.md` ou `.sh` do repositório.
2.  **RAG (Retrieval-Augmented Generation)**: Se não for técnico/repo, busca no grafo de conhecimento do vault Obsidian.
3.  **Fallback**: Se ambos falharem, reporta falta de grounding técnico.

---

## 🛠️ Comandos Principais

### Gerenciamento de Sistema

Sempre use o `kryonix` para aplicar mudanças no sistema. **Evite `nh` ou `nix` diretamente** para garantir que os hooks e logs do Kryonix sejam executados corretamente.

*   `kryonix switch`: Aplica a configuração do host atual.
    *   Internamente: `nh os switch /etc/kryonix -H <host>`
*   `kryonix boot`: Registra a próxima geração no bootloader sem ativar agora.
*   `kryonix rebuild`: Apenas builda o sistema para validar erros (sem privilégios).
*   `kryonix home`: Aplica apenas as configurações do Home Manager.
*   `kryonix update`: Atualiza os inputs do `flake.lock`.
*   `kryonix doctor`: Diagnóstico rápido do estado do host e do repositório.

### Kryonix Brain (AI & RAG)

O Brain é dividido em **CAG** (Context-Augmented Generation) para o código/repo e **RAG** (Retrieval-Augmented Generation) para o vault/notas.

#### Context-Augmented Generation (CAG)
Ideal para perguntas sobre "Onde está X no código?", "Como funciona o Glacier?", "Quais os módulos de rede?".

*   `kryonix brain cag status`: Mostra o estado do pack de contexto atual.
*   `kryonix brain cag ask "pergunta"`: Responde perguntas técnicas usando o código como contexto.
*   `kryonix brain cag route "pergunta"`: Mostra quais arquivos o motor selecionaria para essa pergunta.
*   `kryonix brain cag build`: Reconstrói o pack de contexto (varre o repositório).

#### Retrieval-Augmented Generation (RAG)
Ideal para buscas em notas pessoais, histórico de conversas e conhecimento técnico profundo.

*   `kryonix brain search "pergunta"`: Busca inteligente que prioriza **CAG** para temas técnicos e usa **RAG** para conhecimento geral do vault.
*   `kryonix brain sync`: Sincroniza o vault Obsidian com o grafo do Brain (RAG).
*   `kryonix brain stats`: Estatísticas de entidades e relações no grafo.

---

## ❄️ Gerenciando o Glacier

O **Glacier** é o host principal de IA. Para garantir a estabilidade, siga estas práticas:

### 1. Switch Remoto
Você pode atualizar o Glacier de qualquer máquina (como o Inspiron) usando a flag `--host`:
```bash
kryonix switch --host glacier
```

### 2. Validação Antes do Switch
Antes de aplicar mudanças críticas no Glacier, sempre rode um check:
```bash
kryonix check --host glacier
```

### 3. Recuperação de Brain
Se o serviço de IA no Glacier falhar após um switch, use:
```bash
kryonix brain doctor --remote
```

---

## 💡 Dicas de Uso

### Por que usar `kryonix` em vez de `nh`?
O `kryonix` garante que:
1.  O diretório `/etc/kryonix` seja usado como base.
2.  O hostname correto seja mapeado (ex: `RVE-GLACIER` -> `glacier`).
3.  Logs de auditoria sejam gerados para o Brain.
4.  O ambiente Python (`uv`) esteja configurado para as ferramentas de IA.

---

> [!IMPORTANT]
> **O CLI `kryonix` é a fonte de verdade operacional.** Ao usá-lo, você garante que o sistema permaneça consistente com a arquitetura declarada no repositório.


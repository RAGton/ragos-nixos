# Kora CLI Usage Guide

A Kora é a assistente pessoal do Kryonix e pode ser acessada diretamente pelo CLI `kryonix kora`.

## Comandos Principais

### Status e Health

Para verificar se a Kora e suas dependências (Brain, Ollama) estão saudáveis:

```bash
kryonix kora health
kryonix kora status
kryonix kora capabilities
```

### Interações (Fase 1 e 2)

**Pergunta Rápida:**
```bash
kryonix kora ask "Qual é o status do sistema?"
```

Com modo explícito:
```bash
kryonix kora ask --mode direct "Traduza 'hello' para português"
```

**Busca na Memória (Brain RAG):**
```bash
kryonix kora memory search "arquitetura do projeto"
```

### Acesso Remoto

Se você está no **Inspiron** (cliente) e a Kora está rodando no **Glacier** (servidor), é necessário abrir o túnel SSH antes de interagir com ela:

```bash
kryonix kora tunnel
```

Mantenha o túnel aberto em um terminal e use a CLI normalmente em outro.

Veja [REMOTE_ACCESS.md](./REMOTE_ACCESS.md) para mais detalhes sobre arquitetura e segurança.

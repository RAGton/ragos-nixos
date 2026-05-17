# Antigravity Kora Agent Governance System

Este diretório contém as definições, papéis, regras operacionais e fluxos de trabalho da equipe de agentes autônomos (**Antigravity**) encarregados de manter e evoluir a **Kora** no ecossistema **Kryonix**.

---

## Estrutura do Diretório

```txt
.agents/
├── INDEX.md             # Índice geral de agentes e permissões
├── README.md            # Este arquivo de introdução e governança
├── roles/               # Definição canônica dos papéis de agentes especializados
│   ├── kora-mind-constructor.md
│   ├── kora-voice-stabilizer.md
│   ├── kora-security-warden.md
│   ├── kryonix-nixos-integrator.md
│   ├── kora-memory-rag-engineer.md
│   ├── kora-quality-benchmark-engineer.md
│   ├── kora-local-llm-training-engineer.md
│   ├── kora-ux-cli-designer.md
│   └── kora-n8n-automation-engineer.md
├── workflows/           # Fluxos operacionais passo a passo
│   ├── kora-agent-orchestration.md
│   ├── kora-voice-debug.md
│   ├── kora-mind-quality-pass.md
│   └── security-review.md
├── checklists/          # Checklists de segurança e conformidade
│   ├── validation.md
│   ├── no-secrets.md
│   └── nixos-switch-safety.md
└── prompts/             # System prompts e blueprints para novos agentes
    ├── antigravity-kora-master.md
    └── gemini-kora-agent-team.md
```

---

## Filosofia Operacional

1. **Local-First & Soberania**: O sistema de IA e voz da Kora deve rodar localmente no **Glacier** (servidor) e no **Inspiron** (cliente) sem dependências externas ocultas. Nenhuma chamada de nuvem é permitida sem opt-in explícito do usuário.
2. **Nixos-Native**: Toda configuração do sistema ou serviço em background deve ser declarada como um módulo NixOS ou Home Manager. Scripts imperativos avulsos são estritamente desencorajados para controle de produção.
3. **Pequenas Alterações Altamente Validadas**: Cada alteração deve ser a menor mudança correta possível, acompanhada de testes locais imediatos antes de qualquer comando de implantação (`switch`).
4. **Segurança Hardened**: Secrets de produção, chaves API e tokens nunca devem entrar na Nix Store ou no repositório do Git. O agente `kora-security-warden` audita agressivamente toda tentativa de violação.

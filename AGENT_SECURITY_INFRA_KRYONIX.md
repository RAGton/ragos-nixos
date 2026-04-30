# AGENT — Kryonix Infra Security & Hardening

## MISSÃO

Implementar uma camada de segurança completa, modular e declarativa no projeto Kryonix (NixOS + flakes), garantindo:

- segurança real (não superficial)
- zero regressão
- compatibilidade com serviços existentes
- build distribuído correto (Inspiron → Glacier)
- validação obrigatória antes de qualquer entrega

---

# PRINCÍPIO CENTRAL

NUNCA declarar "pronto" sem:

- flake válido
- build funcionando
- serviços funcionando
- portas corretas
- nenhum erro crítico

Se qualquer item falhar → NÃO está pronto

---

# CONTEXTO DO SISTEMA

Arquitetura atual:

- Inspiron → workstation (leve, cliente)
- Glacier → servidor (IA, Ollama, Brain, LightRAG)

Regra:

- Inspiron NÃO deve compilar pesado
- Glacier é o builder/server
- Segurança deve ser aplicada sem quebrar runtime

---

# REGRAS ABSOLUTAS

❌ NUNCA:

- abrir portas desnecessárias
- expor Ollama publicamente
- expor MCP sem proteção
- remover firewall
- commitar secrets
- rodar `switch` sem validação
- quebrar Hyprland/Caelestia
- bloquear GPU/NVIDIA/Ollama
- sobrescrever config existente sem análise

✅ SEMPRE:

- fazer menor mudança segura
- validar antes e depois
- manter compatibilidade
- documentar decisões críticas
- usar estrutura modular

---

# FASE 1 — AUDITORIA COMPLETA

Antes de modificar qualquer coisa:

1. Ler:
   - flake.nix
   - hosts/*
   - modules/*
   - profiles/*

2. Identificar:
   - serviços ativos
   - portas abertas
   - uso de:
     - SSH
     - Tailscale
     - Ollama
     - Brain API
     - MCP
     - reverse proxy

3. Mapear:

HOST → SERVIÇOS → PORTAS → EXPOSIÇÃO

---

# FASE 2 — ESTRUTURA PROFISSIONAL

Garantir estrutura:

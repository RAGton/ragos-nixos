# Kora Identity & Greeting Model

Este documento descreve como a Kora reconhece o usuário principal, gerencia perfis pessoais e lida com saudações de sessão.

## 1. Detecção de Identidade

A Kora utiliza informações do ambiente de execução (Unix USER, hostname) para identificar o operador.
- **Usuário Principal:** `rocha` (mapeado para o perfil **Ragton**).
- **Usuários Desconhecidos:** Recebem tratamento neutro e permissões restritas.

## 2. Perfil do Usuário (Ragton)

O perfil é carregado de forma persistente e contém:
- **Identidade:** Gabriel Aguiar Rocha.
- **Papel:** Técnico/sysadmin e estudante de Sistemas de Informação.
- **Interesses:** NixOS, Linux, IA local, RAG, Proxmox, etc.
- **Preferências:** Respostas diretas, técnicas e em PT-BR.

## 3. Fluxo de Saudação

Para evitar repetições desnecessárias, a Kora segue a regra:
- **Nova Sessão:** Sauda uma vez (ex: "Bom dia, Ragton.").
- **Mesma Sessão:** Vai direto ao ponto.
- **Mudança de Usuário:** Sauda novamente e ajusta permissões.

O estado da sessão é persistido em `/var/lib/kryonix/kora/sessions/`.

## 4. Respostas Determinísticas

Perguntas sobre a identidade do usuário (ex: "Quem sou eu?") são interceptadas pelo **Identity Router** no backend.
- Se o usuário for reconhecido, a Kora responde com os dados do perfil de forma imediata e precisa.
- Se o usuário perguntar sobre a identidade da Kora ("Quem é você?"), o roteador ignora e deixa o LLM responder com a personalidade da Kora.

## 5. Grounding Pessoal

O perfil do usuário é injetado dinamicamente no **System Prompt**, permitindo que o LLM adapte o tom e o conteúdo das respostas às preferências e ao nível técnico do operador.

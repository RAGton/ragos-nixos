# Skill: Operations

## Objetivo

Orientar mudanças operacionais com risco controlado.

## Regras centrais

- validar antes de aplicar
- preferir `test` quando a mudança ainda precisa de confirmação em runtime
- usar `switch` quando a alteração já estiver segura para ativação imediata
- separar erro novo de erro antigo antes de concluir que a mudança falhou
- manter rollback viável e explícito

## Fluxo padrão

1. checar contexto do host
2. validar flake e diff
3. aplicar com o menor risco possível
4. observar erro novo vs. ruído pré-existente
5. decidir entre seguir, corrigir ou reverter

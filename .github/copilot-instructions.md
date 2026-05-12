# Kryonix — Instruções de Repositório para Copilot

## 1. Fontes de verdade

Antes de propor mudanças amplas, leia obrigatoriamente:

- `AGENTS.md`
- `context/INDEX.md`
- `docs/CURRENT_STATE.md`
- `docs/OPERATIONS.md`
- `docs/ROADMAP.md`

O código real do repositório é a fonte principal de verdade.

Prioridade de contexto:

1. Código atual do repo
2. `AGENTS.md`
3. `context/`
4. `docs/CURRENT_STATE.md`
5. `docs/OPERATIONS.md`
6. `docs/ROADMAP.md`
7. Vault/Kryonix Brain, quando disponível
8. Documentação oficial
9. Memória geral do modelo

Se houver conflito, priorize o código real e registre a inconsistência.

---

## 2. Princípio central

Faça sempre a menor mudança correta, segura e reversível.

Priorize:

1. correção real
2. integridade de dados
3. bootabilidade
4. rollback
5. simplicidade
6. testes
7. documentação mínima

Nunca declare pronto sem validação.

---

## 3. Regras gerais de mudança

- Não faça refactor amplo sem necessidade.
- Não misture correção funcional com limpeza estética.
- Não quebre compatibilidade sem motivo explícito.
- Não remova código legado se ele ainda for usado.
- Não introduza abstrações genéricas sem consumidor real.
- Não esconda erros com `try/catch` ou `|| true` sem justificativa.
- Não silencie falhas críticas.

Mudanças devem ser pequenas, revisáveis e fáceis de reverter.

---

## 4. NixOS / Flakes

Ao tocar em Nix:

- não mexa em `flake.lock` sem necessidade real;
- não atualize inputs casualmente;
- preserve estrutura declarativa;
- prefira módulos pequenos;
- evite lógica imperativa;
- use opções explícitas;
- use `mkEnableOption`, `mkIf`, `mkMerge`, `mkDefault` quando adequado;
- use `mkForce` apenas com justificativa clara;
- não invente opções NixOS;
- valide opções com documentação oficial ou MCP `mcp-nixos`, quando disponível.

Em árvore suja, prefira validação com:

```bash
nix flake show path:$PWD
nix flake check path:$PWD --keep-going --show-trace
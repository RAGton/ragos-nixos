# Vault (Obsidian)

O cérebro técnico e central do projeto opera num diretório formatado como Vault do Obsidian.

Caminho seguro/default:
`/home/rocha/.local/share/kryonix/kryonix-vault`

O Vault pode ser modificado com a variável ambiental `LIGHTRAG_VAULT_DIR`.

## Fonte de Verdade e Sincronização
- `docs/` é a **fonte canônica** operacional.
- `ai/kryonix-vault/` é o vault curado para Obsidian e RAG.
- Notas em `ai/kryonix-vault/01-Canonical/` são derivadas de `docs/`.

## Regras de Acesso e Operação (Obsidian CLI Brain Enforcement)

O sistema conta com regras estritas para agentes não modificarem de forma caótica as anotações centrais do usuário:

1. **Acesso com CLI**: Todo agente interagindo com o Vault deve utilizar a `kryonix vault ...` ou `kryonix brain ...` como porta de acesso e operação principal.
2. **Saúde Inicial**: Executar `kryonix brain health` e `kryonix vault scan` é o pré-requisito antes de depender do retorno do Vault.
3. **Escrita Bloqueada**: Não modificar arquivos Markdown no Vault diretamente (`sed`, `echo` ou edição file-system padrão) a não ser que o usuário autorize ativamente.
4. Caso necessite atualizar de forma profunda o Vault ou se os mecanismos de update seguros estiverem offline, crie uma proposta de update em `docs/archive/VAULT_UPDATE_PROPOSAL.md`.

## Interação Segura com o Grafo e RAG

Ao interagir com o Brain/RAG, a ordem de prioridade de fontes é:
1. Código atual do projeto
2. Documentação atual em `docs/`
3. Notas derivadas em `ai/kryonix-vault/01-Canonical/`
4. Restante do Obsidian Vault acessado via CLI
5. A documentação oficial do produto upstream (NixOS, etc)

**Importante:**
- `docs/archive/` não deve ser indexado como fonte primária.
- `ROADMAP.md` deve ser indexado com status de planejado/parcial, nunca como implementado.
- Respostas do Brain devem priorizar `docs/` e notas de `01-Canonical`.

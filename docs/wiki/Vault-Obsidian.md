# Vault Obsidian

Status: Implementado (com regras de acesso)

## Resumo
O Vault Obsidian é o cérebro técnico do projeto. O acesso deve ser feito via CLI do Kryonix para manter governança e segurança.

## Caminho padrão
- `/home/rocha/.local/share/kryonix/kryonix-vault`
- Override: `LIGHTRAG_VAULT_DIR`.

## Regras essenciais
- `docs/` é a fonte canônica.
- Não editar o Vault diretamente sem autorização.
- Usar `kryonix vault ...` para operações.

## Quando usar
Ao consultar conhecimento técnico via Brain/RAG ou auditar notas.

## Comandos relevantes
```sh
kryonix brain health
kryonix vault scan
kryonix vault index
```

## Riscos
- Escrever diretamente no Vault sem aprovação.
- Indexar conteúdo de `docs/archive` como fonte primária.

## Links relacionados
- [Brain, RAG e CAG](Brain-RAG-CAG)
- [MCP](MCP)
- [Segurança](Seguranca)

# Runbook: Obsidian e Memória Local

## Superfícies

- app desktop: launcher do sistema, vault local, plugins e UI
- Obsidian CLI: leitura e operações a partir do vault
- Obsidian Headless: sync sem app desktop

## Regras

- não assumir que Headless Sync está instalado
- não inventar caminho de vault
- documentar quando a operação depende de vault ativo, vault nomeado ou path explícito

## Referências operacionais

- URI para escolher vault: `obsidian://choose-vault`
- CLI usa parâmetros como `file=<name>` ou `path=<path>`
- Headless Sync usa `ob sync-setup`, `ob sync`, `ob sync-status`

## Uso neste repositório

- o app desktop atual é exposto pelo launcher local
- o wrapper primário é `kryonix-obsidian`; `rag-obsidian` fica só como compatibilidade temporária
- remoto oficial do vault: `https://github.com/RAGton/kryonix-vault.git`
- qualquer camada de memória/IA deve tratar o vault como dado do usuário, não como arquivo do repositório

# Kryonix Home Brain

O **Kryonix Home Brain** é um subsistema de organização inteligente e segura para a sua Home. Ele utiliza uma taxonomia declarativa e um motor determinístico para sugerir nomes e categorias para seus arquivos, com um fluxo de trabalho auditável e reversível.

## Características Principais

- **Taxonomia Declarativa:** Categorias baseadas em palavras-chave e extensões definidas em `home-taxonomy.toml`.
- **Renomeação ABNT-like:** Padronização de nomes (Ex: `2024-05-09_Título_v1.pdf`).
- **Segurança Transacional:** Fluxo `scan -> plan -> manifest -> apply`. Nada é alterado sem o seu consentimento explícito.
- **Rollback Instantâneo:** Possibilidade de reverter qualquer aplicação de manifesto.
- **Memory Bridge:** Exportação de metadados para o Kryonix Brain (RAG/Graph).
- **Anti-Overwrite:** Proteção contra sobrescrita de arquivos existentes.

## Estrutura de Diretórios

- **Entrada:** `~/Downloads` (diretório padrão de triagem).
- **Destinos:** Organizados conforme a taxonomia (Ex: `~/Documentos/Financeiro/Bancos`).
- **Conflitos:** Arquivos com empate de confiança vão para `~/Documentos/00_Inbox/Conflitos`.
- **Estado:** Localizado em `~/.local/state/kryonix/home-brain/`.

## Comandos Rápidos

```bash
kryonix home scan                             # Escaneia arquivos
kryonix home plan --taxonomy --rename --why   # Mostra o que seria feito e o motivo
kryonix home apply --confirm                  # Executa as mudanças do manifesto
kryonix home rollback                         # Reverte a última mudança
```

Para mais detalhes, veja o [DAILY_WORKFLOW.md](./DAILY_WORKFLOW.md).

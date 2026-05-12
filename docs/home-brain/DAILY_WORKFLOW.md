# Fluxo Diário Recomendado

Siga estes passos para manter sua Home organizada com o Kryonix Home Brain.

## 1. Escaneamento Inicial
O primeiro passo é identificar o que há de novo no seu diretório de Downloads.
```bash
kryonix home scan
kryonix home report
```

## 2. Visualização do Plano
Antes de qualquer ação, veja o que o sistema sugere e por que.
```bash
kryonix home plan --taxonomy-suggestions --rename-suggestions --why
```
Se preferir processar os dados programaticamente (com `jq`), use o formato JSON:
```bash
kryonix home plan --json --taxonomy-suggestions --rename-suggestions
```

## 3. Revisão de Categorias e Explicações
Se você não entende por que um arquivo foi classificado de certa forma:
```bash
kryonix home explain ~/Downloads/seu-arquivo.pdf
```
Para ver todas as categorias disponíveis:
```bash
kryonix home categories
```

## 4. Criação do Manifesto
O manifesto é o contrato do que será executado.
```bash
kryonix home manifest create --taxonomy-suggestions --rename-suggestions
```
Você pode revisar o manifesto criado em:
```bash
kryonix home manifest show
```

## 5. Simulação e Aplicação
Sempre simule antes de confirmar.
```bash
kryonix home apply --dry-run
```
Se o resultado for o esperado:
```bash
kryonix home apply --confirm
```

## 6. Reversão (Rollback)
Caso tenha cometido um erro ou mudado de ideia:
```bash
kryonix home rollback
```

## 7. Exportação de Memória
Para alimentar o seu Cérebro IA com o histórico de organização:
```bash
kryonix home export-memory --from latest-manifest --jsonl
```

---

## Boas Práticas

- **Downloads é Transitório:** Use o diretório Downloads como porta de entrada. O objetivo é mantê-lo limpo.
- **Revisão Manual:** Arquivos marcados com baixa confiança ou em diretórios de conflitos devem ser movidos manualmente para o local correto.
- **Frequência:** Rode o fluxo ao menos uma vez por dia para evitar acúmulo de arquivos.

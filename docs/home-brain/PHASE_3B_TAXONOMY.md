# Kryonix Home Brain — Guia de Taxonomia Declarativa (Fase 3B)

Este documento descreve as especificações técnicas da **Fase 3B — Taxonomia Declarativa e Auditável** do Kryonix Home Brain. Esta fase introduz um motor de inteligência organizacional baseado em regras determinísticas e explicabilidade.

---

## 1. Classificação Heurística e Motor de Decisão

Para evitar a necessidade de serviços de IA pesados em tarefas organizacionais simples, o `kryonix-home` implementa uma heurística de pontuação de palavras-chave altamente otimizada combinada com filtros de extensão de arquivo.

O algoritmo executa os seguintes passos para cada arquivo identificado pelo scanner:

1. **Normalização**: O nome do arquivo é convertido para minúsculas e caracteres especiais, pontuações e acentos são limpos.
2. **Match de Palavras-Chave**: O motor busca pelas palavras-chave cadastradas em cada categoria de taxonomia dentro do nome normalizado do arquivo.
3. **Cálculo de Score**:
   $$\text{Score} = \frac{\text{Keywords combinadas}}{\text{Total de Keywords da Categoria}}$$
4. **Filtro de Extensão**: Se a categoria tiver uma lista restrita de extensões permitidas e o arquivo não corresponder a nenhuma delas, ele é sumariamente desqualificado para aquela categoria.

---

## 2. Faixas de Confiança e Ações de Direcionamento

Com base no `score` calculado para a categoria com maior pontuação, o motor direciona o arquivo a uma faixa de confiança específica:

| Faixa de Score | Nível de Confiança | Pasta de Destino | `needs_review` | Detalhes |
| :--- | :--- | :--- | :---: | :--- |
| **[0.90 - 1.00]** | Excelente | `[Category.dir]` | `false` | Classificação exata. Arquivos de texto, código ou planilhas vão sem revisão. PDFs/imagens podem pedir revisão opcional. |
| **[0.75 - 0.89]** | Alta Confiança | `[Category.dir]` | `false` / `true` | Classificação forte. Arquivos leves de texto (`.txt`, `.md`, `.csv`) vão sem revisão. Formatos mais complexos ativam a flag. |
| **[0.45 - 0.74]** | Confiança Média | `[Category.dir]` | `true` | Classificação parcial. O arquivo é planejado para ir ao destino, mas a flag obriga revisão prévia do usuário no manifesto. |
| **[0.00 - 0.44]** | Baixa Confiança | `Documentos/00_Inbox/Baixa_Confianca` | `true` | Nenhum match forte encontrado. Desviado para triagem de baixa confiança na caixa de entrada. |
| **Nenhum Match** | Fallback | `Documentos/00_Inbox/Revisar` ou `[Mime.dir]` | `true` | Nenhuma palavra-chave correspondeu. Roteado para fallbacks por extensão (ex: screenshots vão para `Imagens/Revisar`, PDF/TXT para `00_Inbox/Revisar`). |

---

## 3. Heurísticas Especiais de Controle

### 3.1. Empates e Conflitos (Tie-Breaking)
Se um arquivo obtém pontuações idênticas em duas ou mais categorias distintas (por exemplo, `comprovante_banco_empresa.pdf` que atinge score idêntico para `financeiro.bancos` e `trabalho.geral`):
- O planejador **não** chuta uma categoria de forma aleatória.
- Ele detecta o conflito de score, atribui a categoria técnica `inbox.conflitos` e redireciona o arquivo para a pasta de entrada dedicada: `Documentos/00_Inbox/Conflitos`.
- O manifesto registra todos os IDs concorrentes no vetor `candidate_categories`.
- O campo `taxonomy_reason` explica detalhadamente os IDs que causaram a colisão.

### 3.2. Arquivo Já Organizado (`already_organized`)
Se o arquivo fisicamente já estiver localizado na pasta final ideal correspondente à sua taxonomia e seu nome já corresponder à regra de renomeação ou não precisar de renomeação:
- A flag `already_organized` é marcada como `true` no planejamento.
- O planejador **ignora** o arquivo nas propostas de movimentação física, economizando I/O de disco e mantendo a idempotência do sistema.

### 3.3. Prevenção de Sobrescrita (`destination_exists`)
Se o arquivo planejado for movido para um caminho de destino que já existe fisicamente em disco:
- **Mesmo Hash (SHA-256)**: Se o conteúdo dos dois arquivos for rigorosamente idêntico, a movimentação é marcada como `skipped` e pulada de forma segura (já está duplicada e organizada).
- **Hash Diferente**: A operação é categorizada com falha estrutural por colisão de destino (`destination_exists`). O arquivo original é mantido intacto em sua pasta de entrada, e a movimentação é cancelada para evitar perda de dados.

---

## 4. Campos de Auditoria Estendidos

Para fins de explicabilidade e rastreamento, o planejamento e os manifestos JSON registram metadados detalhados para cada proposta:

- `category_id`: Identificador técnico da categoria (ex: `"financeiro.bancos"`).
- `category_label`: Nome legível humano (ex: `"Financeiro / Bancos"`).
- `category_dir`: Diretório sugerido para o arquivo sob a Home.
- `taxonomy_score`: Score obtido (de `0.0` a `1.0`).
- `matched_keywords`: Lista de palavras-chave que deram match no nome.
- `taxonomy_reason`: Motivação textual descrevendo a heurística aplicada.
- `taxonomy_profile`: Nome do perfil de taxonomia ativo (embutido ou customizado).
- `candidate_categories`: Outras categorias concorrentes se houver empate.
- `needs_review`: Indica se requer auditoria visual do usuário.

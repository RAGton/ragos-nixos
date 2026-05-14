# Grounding vs Answerability

Este documento define os critérios de qualidade para as respostas geradas pelo Kryonix Brain, separando a capacidade de **recuperar** informações da capacidade de **responder** à pergunta.

## 1. Definições

### Retrieval Score (Similaridade)
O `retrieval_score` mede quão parecidos são os documentos encontrados em relação aos termos da pergunta. 
- Um score alto (> 0.7) significa que o Brain encontrou documentos que "falam sobre o assunto".
- **Limitação**: Similaridade semântica não garante que a resposta esteja contida no texto.

### Answerability Score (Suficiência)
O `answerability_score` mede se as evidências encontradas são suficientes para sintetizar uma resposta fundamentada.
- Um score alto (> 0.7) significa que a pergunta pode ser respondida com segurança.
- Um score baixo (< 0.4) indica que, embora os documentos possam ser parecidos, eles não contêm a resposta direta.

## 2. Rótulos de Grounding

O campo `grounding_label` (ou `confidence` no CLI) é agora derivado de ambos os scores:

| Answerability | Retrieval | Grounding Label | Significado |
| :--- | :--- | :--- | :--- |
| **Baixa (< 0.4)** | Qualquer | **Baixa** | Não há evidência suficiente, mesmo que haja similaridade. |
| **Média (0.4-0.6)** | Qualquer | **Média** | Resposta parcial ou com ressalvas. |
| **Alta (> 0.7)** | **Baixa (< 0.4)** | **Baixa** | Contexto existe mas a busca foi fraca. |
| **Alta (> 0.7)** | **Média (0.4-0.7)** | **Média** | Resposta confiável, mas com fontes distantes. |
| **Alta (> 0.7)** | **Alta (> 0.7)** | **Alta** | Resposta ideal: fontes próximas e conteúdo suficiente. |

## 3. O Problema da Contradição

Antes da Issue #39, o Brain frequentemente mostrava `Grounding: Alta` e respondia "Não encontrei informação". Isso acontecia porque apenas o `retrieval_score` era considerado.

Agora, se o `answerability_score` for baixo, o Grounding será forçado para **Baixa**, e o motivo será exibido:
> ⚠ Similaridade alta, mas cobertura insuficiente da intenção da pergunta.

## 4. Comportamento por Intenção

- **`search`**: Foca 100% no `retrieval_score`. O `answerability_score` é estimado apenas por cobertura de termos técnicos, sem validação profunda por LLM.
- **`ask`**: Valida a resposta final. Se o LLM disser que não sabe, o score de answerability cai drasticamente.

# Skill 04 — Qualidade das respostas

## Objetivo

Deixar respostas mais bonitas, organizadas, rápidas e menos alucinadas.

## Schema de resposta interno

Toda query deve retornar dict:

```json
{
  "status": "success|no_grounding|low_confidence|error",
  "answer": "...",
  "confidence": "Alta|Média|Baixa|None",
  "max_score": 0.0,
  "mode": "cag|rag|hybrid|mix|local|global|naive",
  "strategy": "...",
  "sources": [],
  "grounding": {},
  "warnings": []
}
```

## Resposta humana

Formato padrão:

```md
## Resposta direta

...

## Evidências usadas

1. arquivo | chunk | score

## Comandos

```bash
...
```

## Validação

...
```

## Anti-alucinação

- Se `sources=[]`, não responder como certeza.
- Se `max_score < threshold`, retornar `low_confidence`.
- Bloquear termos proibidos em perguntas sobre pipeline Kryonix.
- Nunca inventar arquivo, comando, serviço systemd ou path.
- Se a pergunta pede “como fazer”, incluir validação.

## Velocidade

- CAG para perguntas canônicas.
- RAG com top_k menor por padrão.
- Reranker opcional desligado por padrão.
- Cache de resposta ligado, mas `--no-cache` funcional.
- `OLLAMA_KEEP_ALIVE` configurável.
- Perfis:
  - `safe`
  - `balanced`
  - `query`
  - `quality`
  - `gaming`

## Eval

Criar:

```bash
rag eval run
rag eval report
```

Arquivo:

```txt
tests/evals/questions.yaml
```

Ver `config/eval_questions.yaml`.

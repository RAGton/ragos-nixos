# 08 — Recomendação sobre usar Gemini 3 Flash

## Veredito

Sim, recomendo usar Gemini 3 Flash/Antigravity para implementar a Fase 1, desde que o escopo seja muito bem limitado.

Ele é bom para:

- gerar estrutura Rust rapidamente;
- integrar CLI;
- criar parser com `clap`;
- escrever JSON/serde;
- criar relatórios;
- criar testes;
- adaptar ao padrão do repo.

## Não recomendo usar Gemini 3 Flash para

- decidir sozinho políticas de deleção;
- implementar IA autônoma apagando arquivos;
- mexer em todos os módulos do Kryonix de uma vez;
- alterar flake.lock sem necessidade;
- rodar switch;
- mexer em secrets;
- implementar RAG/Neo4j/daemon tudo no mesmo commit.

## Como usar corretamente

Faça em três prompts separados.

### Prompt 1

Implementar scanner seguro.

### Prompt 2

Implementar planner dry-run.

### Prompt 3

Integrar no flake/CLI e validar.

## Regra prática

Se o Gemini tentar fazer tudo de uma vez, interrompa e diga:

```txt
Reduza o escopo. Implemente apenas a Fase 1, sem IA, sem mover arquivos, sem deletar arquivos, sem daemon e sem Neo4j.
```

## Melhor estratégia

Use Gemini 3 Flash como executor de código, mas você controla a arquitetura.

O Kryonix não deve virar “IA autônoma descontrolada”.
Deve virar um sistema:

```txt
observa -> explica -> propõe -> valida -> aplica -> audita -> permite rollback
```

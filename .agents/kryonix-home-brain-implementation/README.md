# Kryonix Home Brain — Plano de Implementação

Este pacote contém o plano completo para implementar o módulo `kryonix home`, uma camada local, segura, auditável e declarativa para organizar a Home do usuário com Rust, NixOS, Kryonix Brain, RAG/CAG e Neo4j.

## Objetivo

Criar uma Home inteligente que:

- escaneia arquivos pessoais da Home;
- ignora pastas ocultas/configuração/projetos;
- detecta duplicatas com segurança;
- sugere organização sem mover por padrão;
- gera descrições e categorias;
- aplica padrão de nomes inspirado em ABNT;
- registra tudo em manifesto auditável;
- permite rollback;
- alimenta o Kryonix Brain como conhecimento;
- permite busca por conteúdo, local e descrição.

## Ordem recomendada

1. Ler `01-PLANO_IMPLEMENTACAO.md`.
2. Ler `02-ARQUITETURA.md`.
3. Usar `03-PROMPT_GEMINI_3_FLASH.md` no Gemini/Antigravity.
4. Aplicar somente a Fase 1 primeiro.
5. Validar com `04-CHECKLIST_VALIDACAO.md`.
6. Só depois avançar para IA/Ollama/RAG/Neo4j.

## Decisão importante

Na primeira fase, o sistema **não deve mover, renomear ou apagar arquivos reais**.

O objetivo inicial é:

```bash
kryonix home scan
kryonix home report
kryonix home duplicates
kryonix home plan --dry-run
```

## Veredito

Use Gemini 3 Flash para gerar e aplicar código, mas com escopo restrito, commits pequenos e validação obrigatória.

Não peça para ele implementar tudo de uma vez.

# Compact Reporting

Para economizar tokens:

## Use sempre

```bash
git diff --stat
git diff -- <arquivo>
rg -n "termo" <pastas>
sed -n '1,160p' arquivo
```

## Evite

- Colar arquivo inteiro.
- Repetir plano já aprovado.
- Explicar conceitos genéricos.
- Rodar busca ampla sem necessidade.

## Relatório padrão

```txt
Feito:
- item

Arquivos:
- path: motivo

Validação:
- comando: OK/FAIL

Riscos:
- item

Próximo:
- item
```

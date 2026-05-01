# Documentation Audit Workflow

## Quando usar
Sempre que houver alterações em arquivos dentro de `docs/` ou antes de finalizar qualquer tarefa.

## Regras aplicadas
- `.agents/rules/10-documentation.md`
- `.agents/rules/90-definition-of-done.md`

## Entradas
- Arquivos de documentação modificados.
- Scripts de auditoria (`scripts/doc-audit.sh`).

## Saídas
- Relatório de conformidade no console.
- Correções em documentos se necessário.

## Arquivos permitidos
- `docs/**/*`
- `scripts/doc-audit.sh`

## Arquivos proibidos
- Mover arquivos de `docs/` para a raiz sem autorização.

## Passos
1. **Executar Script:** Rodar `./scripts/doc-audit.sh`.
2. **Revisar Erros:** Identificar quebras de links ou formatos.
3. **Corrigir:** Ajustar os arquivos conforme as mensagens de erro.
4. **Validar:** Rodar o script novamente até passar.

## Validação obrigatória
- O script `doc-audit.sh` deve retornar sucesso.

## Rollback
- Reverter alterações nos arquivos de documentação.

## Output final esperado
Documentação limpa, sem links quebrados e seguindo os padrões do Kryonix.

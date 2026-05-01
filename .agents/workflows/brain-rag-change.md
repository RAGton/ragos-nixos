# Brain & RAG Change Workflow

## Quando usar
Para alterações na lógica do Brain, ingestão de dados ou mudanças na estrutura do RAG/LightRAG.

## Regras aplicadas
- `.agents/rules/50-rag-brain.md`
- `.agents/rules/20-testing.md`

## Entradas
- Novos documentos ou alterações no código da API do Brain.

## Saídas
- Grafo atualizado ou novos chunks ingeridos.
- Testes de busca (smoke search) passando.

## Arquivos permitidos
- `packages/kryonix-brain-lightrag/**/*`
- `ai/kryonix-vault/**/*`

## Passos
1. **Preparar:** Isolar o novo conteúdo ou alteração.
2. **Ingerir/Modificar:** Executar a alteração no código ou storage.
3. **Validar Grafo:** Verificar integridade com `kryonix graph stats`.
4. **Testar Busca:** Realizar buscas de teste para garantir grounding correto.

## Validação obrigatória
- A resposta do Brain deve ser fundamentada na alteração realizada.

## Rollback
- Reverter storage do LightRAG a partir do backup.

## Output final esperado
Brain respondendo com maior precisão e novos conhecimentos integrados.

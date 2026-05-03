# Kryonix Brain MCP — Protocolo de Segurança

O servidor MCP do Kryonix Brain foi endurecido para garantir a integridade do sistema e do Vault. Operações de escrita direta foram substituídas por um fluxo de **propostas**.

## Ferramentas Disponíveis

### Pesquisa e Consulta
- `rag_search`: Busca híbrida no grafo com síntese.
- `rag_stats`: Estatísticas de nós e arestas.
- `rag_health`: Diagnóstico de integridade.
- `obsidian_search`: Busca notas no vault.
- `obsidian_read`: Lê conteúdo de uma nota.

### Aprendizado Seguro (Propostas)
- `brain_learn_propose`: Envia conteúdo para a fila de ingestão. Requer aprovação manual via CLI ou API.
- `brain_note_propose`: Cria uma proposta de nota em `00-inbox/ai-proposals/`.
- `brain_events_log`: Registra eventos técnicos no log do sistema.

### Manutenção (Dry-Run)
- `graph_repair_dry_run`: Diagnóstico de reparo do grafo (sem alteração de arquivos).
- `rag_repair_vdb_dry_run`: Diagnóstico de integridade do Vector DB.

## Fluxo de Aprendizado Controlado

Para que a IA "aprenda" algo novo ou crie uma nota, ela deve usar as ferramentas de proposta:

1.  **A IA propõe**: O conteúdo é salvo em uma fila (JSON) ou pasta de inbox no Vault.
2.  **Scanner de Segurança**: O sistema remove automaticamente tokens e segredos detectados.
3.  **Humano Revisa**: O operador do Kryonix revisa a proposta.
4.  **Aprovação**:
    - Para ingestão no grafo: `kryonix brain ingest approve <id>`.
    - Para notas no vault: O humano move a nota da pasta `00-inbox/ai-proposals` para o local definitivo.

## Configuração do Cliente

Use o template em `.mcp.example.json` para configurar seu cliente (ex: Claude Desktop, Cursor, Antigravity).

```json
{
  "mcpServers": {
    "kryonix-brain": {
      "command": "uv",
      "args": [
        "--quiet",
        "run",
        "--project",
        "/etc/kryonix/packages/kryonix-brain-lightrag",
        "kryonix-brain-mcp"
      ],
      "env": {
        "KRYONIX_BRAIN_KEY": "sua-chave-aqui"
      }
    }
  }
}
```

> [!IMPORTANT]
> Nunca coloque sua `KRYONIX_BRAIN_KEY` real em arquivos versionados. Use variáveis de ambiente ou o arquivo `.mcp.json` (que está no `.gitignore`).

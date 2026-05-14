# MCP

Status: Parcial (configuração ativa, validação contínua)

## Resumo
O Model Context Protocol (MCP) expõe ferramentas do Kryonix para agentes via JSON-RPC, mantendo segurança e controle de acesso.

## Servidores MCP principais
- **kryonix-brain** (remoto no Glacier).
- **mcp-nixos** (consulta opções/pacotes).
- **filesystem** (vault read-only).
- **github** (opcional, via token).

## Configuração canônica
- Codex: `.codex/config.toml`.
- Outros clientes: `.mcp.json` (derivado de `.mcp.example.json`).

## Quando usar
Para integrar agentes (Claude/Cursor/Codex) ao contexto do projeto.

## Comandos relevantes
```sh
kryonix mcp check
kryonix mcp doctor
./scripts/check-mcp.sh
pytest -q packages/kryonix-brain-lightrag/tests/test_mcp_*.py
```

## Riscos
- Secrets em `.mcp.json`.
- Paths não absolutos ou apontando para `/`.

## Links relacionados
- [Segurança](Seguranca)
- [Brain, RAG e CAG](Brain-RAG-CAG)
- [Vault Obsidian](Vault-Obsidian)

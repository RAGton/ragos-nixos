# Segurança

Status: Implementado (políticas ativas)

## Resumo
Segurança no Kryonix é prioridade: secrets fora do Git, portas mínimas e acesso remoto restrito.

## Secrets e credenciais
- Nunca commitar `.mcp.json`, `brain.env`, `neo4j.env`.
- Segredos ficam fora do Nix store.
- API key do Brain: `KRYONIX_BRAIN_API_KEY` em `/etc/kryonix/brain.env` (0600).

## Rede e portas conhecidas
- SSH Glacier: `2224`
- Brain API: `8000`
- Ollama: `11434`

## Quando usar
Antes de expor serviços ou configurar acesso remoto.

## Comandos relevantes
```sh
kryonix mcp check
kryonix brain api-key generate
kryonix brain api-key validate
```

## Riscos
- Exposição indevida de portas fora de LAN/Tailscale.
- Secrets em arquivos versionados.

## Links relacionados
- [MCP](MCP)
- [Brain, RAG e CAG](Brain-RAG-CAG)
- [Operações](Operacoes)

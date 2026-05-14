# Inspiron

Status: Implementado (cliente/workstation)

## Resumo
Inspiron é o cliente leve do Kryonix. Ele roda Hyprland/Caelestia e utiliza o Glacier como backend de IA.

## Papel do host
- Workstation diária e desenvolvimento.
- Cliente do Brain via rede (LAN/Tailscale).
- Não exige Ollama ou LightRAG local por padrão.

## Quando usar
Para operações locais de desktop e validações client-side.

## Comandos relevantes
```sh
kryonix test client
kryonix brain health
kryonix mcp check
```

## Riscos
- Esperar runtime local de IA quando o host é cliente.
- Tratar falhas do Glacier como erro fatal no cliente.

## Links relacionados
- [Hosts](Hosts)
- [Glacier](Glacier)
- [Brain, RAG e CAG](Brain-RAG-CAG)

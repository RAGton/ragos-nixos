# Arquitetura

Status: Implementado (arquitetura atual)

## Resumo
A arquitetura do Kryonix separa cliente e servidor, organiza hosts por Flake e centraliza operações na CLI `kryonix`.

## Separação cliente/servidor
- **Inspiron (cliente):** operação diária, desktop, CLI e acesso remoto.
- **Glacier (servidor):** IA local, Ollama, Brain API, LightRAG e Neo4j.

```
Inspiron (cliente)
  -> LAN/Tailscale
  -> Glacier (servidor)
  -> Brain API :8000
  -> Ollama :11434
```

## Componentes principais
- **Flake:** `flake.nix` define hosts, homes, pacotes e checks.
- **Hosts:** `hosts/<host>/default.nix` define papel e hardware.
- **CLI:** `packages/kryonix-cli.nix` centraliza operações.
- **Brain:** `packages/kryonix-brain-lightrag/` e módulos `kryonix.services.*`.

## Status por componente (resumo)
- **Ollama (Glacier):** Implementado.
- **Brain API:** Parcial (funciona, com pendências no Roadmap).
- **LightRAG local:** Implementado (V1).
- **CAG/cache:** Roadmap.
- **MCP remoto:** Parcial.

## Quando usar
Para entender dependências entre serviços e a divisão cliente/servidor.

## Comandos relevantes
```sh
nix flake show --all-systems
kryonix check
kryonix test client
kryonix test server
```

## Riscos
- Expor serviços de IA fora de LAN/Tailscale.
- Tratar runtime do Glacier como obrigatório no Inspiron.

## Links relacionados
- [Hosts](Hosts)
- [Brain, RAG e CAG](Brain-RAG-CAG)
- [Segurança](Seguranca)

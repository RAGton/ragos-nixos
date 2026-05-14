# Uso da CLI Kryonix

A CLI `kryonix` é o ponto de entrada operacional oficial do projeto.

## Fonte de Verdade
- **Auto-documentação:** `kryonix --help` (Derivado do `registry.sh`)
- **Introspecção:** `kryonix commands --json` (Para IAs e automação)
- **Validação:** Todos os comandos são registrados centralmente e validados via CI (`nix flake check`).

## Garantia de Execução
> Todos os comandos documentados são derivados diretamente do código-fonte real. O help da CLI é a única fonte de verdade operacional.

## Comandos Principais

```sh
kryonix doctor       # Avaliação rápida do host, flake e storage
kryonix doctor full  # Diagnóstico completo (docs, sistema, arquitetura, brain)
kryonix check        # Executa `nix flake check --keep-going`
kryonix fmt          # Executa o formatter da flake
kryonix diff         # Compara /run/current-system com a próxima geração
kryonix test         # Testa a geração NixOS sem persistir como default
kryonix boot         # Prepara a geração para o próximo boot
kryonix switch       # Aplica a configuração do host atual
kryonix home         # Aplica a configuração do Home Manager do usuário atual
kryonix iso          # Constroi a ISO a partir da configuração
kryonix git-status   # Status do git do repositório
```

## Kryonix Brain (Inteligência Artificial)

O `kryonix` fornece a interface local para operação do Brain e LightRAG via comandos diretos no shell.

```sh
kryonix brain health         # Mostra saúde do Brain local
kryonix brain stats          # Estatísticas do Brain
kryonix brain search "algo"  # Busca semântica
kryonix brain ask "algo"     # Pergunta para o agente/RAG
kryonix brain doctor --local # Checagem detalhada de permissões/serviços local
```

## Kryonix MCP (Model Context Protocol)

O MCP fornece interfaces JSON-RPC seguras para LLMs sob demanda.

```sh
kryonix mcp check        # Inspiron: check leve/local de config, paths e segurança (sem acionar RAG local)
kryonix mcp doctor       # Glacier: valida o runtime real do Brain MCP e dependências pesadas
```

### Regras de Ouro
- **Inspiron:** Validação leve e focada na segurança do cliente MCP (`kryonix mcp check`).
- **Glacier:** Servidor do runtime real do Brain e armazenamento pesado.
- **Segurança:** Nunca armazene tokens literais de API ou senhas em `.mcp.json`. Utilize wrappers locais (ex: `kryonix-github-mcp`) ou variáveis de ambiente.

Para o Codex, o arquivo canônico do projeto é `.codex/config.toml`. Clientes como Claude/Cursor continuam usando `.mcp.json`.

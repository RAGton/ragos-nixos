# CLI Kryonix

Status: Parcial (validação varia por comando)

## Resumo
A CLI `kryonix` é a interface operacional central para NixOS, Brain/IA e rotinas de host. Ela encapsula `nix`, `nh`, `nvd` e validações de segurança.

## Quando usar
- Para qualquer operação de sistema (check, test, boot, switch).
- Para operações de IA (brain, graph, mcp, vault).
- Para acesso remoto seguro (WayVNC).

## Comandos relevantes
### Principais (status conforme auditoria)
| Comando | Função | Status (2026-05-07) | Observação |
|---|---|---|---|
| `kryonix doctor` | Diagnóstico rápido | FUNCTIONAL | Baixo risco |
| `kryonix git-status` | Status do repo | FUNCTIONAL | Baixo risco |
| `kryonix fmt` | Formatter do flake | PARTIAL | Falhou por permissões no audit |
| `kryonix check` | `nix flake check` | UNKNOWN | Não validado nesta revisão |
| `kryonix test` | Teste runtime | UNKNOWN | Evita `switch` |
| `kryonix boot` | Prepara geração | UNKNOWN | Ação destrutiva |
| `kryonix switch` | Aplica geração | UNKNOWN | Ação destrutiva |

### IA e Brain
| Comando | Status | Observação |
|---|---|---|
| `kryonix brain health` | FUNCTIONAL | Remoto no Glacier |
| `kryonix brain stats` | FUNCTIONAL | Requer API key |
| `kryonix brain search` | FUNCTIONAL | RAG remoto |
| `kryonix brain cag` | FUNCTIONAL | CAG remoto |
| `kryonix mcp check` | PARTIAL | Depende de runtime local/SSH |
| `kryonix vault scan` | FUNCTIONAL | Varredura do vault |

### Acesso remoto WayVNC
```sh
kryonix remote vnc status
kryonix remote vnc start
kryonix remote vnc stop
```

## Regras de uso
- Para hosts remotos, use `--host` (ex.: `kryonix check --host glacier`).
- Evite `nix` direto quando o comando `kryonix` existir.
- Use `switch/boot` somente após validações.

## Riscos
- `switch` e `boot` alteram o sistema imediatamente.
- Comandos de IA dependem do Glacier e de secrets válidos.

## Links relacionados
- [Operações](Operacoes)
- [Testes e Validação](Testes-e-Validacao)
- [Brain, RAG e CAG](Brain-RAG-CAG)

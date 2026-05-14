# Estrutura do Repositório

Status: Implementado (estrutura atual)

## Resumo
A estrutura do repo separa hosts, módulos, perfis, desktop, pacotes e documentação canônica.

## Estrutura principal
| Diretório | Papel | Observações |
|---|---|---|
| `flake.nix` | Entrada do Flake | Outputs, inputs e checks |
| `hosts/` | Hosts NixOS | `glacier`, `inspiron`, `iso` |
| `modules/` | Módulos NixOS/Home | Base, serviços, desktop |
| `profiles/` | Perfis por papel | `glacier-*`, `laptop`, `server-ai` |
| `features/` | Capacidades opt-in | Gaming, dev, virtualização |
| `home/` | Home Manager | Usuário/host |
| `desktop/` | Hyprland/Caelestia | Stack do desktop |
| `packages/` | CLI e IA | `kryonix-cli`, Brain |
| `docs/` | Docs canônicas | Fonte oficial |
| `context/` | Histórico técnico | Decisões/incidentes |

## Arquivos sensíveis
- `flake.nix` / `flake.lock`
- `hosts/*/hardware-configuration.nix`
- `hosts/*/disks.nix`
- `.codex/config.toml` (sem secrets)
- `.mcp.json` (não versionado)

## Quando usar
Para localizar rapidamente onde alterar uma configuração.

## Comandos relevantes
```sh
ls -la
rg -n "kryonix\." hosts modules profiles
```

## Riscos
- Alterar `flake.lock` sem necessidade.
- Misturar hardware específico em módulos genéricos.

## Links relacionados
- [Arquitetura](Arquitetura)
- [NixOS, Flakes e Home Manager](NixOS-Flakes-e-Home-Manager)
- [Desenvolvimento e Contribuição](Desenvolvimento-e-Contribuicao)

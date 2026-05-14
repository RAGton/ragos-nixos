# Home

Kryonix é uma plataforma NixOS declarativa para workstation, gaming, virtualização, IA local, automação segura e operação diária via CLI.

Status: Implementado (Wiki)

## Resumo
Kryonix organiza hosts, módulos, perfis e automação com foco em segurança, rastreabilidade e validação. O repositório é a fonte de verdade operacional, e a CLI `kryonix` é o ponto central de operação.

## Para quem é
- Quem quer um NixOS declarativo, auditável e reproduzível.
- Quem precisa de um desktop real com Hyprland/Caelestia.
- Quem opera IA local com separação clara cliente/servidor.

## Qual problema resolve
- Reduz drift de configuração.
- Centraliza operações e validações via CLI.
- Mantém documentação honesta: implementado ≠ roadmap.

## Por que NixOS
- Configuração declarativa com Flakes.
- Reprodutibilidade e rollback controlado.
- Composição modular por host, perfil e feature.

## Por que a CLI `kryonix` é central
- Orquestra `nix`, `nh`, `nvd` e testes.
- Impõe fluxos seguros antes de ações destrutivas.
- Unifica operações de sistema, Brain e MCP.

## Índice por áreas

### Comece aqui
- [Visão Geral](Visao-Geral)
- [Início Rápido](Inicio-Rapido)
- [Filosofia do Kryonix](Filosofia-do-Kryonix)

### Arquitetura
- [Arquitetura](Arquitetura)
- [Estrutura do Repositório](Estrutura-do-Repositorio)
- [NixOS, Flakes e Home Manager](NixOS-Flakes-e-Home-Manager)

### Operação
- [CLI Kryonix](CLI-Kryonix)
- [Operações](Operacoes)
- [Testes e Validação](Testes-e-Validacao)
- [Troubleshooting](Troubleshooting)
- [WayVNC / Acesso Remoto](WayVNC-Acesso-Remoto)

### Hosts
- [Hosts](Hosts)
- [Glacier](Glacier)
- [Inspiron](Inspiron)

### Brain/IA
- [Brain, RAG e CAG](Brain-RAG-CAG)
- [MCP](MCP)
- [Vault Obsidian](Vault-Obsidian)

### Segurança
- [Segurança](Seguranca)

### Desenvolvimento
- [Desenvolvimento e Contribuição](Desenvolvimento-e-Contribuicao)

### Roadmap
- [Roadmap](Roadmap)

## Quando usar
Use esta página como porta de entrada para navegar na Wiki e entender a estrutura do projeto.

## Comandos relevantes
```sh
kryonix doctor
kryonix git-status
```

## Riscos
- Não execute `switch`/`boot` sem validação prévia.
- Não trate itens de Roadmap como implementados.

## Links relacionados
- [Visão Geral](Visao-Geral)
- [CLI Kryonix](CLI-Kryonix)
- [Segurança](Seguranca)

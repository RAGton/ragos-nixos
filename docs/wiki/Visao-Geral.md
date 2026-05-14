# Visão Geral

Status: Implementado (visão consolidada)

## Resumo
O Kryonix é uma plataforma NixOS declarativa com foco em operação via CLI, desktop Hyprland/Caelestia e IA local distribuída entre Glacier e Inspiron.

## Camadas do projeto
```
Kryonix
├── NixOS Flake
├── Hosts
├── Home Manager
├── Hyprland/Caelestia
├── CLI kryonix
├── Brain/RAG/CAG
├── MCP
├── Vault/Obsidian
├── Segurança
└── Roadmap de ISO/distro
```

## Quando usar
Para entender rapidamente o escopo do projeto e suas camadas principais.

## Comandos relevantes
```sh
nix flake show --all-systems
kryonix check
```

## Riscos
- Confundir camadas de runtime (cliente vs servidor).
- Usar comandos Nix diretos sem os hooks do `kryonix`.

## Links relacionados
- [Arquitetura](Arquitetura)
- [Estrutura do Repositório](Estrutura-do-Repositorio)
- [CLI Kryonix](CLI-Kryonix)

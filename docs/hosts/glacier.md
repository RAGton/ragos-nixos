# Host: Glacier

## Visão Geral
Glacier é o servidor principal do ecossistema Kryonix, atuando como o "Cérebro" (Brain Server) e workstation de alto desempenho/gaming.

## Hardware
- **CPU**: Ryzen 7 9700X (8 Cores / 16 Threads)
- **GPU**: NVIDIA RTX 4060 8GB
- **RAM**: 16GB DDR5
- **Rede**: 2.5Gb Ethernet
- **IP Fixo (LAN)**: `10.0.0.2`
- **Tailscale IP**: `100.108.71.36`

## Papéis (Profiles)
- **Server AI**: Hospeda Ollama, Brain API e Knowledge Graph.
- **Workstation Gamer**: Estação de trabalho Hyprland com suporte total a NVIDIA e Gaming (Steam).

## Serviços
- **Ollama**: Backend de LLM e Embeddings.
- **Kryonix Brain API**: Interface RAG para o projeto.
- **LightRAG Server**: Gerenciamento do Knowledge Graph.
- **Vault Storage**: Armazenamento do conhecimento técnico (Obsidian).
- **SSH**: Acesso remoto seguro.
- **Tailscale**: VPN mesh para integração com o host Inspiron.

## Configuração Declarativa
A configuração está localizada em `hosts/glacier/default.nix` e utiliza os perfis modulares em `profiles/server-ai.nix` e `profiles/workstation-gamer.nix`.

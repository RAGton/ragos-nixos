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
- **Workstation**: Hyprland/Caelestia e aplicativos gráficos, controlado por `kryonix.features.workstation.enable`.
- **Gaming**: Steam, GameMode, MangoHud e Gamescope, controlado por `kryonix.features.gaming.enable`.
- **OpenRGB**: RGB declarado por `kryonix.features.openrgb.enable`.

## Serviços
- **Ollama**: Backend de LLM e Embeddings.
- **Kryonix Brain API**: Interface RAG para o projeto.
- **LightRAG Server**: Gerenciamento do Knowledge Graph.
- **Vault Storage**: Armazenamento do conhecimento técnico (Obsidian).
- **SSH**: Acesso remoto seguro.
- **Tailscale**: VPN mesh para integração com o host Inspiron.

## Configuração Declarativa
A configuração está localizada em `hosts/glacier/default.nix`.

O perfil `server-ai` é obrigatório no Glacier. Workstation, gaming e OpenRGB são features separadas. Lutris e ferramentas Wine/Proton ficam desligadas por padrão para não puxar `openldap-i686-linux`; habilite explicitamente apenas quando esse caminho estiver buildável. O `nvtop` NVIDIA também fica opt-in porque puxa o CUDA toolkit completo e não é necessário para o servidor IA bootar.

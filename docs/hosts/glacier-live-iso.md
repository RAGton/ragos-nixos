# Glacier Live ISO (Minimal)

Este documento descreve a configuração e o uso da ISO live mínima para o host Glacier.

## Objetivo
A ISO `glacier-live` é projetada para ser um ambiente de diagnóstico leve e confiável para:
- Testar compatibilidade de hardware (NVIDIA, rede, discos).
- Validar conectividade via Tailscale.
- Preparar o ambiente para a futura migração para NixOS.
- Executar operações de disco sem alterar o sistema operacional atual (Windows).

## O que está incluído
- **Rede**: NetworkManager, OpenSSH, Tailscale.
- **Hardware**: pciutils, usbutils, lshw, btop.
- **Disco**: parted, gptfdisk, btrfs-progs.
- **Ferramentas**: git, curl, wget, vim, jq, rsync.

## O que NÃO está incluído (por design)
- Hyprland / Interface gráfica pesada.
- Stack de IA (Ollama, Kryonix Brain).
- Steam / Gaming.
- Flatpak.

## Como gerar a ISO
No host Inspiron (ou qualquer host com Nix):
```bash
nix build .#nixosConfigurations.glacier-live.config.system.build.isoImage --show-trace -L
```

## Localização do arquivo
Após o build, a ISO estará disponível no link simbólico `result/iso/`.

## Instalação
Esta ISO **não** instala o NixOS automaticamente. Ela é apenas um ambiente "live" para diagnóstico.

# Migração: Glacier Windows -> NixOS

Este documento descreve o plano de migração do servidor Glacier do Windows 11 para o NixOS, garantindo a preservação dos dados do Brain e a continuidade dos serviços.

## Fase 1: Blueprint (Atual)
- Criação dos arquivos `.nix` em `hosts/glacier/`.
- Definição dos perfis `server-ai` e `workstation-gamer`.
- Validação via `nix flake check`.

## Fase 2: Backup e Preparação
1. **Backup do Brain**: Copiar `C:\Users\aguia\Documents\kryonix-vault\11-LightRAG\rag_storage` para um drive externo ou cloud.
2. **Backup do Vault**: Sincronizar o Obsidian Vault completamente.
3. **Mapeamento de HW**: Confirmar UUIDs dos discos e nomes de interfaces de rede (`ip link`).

## Fase 3: Instalação
1. **Live USB**: Usar a ISO do Kryonix (`nix build .#nixosConfigurations.iso.config.system.build.isoImage`).
2. **Particionamento**: 
   - Recomendado usar BTRFS com subvolumes (`@`, `@home`, `@nix`).
   - Usar `disko` ou particionamento manual seguindo o `hardware-configuration.nix`.
3. **Instalação**: `nixos-install --flake .#glacier`.

## Fase 4: Restauração de Dados
1. **Vault**: Montar o storage no caminho `/var/lib/kryonix/vault`.
2. **Brain Storage**: Restaurar o `rag_storage` em `/var/lib/kryonix/brain/storage`.
3. **Permissões**: `chown -R kryonix-brain:kryonix-brain /var/lib/kryonix/brain`.

## Fase 5: Validação Pós-Migração
1. **Local**: Rodar `kryonix brain stats` no novo Glacier.
2. **Remoto**: Validar acesso do Inspiron via Tailscale.
3. **Gaming**: Testar drivers NVIDIA e Steam.

## Riscos e Mitigação
- **Perda de Dados**: Mitigado por múltiplos backups do Vault e Storage.
- **Incompatibilidade NVIDIA**: Mitigado pelo uso de perfis testados com `modesetting` e Wayland.
- **Downtime**: O Inspiron continuará funcional, mas sem IA durante a migração (algumas horas).

## Rollback
Caso a instalação falhe ou o hardware não responda, o Windows poderá ser restaurado a partir de uma imagem de disco ou reinstalado, reativando os serviços via `rag.bat` no ambiente original.

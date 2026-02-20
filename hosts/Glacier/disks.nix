### Host: Glacier — Layout de disco (documentação / base para disko)
### Autor: rag
###
### O que é
### - Documento do particionamento do host Glacier.
### - Exemplo de configuração no formato do `nix-community/disko`.
###
### Por quê
### - Evita “perder” o layout real do disco ao longo do tempo.
### - Serve como referência rápida em manutenção (ex.: troca de SSD).
### - Pode ser reaproveitado em reinstalações futuras com o disko.
###
### Como
### - Este arquivo NÃO é importado pelo NixOS em runtime.
### - Ele descreve `disko.devices` (inócuo se o disko não estiver sendo usado).
### - Ajuste `device = ...` para um caminho estável (`/dev/disk/by-id/...`) antes de usar em produção.
###
### Riscos
### - Se você aplicar isso sem conferir `/dev/disk/by-id`, pode particionar o disco errado.
### - Tamanhos (ex.: ESP) e UUIDs/labels precisam refletir o estado real da máquina.
###
### Estado atual (05/01/2026)
### - nvme0n1p1 -> /boot (vfat, LABEL BOOT-NIXOS, UUID A0E7-AB3A)
### - nvme0n1p3 -> btrfs (UUID 3c142e78-a12a-4c84-82c5-a2e1ecac74d3)
###   - subvol=@     montado em /
###   - subvol=@home montado em /home
### - swap: não configurado (swapDevices = [ ])
###
### Nota
### - Em runtime, `/nix/store` pode aparecer como mount separado, mas está dentro do subvolume `@`.

{ lib, ... }:
{
  # O disko lê esta árvore quando o módulo `nix-community/disko` é importado.
  # Sem o disko, este attrset não tem efeito (serve apenas como documentação).
  disko.devices = {
    disk."nvme0n1" = {
      type = "disk";
      # Dica (segurança): prefira um caminho estável em vez de /dev/nvme0n1.
      # Exemplo: device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB512...";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            # Partição EFI (ESP). Ajuste o tamanho conforme o disco real.
            size = "2G";
            type = "ef00"; # EFI System
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            size = "100%";
            type = "8300"; # Linux filesystem
            content = {
              type = "btrfs";
              # extraArgs = [ "-L" "RAIZ-NIXOS" ]; # opcional
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [ "subvol=@" "compress=zstd:3" "noatime" "ssd" "discard=async" "space_cache=v2" ];
                };

                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "subvol=@home" "compress=zstd:3" "noatime" "ssd" "discard=async" "space_cache=v2" ];
                };

                # Subvolume dedicado para snapshots (Snapper/backup), se você quiser separar de /.
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "subvol=@snapshots" "compress=zstd:3" "noatime" "ssd" "discard=async" "space_cache=v2" ];
                };
              };
            };
          };
        };
      };
    };
  };
}

# Layout de disco para o host "inspiron" (modo documentação/disko)
#
# Este arquivo NÃO é importado pelo NixOS em runtime. Ele serve para:
# - Documentar o particionamento atual
# - Ser usado como base para dizo/disko em reinstalações futuras
#
# Baseado em:
#   nvme0n1p1  -> /boot (vfat, UUID 954A-B524)
#   nvme0n1p2  -> btrfs RAIZ-NIXOS (UUID a551eedc-61b1-458b-8d4d-99e7ddcc0b1a)
#                  subvol=@ (/)  subvol=@home (/home)
#   nvme0n1p3  -> swap (UUID 6e5e19fc-82c8-4436-89c3-da8ed8cfb12b)
#   sda1       -> btrfs NIXOS-DATA (UUID 06b5fe17-f758-4172-98e7-04287590a710)
#
# Exemplo de configuração no estilo disko (ajuste /dev/disk/by-id conforme sua máquina):

{ lib, ... }:
{
  # Esta seção é reconhecida por módulos como nix-community/disko,
  # mas é inócua se não houver nenhum módulo lendo `disko.devices`.
  disko.devices = {
    disk."nvme0n1" = {
      type = "disk";
      # Dica: trocar pelo caminho estável correto, ex:
      # device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB512...";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
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
               extraArgs = [ "-L" "RAIZ-NIXOS" ]; # opcional
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [ "subvol=@" "compress=zstd" "noatime" ];
                };

                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "subvol=@home" "compress=zstd" "autodefrag" "noatime" ];
                };

                # Subvolume dedicado para snapshots manuais/snapper, se quiser
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "subvol=@snapshots" "compress=zstd" "noatime" ];
                };
              };
            };
          };

          swap = {
            # Em instalações novas dá pra trocar para tamanho fixo (ex: "8G");
            # aqui deixamos como comentário porque o swap atual já existe.
            # size = "8G";
            type = "8200"; # Linux swap
            content = {
              type = "swap";
            };
          };
        };
      };
    };

    # Disco de dados (NIXOS-DATA) opcional, bom para backups/jogos pesados
    disk."sda" = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          type = "8300";
          content = {
            type = "btrfs";
             extraArgs = [ "-L" "NIXOS-DATA" ];
            subvolumes = {
              "@data" = {
                mountpoint = "/mnt/data";
                mountOptions = [ "subvol=@data" "compress=zstd" "noatime" ];
              };

              "@games" = {
                mountpoint = "/mnt/games";
                mountOptions = [ "subvol=@games" "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}

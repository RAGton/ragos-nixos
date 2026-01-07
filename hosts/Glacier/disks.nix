### Layout de disco para o host "Glacier" (modo documentação/disko)
###
### Este arquivo NÃO é importado pelo NixOS em runtime. Ele serve para:
### - Documentar o particionamento atual
### - Ser usado como base para disko em reinstalações futuras
###
### Estado atual (05/01/2026):
###   nvme0n1p1  -> /boot (vfat, LABEL BOOT-NIXOS, UUID A0E7-AB3A)
###   nvme0n1p3  -> btrfs (UUID 3c142e78-a12a-4c84-82c5-a2e1ecac74d3)
###                subvol=@ (/)  subvol=@home (/home)
###   swap: não configurado (swapDevices = [ ])
###
### Observação: em runtime, `/nix/store` pode aparecer como um mount separado,
### mas ele está dentro do subvolume `@`.
###
### Exemplo de configuração no estilo disko (ajuste /dev/disk/by-id conforme sua máquina):

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
            # lsblk mostra ~2G (aprox.). Ajuste conforme seu particionamento.
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

                # Subvolume dedicado para snapshots manuais/snapper, se quiser
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

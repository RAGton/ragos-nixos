# Layout de disco para o host "inspiron" (modo documentação/disko)
#
# Este arquivo é usado pelo `disko` SOMENTE quando a ISO instaladora chama ele.
# Em runtime, quem monta os FS é o `hardware-configuration.nix`.
#
# Estado atual (hardware-configuration.nix):
# - /boot: vfat (UUID AF09-FA74)
# - /, /home, /nix, /var/log, /var/cache, /var/lib/containers, /var/libvirt,
#   /.snapshots, /persist, /tmp: btrfs no mesmo UUID 4d5e25fc-322d-4993-99f5-85e7e299a184
# - /RAG-DATA: btrfs separado (UUID ec9d75cd-877d-4f66-9a6b-cfe7eb5ca9f0) — não automatizado aqui
# - swap: UUID 5ccb5cb3-75b1-4e05-918e-5000bed16da3 — não automatizado aqui
#
# Observação importante:
# - Este `disks.nix` NÃO cria /RAG-DATA nem swap — ele foca no disco do sistema.

{ lib, ... }:
{
  disko.devices = {
    disk."nvme0n1" = {
      type = "disk";
      # Dica: trocar pelo caminho estável correto, ex:
      # device = "/dev/disk/by-id/nvme-...";
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
              mountOptions = [ "fmask=0022" "dmask=0022" ];
            };
          };

          root = {
            size = "100%";
            type = "8300"; # Linux filesystem
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "RAIZ-NIXOS" ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [ "subvol=@" "compress=zstd" "noatime" ];
                };

                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "subvol=@home" "compress=zstd" "autodefrag" "noatime" ];
                };

                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "subvol=@nix" "compress=zstd" "noatime" ];
                };

                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [ "subvol=@log" "compress=zstd" "noatime" ];
                };

                "@cache" = {
                  mountpoint = "/var/cache";
                  mountOptions = [ "subvol=@cache" "compress=zstd" "noatime" ];
                };

                "@containers" = {
                  mountpoint = "/var/lib/containers";
                  mountOptions = [ "subvol=@containers" "compress=zstd" "noatime" ];
                };

                "@libvirt" = {
                  mountpoint = "/var/libvirt";
                  mountOptions = [ "subvol=@libvirt" "compress=zstd" "noatime" ];
                };

                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "subvol=@snapshots" "compress=zstd" "noatime" ];
                };

                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "subvol=@persist" "compress=zstd" "noatime" ];
                };

                "@tmp" = {
                  mountpoint = "/tmp";
                  mountOptions = [ "subvol=@tmp" "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}

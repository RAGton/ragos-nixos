# Layout de disco para o host "glacier" (disko)
#
# Hardware: AMD Ryzen 7 9700X + RTX 4060 + 16 GB DDR5
#
# ⚠️  ANTES DE USAR: substitua o device abaixo pelo ID real do disco.
#     Para descobrir: ls -la /dev/disk/by-id/ | grep nvme
#
# Layout do NVMe:
#   p1 = EFI  (1G)    → /boot
#   p2 = swap (16G)   (DDR5 rápida; 16G é suficiente para hibernação)
#   p3 = btrfs SISTEMA (~300G) → @, @nix, @log, @cache, @containers, @libvirt,
#        @snapshots, @persist, @tmp
#   p4 = btrfs HOME   (restante) → @home
#
# Uso no Live CD:
#   sudo nix run github:nix-community/disko -- --mode disko ./hosts/glacier/disks.nix

{ lib, ... }:

let
  # TODO: substitua pelo ID real após `ls -la /dev/disk/by-id/`
  # Exemplo: nvme-WD_BLACK_SN850X_1000GB_xxxxxxxxxxxxxxxx
  nvmeId = "nvme-PLACEHOLDER_SUBSTITUA_PELO_ID_REAL";
in
{
  disko.devices = {
    disk."nvme0n1" = {
      type = "disk";
      device = "/dev/disk/by-id/${nvmeId}";
      content = {
        type = "gpt";
        partitions = {

          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };

          swap = {
            size = "16G";
            content = {
              type = "swap";
            };
          };

          system = {
            size = "300G";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "NIXOS-SYSTEM"
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@cache" = {
                  mountpoint = "/var/cache";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@containers" = {
                  mountpoint = "/var/lib/containers";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@libvirt" = {
                  mountpoint = "/var/lib/libvirt";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@tmp" = {
                  mountpoint = "/tmp";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };

          home = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "NIXOS-HOME"
              ];
              subvolumes = {
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "autodefrag"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}

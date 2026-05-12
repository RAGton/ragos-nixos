# Layout de disco para o host "inspiron-nina" (disko)
#
# Inspiron 15 com SSD/NVMe único de 500 GB.
# Layout proposto:
# - EFI: 1G
# - swap: 8G
# - btrfs sistema: 220G
# - btrfs home: restante do disco
#
# Ajuste `device` se o NVMe aparecer com outro nome durante a instalação.
{ ... }:
{
  disko.devices = {
    disk."nvme0n1" = {
      type = "disk";
      device = "/dev/nvme0n1";
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
            size = "8G";
            content.type = "swap";
          };

          system = {
            size = "220G";
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

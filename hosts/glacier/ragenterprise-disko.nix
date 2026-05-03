# Layout declarativo do storage extra do Glacier.
#
# Use este arquivo somente para o disco extra:
#   /dev/disk/by-id/ata-ST1000DM003-1ER162_S4Y12Q7Z
#
# O objetivo e converter o filesystem atual em disco inteiro para uma unica
# particao GPT/ext4 sem quebrar o mount existente em /srv/ragenterprise.

{
  disko.devices = {
    disk.ragenterprise = {
      type = "disk";
      device = "/dev/disk/by-id/ata-ST1000DM003-1ER162_S4Y12Q7Z";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/srv/ragenterprise";
              mountOptions = [
                "defaults"
                "nofail"
                "x-systemd.device-timeout=10s"
              ];
              extraArgs = [
                "-L"
                "RAGENTERPRISE"
                "-U"
                "479c1b04-5000-424d-90ae-f2438496711e"
              ];
            };
          };
        };
      };
    };
  };
}

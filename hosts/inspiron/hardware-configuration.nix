# Hardware configuration para o host "inspiron"
#
# Layout do NVMe (ADATA 512GB) — gerenciado pelo disko (disks.nix):
#   part1 = EFI (1G)          → /boot
#   part2 = swap (16G)
#   part3 = btrfs SISTEMA     → @, @nix, @log, @cache, etc (PODE FORMATAR)
#   part4 = btrfs HOME        → @home (NUNCA FORMATAR)
#
# SDA (Kingston 240G) — NÃO gerenciado pelo disko:
#   part1 = btrfs RAG-DATA    → /RAG-DATA (NUNCA FORMATAR)
#
# NOTA: O disko gera automaticamente entradas fileSystems para o NVMe usando
#       PARTLABEL (ex: disk-nvme0n1-system). Essas entradas são sobrescritas
#       abaixo com UUID para maior confiabilidade no boot.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # ─── NVMe p1: EFI — override com UUID (substitui PARTLABEL do disko) ───
  fileSystems."/boot" = lib.mkForce
    { device = "/dev/disk/by-uuid/4509-A31C";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  # ─── NVMe p3: SISTEMA — override com UUID (substitui PARTLABEL do disko) ───
  # O disko gera device = "/dev/disk/by-partlabel/disk-nvme0n1-system"
  # que falha se o PARTLABEL não estiver presente no disco.
  # UUID é definido pelo mkfs.btrfs e persiste enquanto o filesystem existir.
  fileSystems."/" = lib.mkForce
    { device = "/dev/disk/by-uuid/9d31dd94-2893-4c2a-bc47-bb2c4a8d55fc";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd" "noatime" ];
    };

  # ─── SDA: RAG-DATA (NÃO gerenciado pelo disko) ───
  fileSystems."/RAG-DATA" =
    { device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7785682AEA-part1";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" ];
    };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a551eedc-61b1-458b-8d4d-99e7ddcc0b1a";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd:3" "noatime" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/954A-B524";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/a551eedc-61b1-458b-8d4d-99e7ddcc0b1a";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:3" "autodefrag" "noatime" ];
  };


  swapDevices =
    [ { device = "/dev/disk/by-uuid/6e5e19fc-82c8-4436-89c3-da8ed8cfb12b"; }
    ];

  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

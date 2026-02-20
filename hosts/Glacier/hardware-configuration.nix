{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3c142e78-a12a-4c84-82c5-a2e1ecac74d3";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" "ssd" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/3c142e78-a12a-4c84-82c5-a2e1ecac74d3";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" "ssd" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A0E7-AB3A";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}

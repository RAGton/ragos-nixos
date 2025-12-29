{ lib, ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a551eedc-61b1-458b-8d4d-99e7ddcc0b1a";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/a551eedc-61b1-458b-8d4d-99e7ddcc0b1a";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/954A-B524";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/6e5e19fc-82c8-4436-89c3-da8ed8cfb12b"; }
  ];
}

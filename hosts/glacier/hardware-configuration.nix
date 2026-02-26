# Hardware configuration para o host "glacier"
#
# AMD Ryzen 7 9700X + NVIDIA RTX 4060 (Ada Lovelace)
#
# ⚠️  GERE O ARQUIVO REAL após instalar:
#       nixos-generate-config --show-hardware-config
#     e substitua este arquivo pelo conteúdo gerado.
#
# Módulos mínimos necessários para boot AMD + NVMe.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Módulos initrd para AMD + NVMe
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "usbhid"
  ];
  boot.initrd.kernelModules = [
    # DRM NVIDIA carregado cedo para display no TTY
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [];

  # ─────────────────────────────────────────────────────────────────
  # TODO: após `nixos-generate-config --show-hardware-config`, cole
  # as entradas fileSystems abaixo com os UUIDs reais.
  #
  # Exemplo:
  #
  # fileSystems."/" = lib.mkForce {
  #   device = "/dev/disk/by-uuid/REAL-UUID-HERE";
  #   fsType = "btrfs";
  #   options = [ "subvol=@" "compress=zstd" "noatime" ];
  # };
  # ─────────────────────────────────────────────────────────────────

  # CPU microcode AMD
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Firmware redistribuível (inclui firmware WiFi/BT/etc.)
  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

# =============================================================================
# Host: Glacier
#
# O que é:
# - Composição declarativa do host Glacier.
# - Toda lógica está nos perfis glacier-base/ai/gamer + rve-compat.nix.
# - Este arquivo contém apenas: imports, enables, kernel, boot e stateVersion.
#
# Perfis ativos:
# - glacier-base: NVIDIA, SSH, Tailscale, firewall, branding
# - glacier-ai:   Ollama + Brain + LightRAG (sem autostart, keep_alive=0)
# - glacier-gamer: Steam, Lutris, Wine, Heroic, OpenRGB, desktop
# - dev:          git, gh, lazygit, tmux, podman, neovim
# - ti:           nmap, tcpdump, wireshark, virt-manager, qemu
# =============================================================================
{
  inputs,
  hostname,
  lib,
  config,
  ...
}:
{
  imports = [
    # Hardware AMD + NVIDIA (nixos-hardware)
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-cpu-amd-pstate
    inputs.hardware.nixosModules.common-gpu-nvidia

    ./hardware-configuration.nix
    ./rve-compat.nix

    # Kernel e rede
    ../../modules/kernel/zen.nix
    ../../modules/virtualization/net-ragthink.nix
  ];

  # =========================
  # PROFILES — toda a lógica vive aqui
  # =========================
  kryonix.profiles.glacier-base.enable = true;
  kryonix.profiles.glacier-ai.enable = true;
  kryonix.profiles.glacier-gamer.enable = true;

  # Perfis funcionais
  kryonix.profiles.dev.enable = true;
  kryonix.profiles.ti.enable = true;

  # =========================
  # TAILSCALE (RVE-specific, não genérico)
  # =========================
  # authKeyFile e extraUpFlags são identidade deste host — ficam aqui.
  services.kryonix.tailscale = {
    advertiseExitNode = true;
    authKeyFile = /root/tailscale-authkey.secret;
    extraUpFlags = [ "--hostname=RVE-GLACIER" ];
  };

  # KERNEL ZEN (hardware-specific)
  # =========================
  kernelZen = {
    enable = true;
    kernel = "zen";
    forceLocalBuild = true;
    useLLVMStdenv = true;
    extraMakeFlags = [ ];
    disableMitigations = lib.mkDefault false;
    extraKernelParams = [ ];
  };

  # =========================
  # NETWORK — hostname apenas (IP, bridge, firewall em rve-compat e glacier-base)
  # =========================
  networking.hostName = hostname;

  # =========================
  # BOOT (hardware-specific)
  # =========================
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = lib.mkForce true;
        efiSupport = true;
        device = "nodev";
        useOSProber = false;
        # Instala também no local removível/fallback (/EFI/BOOT/BOOTX64.EFI)
        # Útil para firmwares UEFI que perdem entradas ou priorizam o fallback.
        efiInstallAsRemovable = true;
      };
      efi = {
        canTouchEfiVariables = lib.mkForce false;
        efiSysMountPoint = "/boot";
      };
    };

    initrd.kernelModules = lib.mkForce [ ];
    initrd.systemd.enable = true;
  };

  # =========================
  # SYSTEM
  # =========================
  system.stateVersion = "26.05";
}

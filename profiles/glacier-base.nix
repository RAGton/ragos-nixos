# =============================================================================
# Profile: glacier-base
#
# O que é:
# - Perfil base do Glacier: NVIDIA driver, graphics, SSH, Tailscale, firewall,
#   sudo, branding e pacotes de diagnóstico.
# - Networking de identidade (IP fixo, bridge, WoL) fica em rve-compat.nix.
#
# Por quê:
# - Separação limpa: base ≠ IA ≠ gamer.
# - Um único lugar para tudo que é "servidor NixOS com GPU NVIDIA".
# =============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kryonix.profiles.glacier-base;
in
{
  options.kryonix.profiles.glacier-base = {
    enable = lib.mkEnableOption "Perfil base do Glacier (NVIDIA, SSH, Tailscale, firewall, branding)";
  };

  config = lib.mkIf cfg.enable {
    # Performance de servidor
    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

    # NVIDIA RTX 4060 — driver proprietário, sem PRIME (desktop fixo)
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        sync.enable = lib.mkForce false;
        offload.enable = lib.mkForce false;
      };
    };

    # 32-bit graphics (necessário para Steam/Wine e apps legacy)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # SSH habilitado (portas e settings ficam em rve-compat.nix)
    services.openssh.enable = true;

    # Tailscale
    services.tailscale.enable = true;

    # Firewall base: confia no túnel Tailscale
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    # Sudo sem senha para wheel (host single-user)
    security.sudo.wheelNeedsPassword = false;

    # Branding
    kryonix.branding = {
      enable = true;
      prettyName = "Kryonix Glacier";
      edition = "Server/Workstation";
    };

    # Pacotes base de diagnóstico e operação
    # (git, curl, wget, vim, htop já estão em rve-compat.nix — não duplicar)
    environment.systemPackages = with pkgs; [
      efibootmgr
    ];
  };
}

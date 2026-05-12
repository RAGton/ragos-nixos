# Módulo NixOS: MikroTik Winbox (nível do sistema)
# Autor: rag
#
# O que é
# - Instala o Winbox (cliente GUI oficial da MikroTik, via Nixpkgs).
# - Opcionalmente abre as portas UDP usadas pela descoberta de vizinhos (MNDP).
#
# Por quê
# - Deixa o Winbox disponível de forma declarativa, sem downloads manuais.
# - Centraliza (e documenta) o ajuste de firewall quando a descoberta por vizinhos é necessária.
#
# Como
# - `programs.winbox.enable = true` adiciona o pacote ao `environment.systemPackages`.
# - `programs.winbox.openFirewall = true` abre:
#   - UDP 5678 (MNDP)
#   - UDP 40000-50000 (portas efêmeras usadas pelo processo de descoberta)
#
# Riscos
# - Abrir portas no firewall aumenta a superfície de rede; prefira usar em redes confiáveis
#   e considere restringir por interface quando necessário.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.winbox;
in
{
  options.programs.winbox = {
    enable = lib.mkEnableOption "MikroTik Winbox";

    package = lib.mkPackageOption pkgs "winbox" { };

    openFirewall = lib.mkOption {
      description = ''
        Se verdadeiro, abre portas para o protocolo MikroTik Neighbor Discovery (MNDP).

        Necessário para o Winbox enxergar vizinhos via descoberta automática na rede local.
      '';
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [ 5678 ];
      allowedUDPPortRanges = [
        {
          from = 40000;
          to = 50000;
        }
      ];
    };
  };
}

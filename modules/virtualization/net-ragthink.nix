/*
 Autor: rag
 Descrição: Declara a rede libvirt "net-ragthink" (NAT + bridge virbr-ragthink)
            de forma totalmente declarativa via systemd.
*/

{ pkgs, lib, ... }:

let
  netXml = pkgs.writeText "net-ragthink.xml" (builtins.readFile ../../net-ragthink.xml);
  virsh = "${pkgs.libvirt}/bin/virsh";
  diff = "${pkgs.diffutils}/bin/diff";
in
{
  # Evita o firewall bloquear tráfego entre VMs e o host.
  networking.firewall.trustedInterfaces = [ "virbr-ragthink" ];

  systemd.services.libvirt-net-ragthink = {
    description = "Libvirt network: net-ragthink";
    wantedBy = [ "multi-user.target" ];
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail

      # Garante que a rede exista no libvirt do sistema (qemu:///system).
      if ${virsh} -c qemu:///system net-info net-ragthink >/dev/null 2>&1; then
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

        ${virsh} -c qemu:///system net-dumpxml net-ragthink >"$tmp"

        # Se o XML mudou, redefine (para manter estado declarativo).
        if ! ${diff} -q "$tmp" ${netXml} >/dev/null; then
          ${virsh} -c qemu:///system net-destroy net-ragthink >/dev/null 2>&1 || true
          ${virsh} -c qemu:///system net-undefine net-ragthink >/dev/null 2>&1 || true
          ${virsh} -c qemu:///system net-define ${netXml} >/dev/null
        fi
      else
        ${virsh} -c qemu:///system net-define ${netXml} >/dev/null
      fi

      ${virsh} -c qemu:///system net-autostart net-ragthink >/dev/null
      ${virsh} -c qemu:///system net-start net-ragthink >/dev/null 2>&1 || true
    '';
  };
}

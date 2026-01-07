{ config, lib, pkgs, userConfig, ... }:
{
  # Habilita Snapper automaticamente em sistemas com root Btrfs
  # usando subvolumes existentes para / e /home.
  
  # Só aplica se o root for Btrfs
  config = lib.mkIf ((config.fileSystems."/".fsType or "") == "btrfs") {
    # Snapper usa `/.snapshots` por padrão; garanta que o diretório exista
    # mesmo quando não há subvolume/mount dedicado para snapshots.
    systemd.tmpfiles.rules = [
      "d /.snapshots 0755 root root -"
    ];

    # O snapper exige que `/.snapshots` seja um *subvolume* Btrfs.
    # Se ele existir apenas como diretório (como o tmpfiles cria), o
    # `snapper-boot.service` falha durante o `nixos-rebuild switch`.
    #
    # Aqui garantimos de forma declarativa (na ativação) que `/.snapshots`
    # seja um subvolume. Por segurança, só substituímos se for um diretório
    # vazio; caso contrário, abortamos para não perder dados.
    system.activationScripts.snapperEnsureSnapshotsSubvolume = {
      deps = [ "users" ];
      text = ''
        if [ "${config.fileSystems."/".fsType or ""}" = "btrfs" ]; then
          if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume show /.snapshots >/dev/null 2>&1; then
            if [ -e /.snapshots ] && [ ! -d /.snapshots ]; then
              echo "snapper: /.snapshots existe mas não é diretório; não é possível criar subvolume." >&2
              exit 1
            fi

            if [ -d /.snapshots ] && [ -n "$(ls -A /.snapshots 2>/dev/null)" ]; then
              echo "snapper: /.snapshots é um diretório não-vazio e não é subvolume; recuso substituir automaticamente." >&2
              echo "snapper: mova/remova o conteúdo de /.snapshots e rode nixos-rebuild novamente." >&2
              exit 1
            fi

            rm -rf /.snapshots
            ${pkgs.btrfs-progs}/bin/btrfs subvolume create /.snapshots >/dev/null
          fi
        fi
      '';
    };

    services.snapper = {
      snapshotRootOnBoot = true;

      configs = {
        root = {
          SUBVOLUME = "/";
          ALLOW_USERS = [ userConfig.name ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "6";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "3";
          TIMELINE_LIMIT_YEARLY = "1";
        };

        home = {
          SUBVOLUME = "/home";
          ALLOW_USERS = [ userConfig.name ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "3";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "3";
          TIMELINE_LIMIT_YEARLY = "1";
        };
      };
    };
  };
}

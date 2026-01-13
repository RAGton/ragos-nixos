{ config, lib, pkgs, userConfig, ... }:
{
  # Habilita Snapper automaticamente em sistemas com root Btrfs
  # usando subvolumes existentes para / e /home.
  
  # Só aplica se o root for Btrfs
  config = lib.mkIf ((config.fileSystems."/".fsType or "") == "btrfs") {
    # App(s) para gerenciar snapshots no KDE.
    # - btrfs-assistant: interface moderna e prática (funciona muito bem com snapper)
    # - snapper-gui: GUI clássica do snapper
    environment.systemPackages = with pkgs; [
      btrfs-assistant
      snapper
      snapper-gui
    ];

    # Snapper usa `/.snapshots` por padrão; garanta que o diretório exista
    # mesmo quando não há subvolume/mount dedicado para snapshots.
    systemd.tmpfiles.rules = [
      "d /.snapshots 0755 root root -"
      "d /home/.snapshots 0755 root root -"
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

          # Para o config "home" (SUBVOLUME=/home), o snapper usa /home/.snapshots por padrão.
          if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume show /home/.snapshots >/dev/null 2>&1; then
            if [ -e /home/.snapshots ] && [ ! -d /home/.snapshots ]; then
              echo "snapper: /home/.snapshots existe mas não é diretório; não é possível criar subvolume." >&2
              exit 1
            fi

            if [ -d /home/.snapshots ] && [ -n "$(ls -A /home/.snapshots 2>/dev/null)" ]; then
              echo "snapper: /home/.snapshots é um diretório não-vazio e não é subvolume; recuso substituir automaticamente." >&2
              echo "snapper: mova/remova o conteúdo de /home/.snapshots e rode nixos-rebuild novamente." >&2
              exit 1
            fi

            rm -rf /home/.snapshots
            ${pkgs.btrfs-progs}/bin/btrfs subvolume create /home/.snapshots >/dev/null
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

    # Snapshot no boot também para /home (o snapper do NixOS cobre apenas root).
    systemd.services.snapper-home-boot = {
      description = "Snapper snapshot for /home on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" "snapperd.service" ];
      wants = [ "snapperd.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.snapper}/bin/snapper -c home create -d 'boot' -c timeline";
      };
    };

    # Limpeza semanal (fim de semana) em vez de diária.
    # Ajuste o horário se quiser; usamos domingo à noite por padrão.
    systemd.timers.snapper-cleanup.timerConfig.OnCalendar = lib.mkForce "Sun *-*-* 23:30:00";
    systemd.timers.snapper-cleanup.timerConfig.Persistent = lib.mkForce true;
  };
}

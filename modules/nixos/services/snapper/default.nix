# Módulo NixOS: Snapper (Btrfs)
# Autor: rag
#
# O que é
# - Habilita e configura Snapper automaticamente quando `/` é Btrfs.
# - Garante subvolumes de snapshots esperados pelo Snapper (`/.snapshots` e `/home/.snapshots`).
# - Instala GUI(s) para gerenciamento de snapshots.
#
# Por quê
# - Snapshots reduzem risco operacional (rollback/recuperação).
# - Evita falhas comuns no boot/rebuild quando `.snapshots` existe só como diretório.
# - Padroniza retenção (timeline + cleanup) de forma declarativa.
#
# Como
# - Condicionado a `config.fileSystems."/".fsType == "btrfs"`.
# - Usa activation script para garantir *subvolume* (não apenas diretório).
# - Cria snapshot no boot para `/` e também para `/home` via unit dedicada.
#
# Riscos
# - Se `/.snapshots` (ou `/home/.snapshots`) existir como diretório não-vazio, a ativação aborta
#   por segurança (para não destruir dados). Nesse caso, mover/limpar manualmente antes do rebuild.
{ config, lib, pkgs, userConfig, ... }:
{
  # Condição de ativação: só aplica quando o root filesystem é Btrfs.
  config = lib.mkIf ((config.fileSystems."/".fsType or "") == "btrfs") {
    # App(s) para gerenciar snapshots no KDE.
    # - btrfs-assistant: interface moderna e prática (funciona muito bem com snapper)
    # - snapper-gui: GUI clássica do snapper
    environment.systemPackages = with pkgs; [
      btrfs-assistant
      snapper
      snapper-gui
    ];

    # Garante os diretórios de mountpoints.
    # Importante: Snapper precisa que esses paths sejam *subvolumes* Btrfs.
    # O tmpfiles ajuda a garantir o path, mas o activation script abaixo garante o subvolume.
    systemd.tmpfiles.rules = [
      "d /.snapshots 0755 root root -"
      "d /home/.snapshots 0755 root root -"
    ];

    # Garantia de subvolume (não apenas diretório).
    #
    # Por quê
    # - `snapper-boot.service` e o funcionamento normal do Snapper assumem subvolume.
    # - Se existir apenas diretório, o serviço pode falhar em rebuild/boot.
    #
    # Como
    # - Se não for subvolume, substitui apenas quando for diretório vazio.
    # - Se houver conteúdo, aborta com instruções para evitar perda de dados.
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

          # Config "home" (SUBVOLUME=/home): por padrão o snapper usa /home/.snapshots.
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

    # Snapshot no boot também para /home.
    # Motivo: o `snapshotRootOnBoot` cobre apenas `/` por padrão.
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

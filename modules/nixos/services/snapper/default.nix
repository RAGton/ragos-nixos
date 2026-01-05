{ config, lib, userConfig, ... }:
{
  # Habilita Snapper automaticamente em sistemas com root Btrfs
  # usando subvolumes existentes para / e /home.
  
  # Só aplica se o root for Btrfs
  config = lib.mkIf ((config.fileSystems."/".fsType or "") == "btrfs") {
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

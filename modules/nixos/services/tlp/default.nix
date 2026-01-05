{ ... }:
{
  # Set TLP power profile
  services = {
    tlp = {
      enable = true;
      settings = {
        # Mais performance em tomada para games
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "performance";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 1;
  CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "performance";
  PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "performance";

        USB_EXCLUDE_BTUSB = 1;
        # USB autosuspend costuma causar "travadas" (mouse/teclado/áudio).
        # Preferir estabilidade no desktop.
        USB_AUTOSUSPEND = 0;
        USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 1;

        AMDGPU_ABM_LEVEL_ON_AC = 0;
        AMDGPU_ABM_LEVEL_ON_BAT = 0;

        DISK_IOSCHED = [ "none" ];
        DISK_APM_LEVEL_ON_BAT = "1 1";

        SATA_LINKPWR_ON_BAT = "max_performance";
        PCIE_ASPM_ON_AC = "performance";
        PCIE_ASPM_ON_BAT = "performance";

        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "on";

        # Wi‑Fi power saving agressivo pode causar quedas e stutter.
        WIFI_PWR_ON_BAT = "off";

        SOUND_POWER_SAVE_ON_BAT = 0;
        SOUND_POWER_SAVE_CONTROLLER = "Y";

        # Battery charge thresholds for on-road usage
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;
      };
    };

    power-profiles-daemon.enable = false;
  };

  # Disable fingerprint reader
  services.fprintd.enable = false;
}

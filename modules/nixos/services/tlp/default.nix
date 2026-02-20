# Módulo NixOS: TLP (perfil de energia)
# Autor: rag
#
# O que é
# - Configura TLP para controle fino de energia/performance.
# - Desabilita `power-profiles-daemon` para evitar conflito.
#
# Por quê
# - TLP dá previsibilidade de performance (AC/BAT) e estabilidade de periféricos.
# - Evita stutter/queda por autosuspend agressivo.
#
# Como
# - Define `services.tlp.settings` (CPU, USB, Wi‑Fi, power management).
# - Desliga serviços redundantes (`power-profiles-daemon`, `fprintd`).
#
# Riscos
# - Configs agressivas podem aumentar consumo/temperatura e reduzir bateria.
# - Valores de limite de carga (BAT0) precisam fazer sentido para o hardware.
{ ... }:
{
  # Ajusta o perfil de energia via TLP.
  services = {
    tlp = {
      enable = true;
      settings = {
        # Mais performance em tomada para games.
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

        # Limites de carga da bateria (uso no dia a dia).
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;
      };
    };

    power-profiles-daemon.enable = false;
  };

  # Desabilita leitor de digital.
  services.fprintd.enable = false;
}

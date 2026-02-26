# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para instalar e configurar o `albert` (launcher) no Linux.
# - Define config via XDG e serviço systemd user para iniciar junto da sessão gráfica.
#
# Por quê:
# - Padroniza o launcher e comandos de sistema sem depender de configuração manual.
# - Mantém autostart declarativo e reproduzível.
#
# Como:
# - Ativa somente fora do Darwin via `lib.mkIf (!pkgs.stdenv.isDarwin)`.
# - Instala `pkgs.albert`, escreve `~/.config/albert/config` e cria `systemd.user.services.albert`.
#
# Riscos:
# - A string `command_logout` depende de ferramentas do ambiente (hyprctl/jq/kdotool).
# - Mudanças no desktop session podem exigir ajuste nos comandos.
# =============================================================================
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # DMS já fornece launcher nativo; Albert ficaria duplicado.
  dmsEnabled =
    (config.rag.rice.dmsUpstream.enable or false)
    || (config.rag.rice.dms.enable or false)
    || (config.programs.dank-material-shell.enable or false);
in
{
  config = lib.mkIf (!pkgs.stdenv.isDarwin && !dmsEnabled) {
    # Pacote do Albert.
    home.packages = [ pkgs.albert ];

    # Importa a configuração do Albert a partir do store do Home Manager.
    xdg.configFile."albert/config".text = ''
      [General]
      frontend=widgetsboxmodel-ng
      showTray=false
      telemetry=false

      [applications]
      enabled=true
      global_handler_enabled=true

      [chromium]
      enabled=true
      fuzzy=false
      global_handler_enabled=false
      trigger=bm

      [debug]
      enabled=false

      [path]
      enabled=false

      [system]
      command_lock=loginctl lock-session
      command_logout="[[ \"$DESKTOP_SESSION\" == hyprland* ]] && { hyprctl -j clients 2>/dev/null | jq -j '.[] | \"dispatch closewindow address:\\(.address); \"' | xargs -r hyprctl --batch 2>/dev/null; } || [ \"$DESKTOP_SESSION\" = \"plasma\" ] && kdotool search '.*' windowclose %@ || true"
      command_poweroff=systemctl poweroff -i
      command_reboot=systemctl reboot -i
      enabled=true
      logout_enabled=true
      title_logout=Quit All Applications
      title_poweroff=Shutdown
      trigger=sys

      [widgetsboxmodel-ng]
      alwaysOnTop=true
      clearOnHide=true
      debug=false
      displayScrollbar=false
      followCursor=true
      hideOnFocusLoss=true
      historySearch=true
      itemCount=10
      quitOnClose=false
      showCentered=true
    '';

    # Serviço systemd user para iniciar o Albert na sessão gráfica.
    systemd.user.services.albert = {
      Unit = {
        Description = "Albert Launcher";
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.albert}/bin/albert";
        Nice = 10;
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
        Restart = "always";
        RestartSec = "0s";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../../modules/home-manager/common
    ../../../desktop/hyprland/user.nix
    ../../../desktop/hyprland/rice/dms-upstream.nix
    ../../shared/dev-workstation.nix
  ];

  rag.rice.dmsUpstream.enable = true;

  rag.vscode.extraExtensions = [
    "vsciot-vscode.vscode-arduino"
    "platformio.platformio-ide"
  ];

  rag.vscode.extraSettings = {
    "arduino.useArduinoCli" = true;
  };

  home.packages = with pkgs; [
    google-chrome
  ];

  home.sessionVariables = {
    ARDUINO_SKETCHBOOK_DIR = "${config.home.homeDirectory}/Arduino";
    PSIM_WINEPREFIX = "${config.home.homeDirectory}/.local/share/wineprefixes/psim";
  };

  xdg.desktopEntries.psim = {
    name = "PSIM";
    genericName = "Circuit Simulator";
    comment = "PSIM executado via Wine";
    exec = "psim";
    terminal = false;
    categories = [
      "Development"
      "Education"
      "Engineering"
    ];
    icon = "wine";
    startupNotify = true;
  };

  home.activation.ensureElectronicsWorkspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
      "$HOME/Arduino" \
      "$HOME/.local/share/wineprefixes" \
      "$HOME/.local/share/psim-installers"
  '';
}

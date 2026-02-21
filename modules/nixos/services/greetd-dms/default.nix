# =============================================================================
# NixOS: greetd + tuigreet (Wayland-friendly login manager)
#
# O que é:
# - Habilita greetd e configura sessão Wayland funcional com tuigreet.
#
# Por quê:
# - Substitui SDDM/GDM por um login manager leve e Wayland-friendly.
# - tuigreet é o greeter padrão, estável e bem integrado com greetd.
# - Corrige problema de login loop causado por sessão logind inválida.
#
# Como usar:
# - No host (ex.: hosts/inspiron/default.nix):
#     rag.services.greetdDms.enable = true;
#
# Por que funciona:
# - A sessão deve ter class=user e type=wayland para que logind crie
#   uma sessão válida com seat0 anexado.
# - Sem isso, UWSM herda uma sessão "manager" sem seat e Hyprland falha.
# - O PAM é configurado com os parâmetros corretos para pam_systemd.so.
#
# Notas:
# - O rice DMS (DankMaterialShell) é carregado pelo usuário via Home Manager.
# - O usuário "greeter" é criado automaticamente pelo módulo greetd do NixOS.
# - UWSM é usado para iniciar Hyprland quando programs.hyprland.withUWSM = true.
# =============================================================================
{ config, lib, pkgs, ... }:

let
  cfg = config.rag.services.greetdDms;
  greeterUser = cfg.user;

  # Comando tuigreet com configuração otimizada para sessões Wayland
  tuigreetCmd = lib.concatStringsSep " " [
    "${pkgs.tuigreet}/bin/tuigreet"
    "--time"
    "--remember"
    "--remember-user-session"
    "--asterisks"
    "--cmd ${lib.escapeShellArg cfg.command}"
  ];
in
{
  options.rag.services.greetdDms = {
    enable = lib.mkEnableOption "greetd com tuigreet (gerenciador de login Wayland-friendly)";

    user = lib.mkOption {
      type = lib.types.str;
      default = "greeter";
      description = ''
        Usuário que executa o processo greeter do greetd.
        Por padrão usa "greeter", o usuário de sistema criado automaticamente
        pelo módulo services.greetd do NixOS. Altere apenas se souber o que está fazendo.
      '';
    };

    command = lib.mkOption {
      type = lib.types.str;
      default = "uwsm start hyprland-uwsm.desktop";
      description = ''
        Comando da sessão lançado após o login.
        Padrão: "uwsm start hyprland-uwsm.desktop" (requerido quando programs.hyprland.withUWSM = true).
        Use "Hyprland" apenas se withUWSM = false.
      '';
    };

    vt = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = ''
        Virtual terminal (VT) onde o greetd será executado.
        Padrão: 1 (primeiro terminal virtual).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ==========================================================================
    # Configuração do greetd
    # ==========================================================================
    services.greetd = {
      enable = true;
      vt = cfg.vt;
      settings = {
        default_session = {
          user = greeterUser;
          command = tuigreetCmd;
        };
      };
    };

    # ==========================================================================
    # PAM para greetd: Sessão Wayland com seat
    #
    # CRÍTICO: Configura pam_systemd.so com class=user type=wayland para que
    # logind crie uma sessão válida com:
    # - Class: user (não "manager")
    # - Type: wayland
    # - Seat: seat0
    #
    # Isso é necessário porque as opções estruturadas do NixOS (startSession = true)
    # não permitem especificar esses parâmetros. Sem eles, a sessão não funciona
    # com UWSM e Hyprland.
    #
    # Referência: docs/GREETD_FINAL_SOLUTION.md
    # ==========================================================================
    security.pam.services.greetd = {
      allowNullPassword = lib.mkForce false;
      unixAuth = true;
      text = lib.mkForce ''
        # PAM para greetd - Sessão Wayland funcional
        # NÃO MODIFICAR sem entender docs/GREETD_FINAL_SOLUTION.md

        # Autenticação
        auth     required pam_unix.so nullok try_first_pass
        auth     optional pam_gnome_keyring.so

        # Verificação de conta
        account  required pam_unix.so

        # Senha (para troca de senha)
        password required pam_unix.so nullok yescrypt
        password optional pam_gnome_keyring.so use_authtok

        # Sessão - ORDEM IMPORTA
        session  required pam_unix.so
        session  required pam_env.so conffile=/etc/pam/environment readenv=0
        session  optional pam_keyinit.so force revoke
        session  required pam_limits.so

        # CRÍTICO: class=user type=wayland para sessão Wayland válida
        # - class=user: logind cria sessão com seat (não "manager")
        # - type=wayland: define XDG_SESSION_TYPE=wayland e aloca VT
        session  required pam_systemd.so class=user type=wayland

        # Gnome Keyring (desbloqueio automático)
        session  optional pam_gnome_keyring.so auto_start

        # Fallback para módulos opcionais
        session  optional pam_permit.so
      '';
    };

    # ==========================================================================
    # Variáveis de ambiente para sessão Wayland
    # ==========================================================================
    environment.sessionVariables = {
      # Garante que apps Electron/Chromium usem Wayland
      NIXOS_OZONE_WL = "1";
      # XDG runtime dir (normalmente já definido, mas garantimos)
      XDG_RUNTIME_DIR = "/run/user/$UID";
    };

    # ==========================================================================
    # Pacotes necessários
    # ==========================================================================
    environment.systemPackages = with pkgs; [
      tuigreet
      # greetd já é instalado pelo módulo services.greetd
    ];

    # ==========================================================================
    # Garantir que logind está configurado corretamente
    # ==========================================================================
    services.logind = {
      # Não mata sessões de usuário no logout (permite processos em background)
      killUserProcesses = false;
      # Extrai session slice para isolamento
      extraConfig = ''
        HandlePowerKey=suspend
        HandleLidSwitch=suspend
        HandleLidSwitchExternalPower=ignore
      '';
    };
  };
}


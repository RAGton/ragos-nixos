# =============================================================================
# NixOS: greetd + tuigreet (Wayland-friendly login manager)
#
# O que é:
# - Habilita greetd e configura a sessão padrão com tuigreet.
#
# Por quê:
# - Substitui SDDM/GDM por um login manager leve e Wayland-friendly.
# - tuigreet é o greeter padrão, estável e bem integrado com greetd.
#
# Como usar:
# - No host (ex.: hosts/inspiron/default.nix):
#     rag.services.greetdDms.enable = true;
#
# Notas:
# - O rice DMS (DankMaterialShell) é carregado pelo usuário via Home Manager.
#   Aqui só configuramos o display manager (greetd + tuigreet).
# - O usuário padrão "greeter" é criado automaticamente pelo módulo greetd do NixOS.
# - Quando programs.hyprland.withUWSM = true, a sessão deve ser iniciada via UWSM.
# =============================================================================
{ config, lib, pkgs, ... }:

let
  cfg = config.rag.services.greetdDms;
  greeterUser = cfg.user;
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
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session = {
        user = greeterUser;
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${lib.escapeShellArg cfg.command}";
      };
    };

    # ✅ PAM para greetd: configuração explícita para criar sessão Wayland com seat.
    # 
    # CRÍTICO: Usa text = lib.mkForce para especificar class=user type=wayland no pam_systemd.so.
    # Isto é necessário porque:
    # 
    # 1. startSession = true (opção estruturada) adiciona pam_systemd.so MAS sem os parâmetros
    #    class=user e type=wayland, resultando em sessão "manager" sem seat.
    # 
    # 2. class=user → logind cria sessão com seat (não "manager")
    #    type=wayland → logind aloca VT e define XDG_SESSION_TYPE=wayland
    # 
    # 3. Sem isso, UWSM herda sessão inválida e Hyprland/DMS não iniciam.
    # 
    # Referência: docs/SOLUTION_LOGIND_WAYLAND.md
    security.pam.services.greetd = {
      allowNullPassword = lib.mkForce false;
      unixAuth = true;
      text = lib.mkForce ''
        # Autenticação
        auth     required pam_unix.so nullok try_first_pass
        auth     optional pam_gnome_keyring.so
        
        # Verificação de conta
        account  required pam_unix.so
        
        # Senha
        password required pam_unix.so nullok yescrypt
        password optional pam_gnome_keyring.so use_authtok
        
        # Sessão
        session  required pam_unix.so
        session  required pam_env.so conffile=/etc/pam/environment readenv=0
        session  optional pam_keyinit.so revoke
        session  required pam_limits.so
        session  required pam_systemd.so class=user type=wayland
        session  optional pam_gnome_keyring.so auto_start
        session  optional pam_permit.so
      '';
    };

    environment.systemPackages = [ pkgs.tuigreet ];

    assertions = [
      {
        assertion = lib.hasAttr greeterUser config.users.users;
        message = "greetdDms: users.users.${greeterUser} não existe. Crie o usuário antes ou ajuste rag.services.greetdDms.user.";
      }
    ];
  };
}


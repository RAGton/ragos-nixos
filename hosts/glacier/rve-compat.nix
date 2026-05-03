{
  config,
  lib,
  pkgs,
  ...
}:
let
  enablePublicHttps = false;
in
{
  # Preserva a identidade e o acesso remoto do host atual,
  # mesmo que o output da flake continue se chamando `glacier`.
  networking.hostName = lib.mkForce "RVE-GLACIER";
  networking.useDHCP = lib.mkForce false;
  networking.networkmanager.enable = lib.mkForce false;
  programs.nm-applet.enable = lib.mkForce false;

  networking.interfaces.enp6s0 = {
    useDHCP = false;
    ipv4.addresses = [ ];
    wakeOnLan = {
      enable = true;
      policy = [ "magic" ];
    };
  };

  networking.bridges.br0.interfaces = [ "enp6s0" ];
  networking.interfaces.br0.ipv4.addresses = [
    {
      address = "10.0.0.2";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  networking.enableIPv6 = true;

  services.openssh = {
    ports = [ 2224 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  programs.ssh.extraConfig = ''
    Host github.com
      HostName github.com
      User git
      IdentityFile /home/rocha/.ssh/id_ed25519_git_signing
      IdentitiesOnly yes
      AddKeysToAgent yes
      PreferredAuthentications publickey
  '';

  networking.firewall.allowedTCPPorts = lib.mkAfter (
    [
      2224
    ]
    ++ lib.optionals enablePublicHttps [ 443 ]
  );

  # Enable after Cloudflare credential files exist on the host.
  security.acme = lib.mkIf enablePublicHttps {
    acceptTerms = true;
    defaults = {
      email = "aguiarrocha36@gmail.com";
      dnsProvider = "cloudflare";
    };

    certs."rve.ragenterprise.com.br" = {
      group = config.services.nginx.group;
      dnsProvider = "cloudflare";
      credentialFiles = {
        CLOUDFLARE_DNS_API_TOKEN_FILE = "/var/lib/secrets/cloudflare-dns-token";
        CLOUDFLARE_ZONE_API_TOKEN_FILE = "/var/lib/secrets/cloudflare-zone-token";
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;

    virtualHosts."rve.ragenterprise.com.br" = {
      useACMEHost = lib.mkIf enablePublicHttps "rve.ragenterprise.com.br";
      forceSSL = enablePublicHttps;
      locations."/" = {
        return = "200 'RVE online\\n'";
        extraConfig = ''
          default_type text/plain;
        '';
      };
    };
  };

  # Storage adicional para fluxo de hypervisor/workstation.
  users.groups.kryonix = { };
  users.users.rocha.extraGroups = lib.mkAfter [ "kryonix" ];

  # SSH key-based authentication only (no password)
  users.users.rocha.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMI1uwVA1Y03EBvdy34fw1LRPk3TgYcVmeUOPWrEmjYn rocha@inspiron"
  ];

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    htop
    pciutils
    usbutils
    ethtool
    tailscale
    iproute2
  ];

  systemd.services.wol = {
    description = "Enable Wake-on-LAN";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp6s0 wol g";
      RemainAfterExit = true;
    };

    wantedBy = [ "multi-user.target" ];
  };

  # Host fixo/desktop não deve suspender por eventos de energia/logind.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };
}

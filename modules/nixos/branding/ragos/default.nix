# =============================================================================
# Módulo NixOS: Branding do sistema (RagOS)
# Autor: rag
#
# O que é
# - Um módulo *reutilizável* para “caracterizar” o NixOS como RagOS.
# - Ajusta identidade do sistema em lugares padrão do Linux desktop:
#   - /etc/os-release (PRETTY_NAME, NAME, ID, VERSION_ID)
#   - /etc/issue (texto do console/login)
#
# Por quê
# - Mantém o rebranding *declarativo* e centralizado, sem “gambiarras” por host.
# - Evita espalhar strings (nome/versão) em vários arquivos.
#
# Como usar
# - Importe este módulo em um host (ex.: `hosts/inspiron/default.nix`) ou em um módulo comum.
# - Depois habilite:
#     ragos.enable = true;
#     ragos.versionId = "25.11"; # (se quiser espelhar o stateVersion)
#
# Nota importante sobre versões
# - `system.stateVersion` NÃO deve ser mudado só por branding.
# - `ragos.versionId` é apenas o que aparece em /etc/os-release.
# =============================================================================
{ lib, config, ... }:
let
  cfg = config.ragos;
  # Conteúdo do /etc/os-release.
  # Usamos um conjunto pequeno e compatível (muitas ferramentas só precisam disso).
  osReleaseText = ''
    NAME="NixOS (RagOS)"
    PRETTY_NAME=${lib.escapeShellArg cfg.prettyName}
    ID=nixos
    ID_LIKE=nixos
    VERSION_ID=${lib.escapeShellArg cfg.versionId}
    LOGO=nix-snowflake
    HOME_URL="https://nixos.org/"
  '';
in
{
  options.ragos = {
    enable = lib.mkEnableOption "Ativa branding do sistema como RagOS";

    prettyName = lib.mkOption {
      type = lib.types.str;
      default = "RagOS";
      description = "Nome amigável (PRETTY_NAME) exibido por ferramentas/GUI.";
    };

    versionId = lib.mkOption {
      type = lib.types.str;
      default = "25.11";
      description = "Versão exibida (VERSION_ID) em /etc/os-release.";
    };

    issueText = lib.mkOption {
      type = lib.types.lines;
      default = ''
        RagOS (base NixOS)
        Kernel: \r \m
      '';
      description = ''
        Texto para /etc/issue (login/TTY).

        Dica: suporta escapes do getty, como:
        - \r: release do kernel
        - \m: arquitetura
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Substitui o /etc/os-release padrão do NixOS.
    # Se não for mkForce, pode acontecer de ficar duplicado/mesclado.
    environment.etc."os-release".text = lib.mkForce osReleaseText;

    # Texto exibido em TTY/getty.
    environment.etc."issue".text = cfg.issueText;
  };
}

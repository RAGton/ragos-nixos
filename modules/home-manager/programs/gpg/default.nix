# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar o `gpg` e (no Linux) o `gpg-agent`.
#
# Por quê:
# - Define um baseline de segurança/compatibilidade para operações com GPG.
# - No Linux, habilita agent com suporte a SSH para integrar fluxos que dependem dele.
#
# Como:
# - Configura `programs.gpg.settings` (preferências de cifra/hash e hardening).
# - Habilita `services.gpg-agent` somente quando não for Darwin.
#
# Riscos:
# - Preferências mais estritas podem quebrar interoperabilidade com chaves antigas.
# - Pinentry escolhido (gnome3) pode não combinar com todos os ambientes; ajuste se necessário.
# =============================================================================
{
  pkgs,
  lib,
  ...
}:
{
  # Instala e configura o gpg via Home Manager.
  programs.gpg = {
    enable = true;
    settings = {
      personal-cipher-preferences = "AES256";
      personal-digest-preferences = "SHA512";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 AES256 ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      charset = "utf-8";
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-key-origin = true;
      require-cross-certification = true;
      no-symkey-cache = true;
      use-agent = true;
      throw-keyids = true;
    };
  };

  services.gpg-agent = lib.mkIf (!pkgs.stdenv.isDarwin) {
    enable = true;
    defaultCacheTtl = 86400;
    enableSshSupport = true;
    pinentry.package = lib.mkDefault pkgs.pinentry-gnome3;
  };
}

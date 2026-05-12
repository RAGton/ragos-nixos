{
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (!pkgs.stdenv.isDarwin) {
    # =============================================================================
    # Autor: rag
    #
    # O que é:
    # - Módulo Home Manager para habilitar o `obs-studio` no Linux.
    #
    # Por quê:
    # - Garante que o OBS esteja disponível no perfil do usuário sem setup manual.
    #
    # Como:
    # - Ativa somente fora do Darwin via `lib.mkIf (!pkgs.stdenv.isDarwin)`.
    # - Habilita `programs.obs-studio.enable = true`.
    #
    # Riscos:
    # - OBS depende de codecs/backends; problemas costumam ser do ambiente/driver.
    # =============================================================================

    # Instala o OBS Studio via módulo do Home Manager.
    programs.obs-studio.enable = true;
  };
}

# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para habilitar `cliphist` (histórico da área de transferência).
#
# Por quê:
# - Mantém histórico de clipboard no Wayland para recuperar itens copiados.
#
# Como:
# - Habilita `services.cliphist`.
#
# Riscos:
# - Histórico pode conter dados sensíveis; avalie limpeza/regras conforme seu uso.
# =============================================================================
{ config, ... }:
let
  # DMS já fornece clipboard manager próprio.
  dmsEnabled =
    (config.rag.rice.dmsUpstream.enable or false)
    || (config.rag.rice.dms.enable or false)
    || (config.programs.dank-material-shell.enable or false);
in
{
  # Evita duplicar o gerenciamento de clipboard quando DMS está ativo.
  services.cliphist.enable = !dmsEnabled;
}

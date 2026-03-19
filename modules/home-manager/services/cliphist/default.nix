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
{ ... }:
{
  # O widget/IPC de clipboard do DMS usa um backend de histórico.
  # Mantemos o cliphist sempre ativo para o shell do DMS e para o fallback via rofi.
  services.cliphist.enable = true;
}

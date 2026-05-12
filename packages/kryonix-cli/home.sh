# kryonix home — wrapper shell para o binário Rust kryonix-home
#
# Delega a execução para o binário compilado.
# A Fase 1 não realiza nenhuma mutação na Home do usuário.

kryonix_home() {
  if ! command -v kryonix-home &>/dev/null; then
    printf 'ERRO: binário kryonix-home não encontrado no PATH.\n' >&2
    printf 'Verifique se o pacote kryonix-home está instalado.\n' >&2
    return 1
  fi

  kryonix-home "$@"
}

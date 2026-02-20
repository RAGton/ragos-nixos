# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para instalar o Telegram Desktop e registrar como app padrão em alguns MIME types.
#
# Por quê:
# - Garante que o Telegram esteja disponível no perfil do usuário.
# - Facilita integração com o sistema ao definir pacotes padrão para aplicações.
#
# Como:
# - Adiciona `pkgs.telegram-desktop` em `home.packages`.
# - Define `xdg.mimeApps.defaultApplicationPackages`.
#
# Riscos:
# - `defaultApplicationPackages` depende do suporte do Home Manager/ambiente XDG.
# =============================================================================
{
  pkgs,
  ...
}:
let
  telegram = pkgs.telegram-desktop;
in
{
  home.packages = [ telegram ];

  xdg.mimeApps.defaultApplicationPackages = [ telegram ];
}

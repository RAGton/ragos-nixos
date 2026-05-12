{
  pkgs,
  ...
}:
{
  # =============================================================================
  # Autor: rag
  #
  # O que é:
  # - Módulo Home Manager que define o Zen Browser como navegador padrão (XDG MIME/protocol handlers).
  #
  # Por quê:
  # - Centraliza o “default browser” do usuário de forma declarativa.
  # - Mantém consistência entre hosts sem precisar configurar via GUI.
  #
  # Como:
  # - Define `xdg.mimeApps.defaultApplications` para tipos/protocolos web.
  # - O app em si é instalado via Flatpak (veja `services/flatpak`).
  #
  # Riscos:
  # - Se o Flatpak/app id mudar, os handlers deixam de apontar para o navegador correto.
  # =============================================================================

  xdg.mimeApps.defaultApplications = {
    "text/html" = "app.zen_browser.zen.desktop";
    "x-scheme-handler/http" = "app.zen_browser.zen.desktop";
    "x-scheme-handler/https" = "app.zen_browser.zen.desktop";
    "x-scheme-handler/ftp" = "app.zen_browser.zen.desktop";
    "application/xhtml+xml" = "app.zen_browser.zen.desktop";
    "application/x-extension-htm" = "app.zen_browser.zen.desktop";
    "application/x-extension-html" = "app.zen_browser.zen.desktop";
    "application/x-extension-shtml" = "app.zen_browser.zen.desktop";
    "application/x-extension-xhtml" = "app.zen_browser.zen.desktop";
    "application/x-extension-xht" = "app.zen_browser.zen.desktop";
  };

  home.sessionVariables = {
    BROWSER = "zen";
    DEFAULT_BROWSER = "zen";
  };
}

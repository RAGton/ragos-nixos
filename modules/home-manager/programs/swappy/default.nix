{ pkgs, ... }:
{
  # =============================================================================
  # Autor: rag
  #
  # O que é:
  # - Módulo Home Manager para instalar o `swappy` e publicar uma config mínima.
  #
  # Por quê:
  # - Padroniza o diretório e o formato de nomes para screenshots editados.
  #
  # Como:
  # - Adiciona `pkgs.swappy` em `home.packages`.
  # - Escreve `~/.config/swappy/config` via `xdg.configFile`.
  #
  # Riscos:
  # - Se o diretório `~/Pictures` não existir, o swappy pode falhar ao salvar.
  # =============================================================================

  # Garante que o pacote swappy esteja instalado.
  home.packages = [ pkgs.swappy ];

  # Importa a configuração do swappy a partir do store do Home Manager.
  xdg.configFile = {
    "swappy/config".text = ''
      [Default]
      save_dir=$HOME/Pictures
      save_filename_format=screenshot-%Y%m%d-%H%M%S.png
    '';
  };
}

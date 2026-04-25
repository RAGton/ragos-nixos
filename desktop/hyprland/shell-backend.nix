{ lib, ... }:
{
  options.kryonix.shell.backend = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.enum [
        "caelestia"
      ]
    );
    default = null;
    description = ''
      Backend de shell/rice ativo neste perfil Home Manager.

      Esta opção serve apenas para o lado user-level saber quais atalhos e
      arquivos de configuração publicar. A ativação principal do shell continua
      sendo responsabilidade do sistema.
    '';
  };
}

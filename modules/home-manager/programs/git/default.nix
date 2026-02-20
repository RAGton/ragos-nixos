# =============================================================================
# Autor: rag
#
# O que é:
# - Módulo Home Manager para configurar `git` e `delta`.
# - Habilita assinatura de commits via chave SSH quando `userConfig.gitKey` for do tipo `ssh-*`.
#
# Por quê:
# - Centraliza identidade (nome/email), preferências e assinatura em todos os hosts.
# - Evita falhas ao habilitar assinatura quando a chave não é SSH.
#
# Como:
# - Cria `~/.config/git/allowed_signers` somente quando a chave é SSH.
# - Configura `programs.git.signing` apenas quando existe chave.
# - Habilita `delta` para pager/diff melhorado.
#
# Riscos:
# - Se `userConfig.gitKey` estiver incorreta, a assinatura pode falhar e o `git` vai recusar commits.
# - `allowed_signers` é gerado a partir de email/chave; mantenha `userConfig` consistente.
# =============================================================================
{ lib, userConfig, ... }:
{
  home.file =
    let
      hasGitKey = userConfig.gitKey != "";
      isSshSigningKey = hasGitKey && lib.hasPrefix "ssh-" userConfig.gitKey;
    in
    lib.mkIf isSshSigningKey {
      ".config/git/allowed_signers".text = "${userConfig.email} ${userConfig.gitKey}\n";
    };

  # Git: identidade e preferências globais do usuário.
  programs.git = {
    enable = true;
    settings =
      let
        hasGitKey = userConfig.gitKey != "";
        isSshSigningKey = hasGitKey && lib.hasPrefix "ssh-" userConfig.gitKey;
      in
      lib.mkMerge [
        {
          user = {
            email = userConfig.email;
            name = userConfig.fullName;
          };
          pull.rebase = "true";
        }
        (lib.mkIf isSshSigningKey {
          gpg = {
            format = "ssh";
            ssh.allowedSignersFile = "~/.config/git/allowed_signers";
          };
        })
      ];

    # Só habilita assinatura se a chave estiver definida.
    signing = lib.mkIf (userConfig.gitKey != "") {
      key = userConfig.gitKey;
      signByDefault = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      keep-plus-minus-markers = true;
      light = false;
      line-numbers = true;
      navigate = true;
      width = 280;
    };
  };
}

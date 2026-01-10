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

  # Instala o git via módulo do Home Manager
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

  # Habilita o tema Catppuccin para o git delta
  catppuccin.delta.enable = true;
}

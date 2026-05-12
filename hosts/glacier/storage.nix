{ lib, ... }:

{
  # Permissões declarativas para o storage do Kryonix.
  # Garante que mesmo após reformat/migração, o usuário 'kryonix' e o grupo 'kryonix'
  # tenham os acessos corretos sem intervenção manual.
  systemd.tmpfiles.rules = [
    # Diretório raiz do Kryonix (ponto de montagem)
    "d /var/lib/kryonix 0755 root root -"

    # Home do Brain e storage LightRAG
    "d /var/lib/kryonix/brain 0770 kryonix kryonix -"
    "d /var/lib/kryonix/brain/storage 0770 kryonix kryonix -"

    # Vault Obsidian (rocha é o dono, kryonix tem acesso de escrita via grupo)
    # 2775: setgid bit garante que novos arquivos no vault pertençam ao grupo kryonix
    "d /var/lib/kryonix/vault 2775 rocha kryonix -"

    # Backups
    "d /var/lib/kryonix/backups 0750 root kryonix -"

    # Ollama (gerenciado pelo próprio serviço, mas garantimos a base)
    "d /var/lib/kryonix/ollama 0750 ollama ollama -"
  ];
}

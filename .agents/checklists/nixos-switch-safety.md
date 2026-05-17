# Checklist: Rebuild e Switch Seguro do NixOS

Este checklist protege o sistema operacional de falhas catastróficas (perda de rede, boot quebrado, SSH inacessível) durante a implantação de novos módulos ou serviços declarativos.

---

## Passos Operacionais e Gates

- [ ] **Não usar switch automaticamente**:
  Comandos como `sudo nixos-rebuild switch`, `nh os switch`, ou `kryonix switch` **nunca** devem ser executados de forma autônoma pelos subagentes. Eles exigem aprovação e execução direta pelo operador humano.

- [ ] **Avaliação Dry-Run Limpa**:
  Antes de propor qualquer switch, certifique-se de que a configuração do host alvo avalia sem erros de sintaxe ou tipos Nix.
  ```bash
  nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link -L --show-trace
  ```
  *(Substitua `<host>` por `inspiron` ou `glacier` conforme aplicável)*

- [ ] **Isolamento de Alterações de Boot e Discos**:
  Se a alteração tocar no bootloader, partições, grub, systemd-boot ou disko:
  - Explicar detalhadamente o risco ao operador.
  - Apresentar o plano exato de rollback.
  - Solicitar confirmação por escrito antes de prosseguir.

- [ ] **Isolamento de Regras de Firewall e Tailscale**:
  Se a alteração envolver regras de rede, iptables, portas ou chaves do Tailscale:
  - Garantir que a porta SSH (`2224` no Glacier) permaneça aberta.
  - Testar conexões ativas de rede antes de desativar regras antigas.

- [ ] **Verificação de systemd-tmpfiles e Permissões**:
  Certificar-se de que caminhos dinâmicos sob `/var/lib/kryonix/` criados por tmpfiles possuem os donos e grupos corretos (`root` ou `kryonix`), impedindo erros de "Permission denied" em tempo de execução dos serviços de IA.

Analise todo o contexto do projeto Kryonix/NixOS/flake antes de editar.

Objetivo:
Implementar uma camada de segurança declarativa e reutilizável para todos os hosts NixOS do projeto, com AppArmor, firewall, SSH hardening, fail2ban, systemd hardening e liberação explícita dos serviços corretos.

Contexto:
- Projeto usa NixOS com flakes.
- Hosts previstos: inspiron, glacier e futuros servidores.
- Glacier será servidor/mini datacenter com serviços Kryonix Brain, Ollama, LightRAG, Tailscale, SSH e possivelmente reverse proxy.
- Inspiron é workstation cliente.
- Segurança deve ser modular, reutilizável e sem quebrar serviços existentes.
- Seguir padrão profissional de flake: modules/, profiles/, hosts/.
- Não colocar tudo no flake.nix.
- Não commitar secrets.
- Não abrir portas desnecessárias.

Tarefas obrigatórias:

1. Auditar estrutura atual
- Ler flake.nix.
- Identificar hosts existentes.
- Identificar módulos, profiles e serviços já definidos.
- Identificar portas usadas por:
  - SSH
  - Tailscale
  - Ollama
  - Kryonix Brain API
  - LightRAG/MCP
  - reverse proxy se existir
  - serviços web expostos

2. Criar módulo base de segurança
Criar:
modules/security/base.nix

Deve conter:
- security.apparmor.enable = true
- firewall enable default deny
- OpenSSH hardening:
  - PermitRootLogin no
  - PasswordAuthentication false
  - KbdInteractiveAuthentication false
  - X11Forwarding false
- fail2ban para SSH
- sudo mais restrito
- sysctl seguro quando compatível
- comentários explicando decisões críticas

3. Criar módulo de firewall por serviço
Criar:
modules/security/firewall-services.nix

Implementar opções declarativas:
- kryonix.security.services.ssh.enable
- kryonix.security.services.tailscale.enable
- kryonix.security.services.brainApi.enable
- kryonix.security.services.ollama.enable
- kryonix.security.services.reverseProxy.enable
- kryonix.security.services.mcp.enable

Cada serviço deve abrir somente as portas necessárias.

Regras:
- SSH: porta configurável, padrão 22 ou porta atual do host se já existir.
- Tailscale: não abrir portas públicas desnecessárias.
- Ollama: não expor publicamente por padrão.
- Brain API: expor preferencialmente só em Tailscale/LAN.
- MCP: não expor publicamente sem autenticação/reverse proxy.
- Reverse proxy: liberar 80/443 somente em host server.

4. Criar profile de segurança para servidores
Criar:
profiles/security/server-hardening.nix

Deve importar:
- modules/security/base.nix
- modules/security/firewall-services.nix

Ativar:
- SSH hardened
- fail2ban
- AppArmor
- firewall
- systemd hardening padrão para serviços Kryonix quando existirem

5. Criar profile de segurança para workstation
Criar:
profiles/security/workstation-hardening.nix

Deve:
- ativar AppArmor
- firewall
- SSH somente se host já usar SSH
- não quebrar Hyprland/Caelestia/Flatpak/apps gráficos
- não aplicar hardening agressivo em sessão gráfica

6. Aplicar nos hosts
- glacier deve usar server-hardening
- inspiron deve usar workstation-hardening
- não alterar comportamento não relacionado

7. Hardening dos serviços Kryonix
Para serviços systemd do projeto, aplicar quando seguro:
- NoNewPrivileges=true
- PrivateTmp=true
- ProtectSystem=strict ou full
- ProtectHome=true quando possível
- ReadWritePaths explícito
- CapabilityBoundingSet vazio quando possível
- RestrictSUIDSGID=true
- LockPersonality=true
- MemoryDenyWriteExecute=true se não quebrar runtime
- Restart=on-failure

Não aplicar opção que quebre:
- Ollama com GPU
- drivers NVIDIA
- acesso ao vault/storage
- rede Tailscale
- MCP stdio

8. AppArmor
- Ativar AppArmor global.
- Verificar se existem profiles úteis em nixpkgs.
- Não criar profile custom agressivo sem modo complain primeiro.
- Se criar profile custom, começar em complain e documentar caminho para enforce.
- Não bloquear Ollama/GPU sem validação.

9. Documentação
Criar:
docs/security/hardening-nixos.md

Documentar:
- o que foi implementado
- portas liberadas por host
- serviços públicos vs LAN/Tailscale
- como testar AppArmor
- como testar firewall
- como validar SSH
- como reverter em caso de bloqueio

10. Validação obrigatória
Rodar:
nix flake check --show-trace

Para cada host:
nixos-rebuild build --flake .#inspiron --show-trace
nixos-rebuild build --flake .#glacier --show-trace

Se estiver no host correto, fazer apenas dry/test, não switch automático sem autorização.

11. Testes manuais esperados
Gerar comandos para validar:
- aa-status
- sudo systemctl status apparmor
- sudo nft list ruleset
- ssh -v host
- systemctl status fail2ban
- curl health da Brain API via Tailscale/LAN
- curl Ollama somente local/Tailscale, nunca público

Regras absolutas:
- Não abrir Ollama em 0.0.0.0 público.
- Não expor MCP público sem auth.
- Não desativar firewall.
- Não alterar senha/usuário.
- Não remover serviços existentes.
- Não aplicar nixos-rebuild switch sem autorização.
- Não commitar secrets.
- Não declarar pronto sem flake check e build dos hosts.

Entrega final:
- arquivos criados/alterados
- portas liberadas por host
- serviços protegidos
- comandos executados
- resultado dos builds
- riscos pendentes
- próximos passos recomendados
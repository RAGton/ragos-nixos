Cole este prompt no Copilot/Antigravity 👇

```txt
Você está no repo NixOS/Kryonix em /etc/kryonix no host inspiron.

PROBLEMA:
`kryonix switch --update` atualizou o flake.lock e agora o rebuild do host `inspiron` está compilando localmente:

- rusty-v8-147.2.1
- deno-2.7.13
- yt-dlp-2026.03.17
- mpv-with-scripts-0.41.0
- kalarm-26.04.0

Isso está usando 100% da CPU por muito tempo. A cadeia vista no build é:

kalarm -> mpv-with-scripts -> yt-dlp -> deno -> rusty-v8

OBJETIVO:
Corrigir a configuração para o host `inspiron` não puxar `kalarm`, `mpv-with-scripts`, `yt-dlp`, `deno` nem `rusty-v8` no system closure, exceto se algum deles for explicitamente necessário e justificado.

REGRAS:
- Não remover Hyprland/Caelestia inteiro sem necessidade.
- Não quebrar o ambiente gráfico.
- Não remover apps essenciais do usuário.
- Não rodar nix-collect-garbage.
- Não fazer reset do flake.lock sem análise.
- Não commitar sem validação.
- Não declarar pronto sem build/test mínimo passando.
- Fazer a menor alteração segura.
- Separar perfil desktop/media/dev se necessário.

TAREFAS:

1. Diagnóstico de dependência
Rodar:

cd /etc/kryonix

nix why-depends \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  nixpkgs#deno \
  --derivation

nix why-depends \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  nixpkgs#kalarm \
  --derivation

grep -R "kalarm\|mpv-with-scripts\|yt-dlp\|deno\|rusty-v8" -n \
  flake.nix hosts modules profiles home packages overlays lib 2>/dev/null || true

Identificar exatamente qual arquivo/opção puxa a cadeia.

2. Corrigir origem
Se `kalarm` estiver em `environment.systemPackages`, `home.packages` ou perfil KDE/media:
- remover do perfil padrão do `inspiron`;
- mover para perfil opcional, exemplo:
  profiles/desktop/kde-apps.nix
  profiles/media/full.nix
  profiles/dev/js-runtime.nix

Se `mpv-with-scripts` estiver puxando `yt-dlp`/`deno`:
- substituir por `pkgs.mpv` simples quando possível;
- deixar `yt-dlp` separado e opcional;
- não usar mpv com scripts pesados no closure base.

Se `deno` estiver em pacote de desenvolvimento:
- remover do systemPackages;
- colocar em devShell ou perfil opcional;
- preferir devShell para ferramentas de desenvolvimento.

3. Criar perfil leve
Garantir que o `inspiron` use apenas pacotes necessários no sistema base.

Modelo esperado:
- base: CLI essencial, rede, git, editor, diagnóstico;
- desktop: Hyprland/Caelestia e apps realmente usados;
- media-full: opcional, não importado por padrão;
- dev-heavy: opcional/devShell, não importado no system closure.

4. Evitar recorrência
Adicionar comentário curto no módulo/perfil onde a correção foi feita:

"Não adicionar deno/yt-dlp/mpv-with-scripts/kalarm no closure base: isso pode puxar rusty-v8 e compilar V8 localmente."

5. Validação obrigatória
Rodar:

nix flake check --show-trace

nix build \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  --dry-run \
  --show-trace \
  --print-build-logs

Depois verificar que NÃO aparece na lista de builds:

- rusty-v8
- deno
- yt-dlp
- mpv-with-scripts
- kalarm

Rodar também:

nix path-info -r \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  | grep -E "rusty-v8|deno|yt-dlp|mpv-with-scripts|kalarm" \
  && echo "ERRO: dependências pesadas ainda no closure" \
  || echo "OK: dependências pesadas ausentes do closure"

6. Switch seguro
Somente se dry-run estiver limpo:

nh os test . -H inspiron

Se `nh os test` passar, então rodar:

nh os switch . -H inspiron

7. Entrega final
Responder com:
- causa raiz encontrada;
- arquivo(s) alterado(s);
- dependência que puxava `rusty-v8`;
- resultado do dry-run;
- confirmação se `rusty-v8/deno/yt-dlp/mpv-with-scripts/kalarm` sumiram do closure;
- resultado do `nh os test`;
- se switch foi aplicado ou não.

IMPORTANTE:
Se alguma dependência ainda aparecer, NÃO declare pronto. Corrija e rode a validação novamente.
```

Após ele corrigir, rode manualmente:

```bash
cd /etc/kryonix
nix path-info -r .#nixosConfigurations.inspiron.config.system.build.toplevel \
  | grep -E "rusty-v8|deno|yt-dlp|mpv-with-scripts|kalarm" \
  || echo "OK limpo"
```

Você está no repo `/etc/kryonix`.

OBJETIVO:
Corrigir a arquitetura do flake para que o host `inspiron` NÃO compile dependências pesadas localmente.
A compilação pesada deve acontecer apenas no host `glacier`.

CONTEXTO:
O `inspiron` executou `kryonix switch --update` e compilou localmente:
- rusty-v8
- deno
- yt-dlp
- mpv-with-scripts
- kalarm

Isso não pode acontecer novamente.

REGRAS:
- `inspiron` = client/dev leve
- `glacier` = servidor/build pesado
- Não remover Hyprland/Caelestia sem necessidade
- Não quebrar o ambiente gráfico do inspiron
- Não declarar pronto sem teste real
- Não commitar sem validação
- Não usar garbage collect agora

TAREFAS:

1. Diagnosticar quem puxa dependências pesadas:

cd /etc/kryonix

nix why-depends \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  nixpkgs#deno \
  --derivation

nix why-depends \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  nixpkgs#kalarm \
  --derivation

grep -R "kalarm\|mpv-with-scripts\|yt-dlp\|deno\|rusty-v8" -n \
  flake.nix hosts modules profiles home packages overlays lib 2>/dev/null || true

2. Separar perfis:

Criar/ajustar estrutura:

profiles/
  base.nix
  desktop.nix
  media-light.nix
  media-heavy.nix
  dev-light.nix
  dev-heavy.nix
  builder-client.nix
  builder-server.nix

Regra:
- `inspiron` importa:
  - base
  - desktop
  - media-light
  - dev-light
  - builder-client

- `glacier` importa:
  - base
  - dev-heavy
  - media-heavy se necessário
  - builder-server

3. Remover do closure do inspiron:

Garantir que `inspiron` NÃO contenha no system closure:
- rusty-v8
- deno
- yt-dlp
- mpv-with-scripts
- kalarm

Se encontrar:
- `mpv-with-scripts` → substituir por `pkgs.mpv`
- `yt-dlp` → mover para `glacier` ou perfil opcional não importado
- `deno` → mover para devShell ou `glacier`
- `kalarm` → remover do inspiron ou mover para perfil KDE opcional

4. Configurar builds remotos no inspiron:

Adicionar no NixOS config do `inspiron`:

nix.distributedBuilds = true;

nix.buildMachines = [
  {
    hostName = "glacier";
    system = "x86_64-linux";
    protocol = "ssh-ng";
    maxJobs = 4;
    speedFactor = 8;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [];
  }
];

nix.settings = {
  builders-use-substitutes = true;
  max-jobs = 0;
  cores = 0;
};

IMPORTANTE:
- `max-jobs = 0` no inspiron força não construir localmente.
- Se isso quebrar UX, usar `max-jobs = 1`, mas preferir `0`.

5. Configurar acesso SSH para builder:

Verificar se existe host SSH:

Host glacier
  HostName 10.0.0.2
  Port 2224
  User rocha
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

Testar:

ssh glacier 'nix --version && hostname && nproc'

6. Configurar glacier como builder:

No host `glacier`, garantir:

nix.settings.trusted-users = [
  "root"
  "rocha"
];

nix.settings.allowed-users = [
  "@wheel"
  "rocha"
];

nix.settings.experimental-features = [
  "nix-command"
  "flakes"
];

services.openssh.enable = true;

7. Testar build remoto:

No inspiron, rodar:

cd /etc/kryonix

nix build \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  --builders 'ssh-ng://glacier x86_64-linux - 4 8 nixos-test,benchmark,big-parallel,kvm' \
  --option max-jobs 0 \
  --option builders-use-substitutes true \
  --dry-run \
  --show-trace

Depois rodar build real de teste:

nix build \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  --builders 'ssh-ng://glacier x86_64-linux - 4 8 nixos-test,benchmark,big-parallel,kvm' \
  --option max-jobs 0 \
  --option builders-use-substitutes true \
  --show-trace

8. Validar que o inspiron não compila local:

Durante o build, no inspiron:

pgrep -af "clang|gcc|rustc|cargo|deno|rusty-v8" \
  && echo "ERRO: compilação local detectada no inspiron" \
  || echo "OK: sem compilação local no inspiron"

No glacier:

ssh glacier 'pgrep -af "clang|gcc|rustc|cargo|deno|rusty-v8" || true'

9. Validar closure limpo:

nix path-info -r \
  .#nixosConfigurations.inspiron.config.system.build.toplevel \
  | grep -E "rusty-v8|deno|yt-dlp|mpv-with-scripts|kalarm" \
  && echo "ERRO: deps pesadas ainda no closure do inspiron" \
  || echo "OK: closure do inspiron limpo"

10. Switch seguro:

Se tudo passou:

nh os test . -H inspiron

Depois:

nh os switch . -H inspiron

11. Entrega final:

Responder com:
- causa raiz
- arquivos alterados
- o que ficou no inspiron
- o que foi movido para glacier
- confirmação do builder remoto
- resultado do dry-run
- resultado do build real
- resultado do grep do closure
- confirmação se houve ou não compilação local

REGRA FINAL:
Não declarar pronto se:
- `rusty-v8`, `deno`, `yt-dlp`, `mpv-with-scripts` ou `kalarm` ainda aparecerem no closure do inspiron;
- o build não usar glacier;
- houver compilação local pesada no inspiron


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
- próximos passos recomendados.

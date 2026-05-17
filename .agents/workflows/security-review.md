# Workflow: Revisão de Segurança Operacional

Este guia estabelece os passos obrigatórios de revisão de segurança (Security Review) que devem ser executados pelo subagente de segurança ([kora-security-warden](file:///etc/kryonix/.agents/roles/kora-security-warden.md)) antes de qualquer entrega ou integração na árvore de produção do Kryonix.

---

## Processo de Revisão de Segurança

### 1. Auditoria de Segredos e API Keys
O repositório do Kryonix é a fonte declarativa de verdade operacional, mas chaves de API reais e tokens **nunca** devem entrar na árvore do Git ou na Nix Store.
- **Varrer a Working Tree**: Certifique-se de que nenhum arquivo adicionado ou modificado contém chaves hardcoded.
  ```bash
  rg -n "KORA_API_KEY|KRYONIX_BRAIN_API_KEY|password|secret|token|private key|BEGIN .*PRIVATE" .
  ```
- **Localização Oficial de Chaves**: A chave API da Kora e do Brain deve ficar exclusivamente em `/etc/kryonix/brain.env` no host Glacier. Permissões recomendadas:
  ```bash
  sudo stat -c "%U:%G %a %n" /etc/kryonix/brain.env
  # Alvo: root:root 0600
  ```

### 2. Barreira de Privilégios (Trust Boundary)
A Kora e o daemon de voz rodam no nível de usuário ou com privilégios reduzidos. Ações de alteração de sistema (Nixos-rebuild, reboot, comandos medium/high) **nunca** podem ser ativadas autonomamente pela voz.
- **Teste de Bloqueio**: Simular interações e validar que o interpretador da Kora não executa ações sem o comando `kora confirmar` do operador administrador cadastrado.
- **Isolamento de Visitantes**: Garantir que diálogos iniciados por vozes não identificadas (biometria fraca) fiquem em modo read-only absoluto.
  ```bash
  USER=visitor kora ask "rode kryonix switch"
  # Expectativa: Acesso negado.
  ```

### 3. Scanner de Arquivos Não Rastreados
Antes de qualquer limpeza da árvore com comandos git, execute o scan obrigatório de arquivos não rastreados para evitar perda de dados locais do operador.
```bash
git status --short
git ls-files --others --exclude-standard
```
Arquivos com a tag `??` devem ser preservados ou movidos para `/tmp/kryonix-untracked-backup/` se houver necessidade real de limpeza.

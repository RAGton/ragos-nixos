# Checklist: Prevenção de Vazamento de Segredos (No Secrets)

Este checklist garante que nenhum segredo de produção, chave API privada ou credencial do operador entre na árvore de controle de versão do repositório Kryonix.

---

## Verificações de Segurança

- [ ] **Scan Ativo de API Keys**:
  Certifique-se de que chaves canônicas do ecossistema não estão escritas no código-fonte.
  ```bash
  rg -n "KORA_API_KEY|KRYONIX_BRAIN_API_KEY" .
  ```

- [ ] **Scan de Palavras-Chave Sensíveis**:
  Varrer a árvore em busca de strings comuns associadas a credenciais.
  ```bash
  rg -n "password|secret|token|private key|BEGIN .*PRIVATE" .
  ```

- [ ] **Isolamento de Arquivos Não Rastreados**:
  Checar se arquivos de ambiente locais (como `.env` ou chaves temporárias) estão listados no `.gitignore` e não correm risco de serem incluídos acidentalmente.
  ```bash
  git status --short
  ```

- [ ] **Permissões de Arquivos Sensíveis**:
  Certificar-se de que arquivos sensíveis em produção no host Glacier (como `/etc/kryonix/brain.env`) estão com a permissão correta e não são visíveis para outros usuários locais.
  ```bash
  stat -c "%U:%G %a %n" /etc/kryonix/brain.env
  # Alvo: root:root 0600
  ```

- [ ] **Nix Store Limpa**:
  Garantir que segredos de ambiente sejam injetados em tempo de execução via systemd `EnvironmentFile=` e nunca declarados inline nos arquivos Nix que entram para a Nix Store pública.

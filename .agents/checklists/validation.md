# Checklist: Validação Geral de Código e Estilo

Este checklist deve ser inteiramente preenchido e validado com comandos reais antes de qualquer alteração de código na Kora ser marcada como **Definition of Done**.

---

## Itens de Validação

- [ ] **Sintaxe Python Válida**:
  Certifique-se de que todas as modificações no pacote `kora` compilam sem erros de sintaxe ou tracebacks.
  ```bash
  python -m compileall packages/kora
  ```

- [ ] **Scripts Shell Saudáveis**:
  Validar a sintaxe de todos os scripts bash e wrappers da CLI do Kryonix.
  ```bash
  bash -n packages/kryonix-cli/*.sh
  ```

- [ ] **Construção Local da Derivação Nix**:
  O pacote customizado da Kora deve compilar perfeitamente na sandbox local do Nix.
  ```bash
  nix build .#kora --no-link -L --show-trace
  ```

- [ ] **Build Completo do Utilitário CLI Kryonix**:
  Verificar se o empacotador de comandos do Kryonix constrói limpo.
  ```bash
  nix build .#kryonix --no-link -L --show-trace
  ```

- [ ] **Flake Check Geral**:
  Rodar o Baseline CI local do flake para verificar se todas as restrições declarativas e dependências do flake.lock são válidas.
  ```bash
  nix flake check --keep-going --show-trace
  ```

- [ ] **Ausência de Erros de Lint de Git**:
  Checar se não há vestígios de conflito ou quebras de espaciação.
  ```bash
  git diff --check
  ```

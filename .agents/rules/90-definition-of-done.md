# Definition of Done (DoD)

Uma tarefa só pode ser considerada pronta se satisfizer os seguintes critérios:

- [ ] **Implementação:** A alteração foi feita conforme o plano e adere estritamente às restrições do papel do subagente.
- [ ] **Teste e Compilação:** 
  - O código Python compila sem tracebacks: `python -m compileall packages/kora`
  - Os testes de regressão de qualidade passam sem falhas: `kora benchmark quality`
  - A derivação Nix é construída na sandbox local sem erros: `nix build .#kora --no-link -L --show-trace`
- [ ] **Integração do Flake:** A validação estrita do ecossistema passa com sucesso: `nix flake check --keep-going --show-trace`
- [ ] **Evidência:** Os resultados dos testes e as gravações/capturas de tela (se houver mudanças de UI) foram documentados e linkados em `docs/TESTING.md` ou no `walkthrough.md`.
- [ ] **Documentação:** A documentação técnica em `docs/` e o índice RAG foram atualizados para refletir a nova verdade do código real do repositório.
- [ ] **Audit e Segurança:** O Security Warden executou a auditoria de secrets e confirmou que nenhum token real ou chave de API foi incluído.
- [ ] **Riscos:** Eventuais riscos de boot, rede ou indisponibilidade física do Glacier foram documentados com planos de rollback claros.
- [ ] **Git Commits:** As alterações foram versionadas em commits pequenos, semânticos e individuais (evitando commits "monólitos" ou `git add .` indiscriminados).

# Core Rules

Regras fundamentais para operação segura no Kryonix.

- **Menor mudança segura:** Sempre prefira a alteração mínima necessária e correta para resolver o problema, sem refatorações estéticas paralelas.
- **Não inventar feature:** Não implemente o que não foi explicitamente solicitado ou que não tenha base factual no estado real do código do repositório.
- **Não declarar pronto sem evidência:** O status "Pronto" exige validação real e registro de evidência por comandos de teste executados.
- **Preservar histórico útil:** Não apague documentação ou código histórico sem mover para `archive/`.
- **Rollback sempre que possível:** Tenha sempre um plano de retorno em caso de falha de boot, rede, firewall, GPU ou áudio.
- **Governança de Commits Estrita:** Nunca utilize `git add .` ou `git commit -a`. Sempre adicione individualmente e com commits pequenos e semânticos (`git add <arquivo>`).
- **Proteção a Arquivos Não Rastreados:** Antes de qualquer limpeza de working tree, execute obrigatoriamente `git status --short` e crie um backup de segurança para arquivos `??` (não rastreados).
- **Sem improvisos:** Se a tarefa fugir do planejado, utilize o workflow `refinement.md` ou proponha um plano estruturado antes de prosseguir.

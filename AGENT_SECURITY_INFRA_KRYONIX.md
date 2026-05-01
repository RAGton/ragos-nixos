Você está no repositório Kryonix. Objetivo: refatorar e limpar a documentação para que ela seja fiel ao estado real do projeto.

Tarefa principal:
Centralizar toda documentação canônica em `docs/`.

Regras absolutas:
- Não inventar funcionalidades.
- Não documentar como pronto o que não está implementado.
- Tudo que estiver planejado, incompleto ou parcial deve ir para `docs/ROADMAP.md`.
- Tudo obsoleto, duplicado, rascunho ou enganoso deve ser removido ou movido para `docs/archive/`.
- Não apagar informação útil sem consolidar antes.
- Não mexer em código funcional salvo se for necessário para corrigir links/caminhos de documentação.
- Não commitar secrets, dumps, storage, cache, logs, ISO, artefatos ou rag_storage.
- Rodar validação antes de declarar pronto.

Contexto importante:
O projeto já tem regras fortes de engenharia: menor mudança segura, NixOS/flake, rollback, systemd, testes e validação real. A documentação deve refletir somente o que existe hoje. Itens como Glacier NixOS definitivo, MCP remoto completo, web research controlado, package generation com IA e autocuradoria do vault ainda devem ficar como roadmap se não estiverem implementados. A regra do projeto é não declarar pronto sem validação real, incluindo testes e checks relevantes.

Escopo:
1. Mapear todos os arquivos `.md`, `.txt`, docs soltas e READMEs.
2. Identificar:
   - documentação canônica
   - documentação duplicada
   - documentação desatualizada
   - documentação de planejamento
   - documentação de agente/prompt
   - relatórios temporários
   - lixo/rascunho
3. Criar estrutura final:

docs/
├── README.md
├── ARCHITECTURE.md
├── INSTALL.md
├── USAGE.md
├── OPERATIONS.md
├── SECURITY.md
├── TESTING.md
├── TROUBLESHOOTING.md
├── ROADMAP.md
├── agents/
│   └── README.md
├── hosts/
│   ├── inspiron.md
│   └── glacier.md
├── brain/
│   ├── README.md
│   ├── lightrag.md
│   ├── mcp.md
│   └── vault.md
└── archive/

4. Consolidar conteúdo real em docs canônicas:
   - `docs/README.md`: visão geral curta e links.
   - `docs/ARCHITECTURE.md`: arquitetura real atual.
   - `docs/INSTALL.md`: instalação real validada.
   - `docs/USAGE.md`: comandos reais existentes.
   - `docs/OPERATIONS.md`: operação diária, rebuild, sync, backup.
   - `docs/SECURITY.md`: hardening, secrets, SSH, Tailscale, firewall.
   - `docs/TESTING.md`: comandos reais de teste.
   - `docs/TROUBLESHOOTING.md`: erros reais e correções.
   - `docs/ROADMAP.md`: tudo que ainda não existe ou está parcial.

5. Atualizar ou criar `AGENTS.md` com regras:
   - consultar `docs/README.md` primeiro;
   - documentação canônica fica em `docs/`;
   - prompts/agentes ficam em `docs/agents/`;
   - não criar docs soltas na raiz;
   - não documentar feature inexistente como implementada;
   - mover planos para `docs/ROADMAP.md`;
   - sempre rodar testes antes de declarar pronto.

6. Atualizar links quebrados.
7. Remover referências falsas a funcionalidades não implementadas.
8. Criar índice navegável em `docs/README.md`.
9. Atualizar `.gitignore` se necessário para ignorar:
   - `scratch/`
   - `diagnostics*/`
   - `*.log`
   - `*.iso`
   - `result`
   - `kryonix-artifacts/`
   - `rag_storage/`
   - caches temporários

Critérios de qualidade:
- Documentação curta, técnica e objetiva.
- Sem marketing.
- Sem promessa falsa.
- Sem duplicação.
- Cada arquivo deve ter propósito claro.
- Roadmap separado do estado atual.
- Comandos documentados precisam existir no repo.
- Se um comando não existir, mover para roadmap ou remover.

Validação obrigatória:
Rodar, conforme disponível no repo:

git status
find . -name "*.md" -o -name "*.txt"
grep -R "TODO\|WIP\|não implementado\|planejado\|futuro" docs/ || true
grep -R "<<<<<<<\|=======\|>>>>>>>" . || true
nix flake check --show-trace || true
./rag.bat test all || true
./scripts/check-docs.sh || true

Se algum comando não existir, registrar isso em `docs/TESTING.md` como pendência ou criar script simples se fizer sentido.

Entrega final:
- listar arquivos criados/movidos/removidos;
- explicar o que virou documentação canônica;
- explicar o que foi para roadmap;
- listar lixos removidos/arquivados;
- mostrar resultado dos checks;
- não declarar pronto se houver erro crítico.
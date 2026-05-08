# Kryonix Structural Audit

## Status
Status: Implementado

## Resumo Executivo
O repositório Kryonix encontra-se em um estado **funcional e estável**. Os builds de CLI, Host (Inspiron) e Home Manager concluem com sucesso. A árvore atual demonstra uma transição madura para o NixOS declarativo, com boa separação de módulos, perfis e configuração de IA. No entanto, o `flake.nix` (330 linhas) está começando a ficar sobrecarregado, e há um volume considerável de documentação legada/arquitetural duplicada ou fragmentada espalhada pelos diretórios de contexto (`.ai`, `.agents`, `.context`, `docs/`).

### Principais Riscos Encontrados
- **Poluição Documental:** Existem múltiplos `README`, `ARCHITECTURE` e `CURRENT_STATE` fragmentados. Isso causa confusão para novos agentes/usuários.
- **`flake.nix` Monolítico:** A definição de inputs, configurações e overlays no mesmo arquivo dificulta a manutenção em larga escala.
- **Artefatos Locais:** A presença de symlinks como `result` soltos na raiz indica falta de limpeza após testes locais.
- **Modularização Faltante:** Alguns módulos de sistema/home estão misturados ou com escopos que poderiam ser melhor definidos.

### Decisões Imediatas
- A configuração atual do repositório é canônica.
- O Glacier e o Inspiron estão devidamente modelados e isolados.
- As integrações sensíveis (como secrets do Brain) estão protegidas (`brain.env` e `neo4j.env` no `.gitignore`).

---

## Inventário da Raiz

| Caminho | Classe | Estado | Ação Recomendada |
| :--- | :--- | :--- | :--- |
| `flake.nix` / `flake.lock` | Core Nix | Funcional, 330 linhas | Modularizar via `/flake/` |
| `hosts/` | Hosts | Estável | Manter |
| `modules/` / `profiles/` / `features/` | Modules | Funcional | Consolidar sobreposições |
| `home/` / `desktop/` | Home/Desktop | Estável | Manter |
| `packages/` | Packages/CLI | Funcional (CLI central) | Continuar evoluindo via `kryonix-cli` |
| `scripts/` | Scripts | 80 scripts identificados | Auditar uso real e depreciar legados |
| `docs/` / `AGENTS.md` / `README*` | Docs | 144 docs; muita sobreposição | Unificar, migrar para archive |
| `.ai/` / `.agents/` / `.context/` / `context/` / `skills/` | AI/Agents/Context | Fragmentado | Consolidar fluxo de RAG/CAG |
| `overlays/` / `lib/` | Core Nix Extensível | Funcional | Manter |
| `.git/` / `.github/` / `.vscode/` | Configurações | OK | Nenhuma |
| `result` | Build Artifacts | Lixo de build | Remover/Gitignore |
| `brain.env` / `neo4j.env` | Secrets Ignorados | OK, ignorados | Manter segurança atual |

---

## Estrutura Canônica Recomendada

Para comportar o crescimento do projeto, recomenda-se a seguinte árvore:

```text
kryonix/
├── flake.nix
├── flake/                     # Modularização do flake.nix
│   ├── inputs.nix
│   ├── outputs.nix
│   ├── hosts.nix
│   └── packages.nix
├── hosts/                     # Configuração específica por máquina
├── modules/                   # Módulos NixOS genéricos
├── profiles/                  # Papéis reutilizáveis (server, workstation)
├── features/                  # Capacidades opt-in (gaming, ai, etc)
├── home/                      # Configurações do Home Manager
├── desktop/                   # WM, DE, Wayland, X11
├── packages/                  # Derivations customizadas e scripts encapsulados
├── scripts/                   # Scripts isolados (apenas o essencial)
├── docs/                      # Documentação centralizada
│   ├── operations/
│   ├── brain/
│   ├── hosts/
│   └── ai/                    # Integrando antigas .context, context, .ai, .agents
├── .agents/                   # Regras estritas de agentes e workflows
├── .ai/                       # Prompts e submodulos (ex: kryonix-vault)
├── context/                   # Retirar se consolidado com docs/ai/
└── files/                     # Arquivos estáticos sem lógica Nix
```

---

## Achados

### Críticos
- Nenhuma falha crítica no build. Todos os targets Nix compilaram com sucesso no host Inspiron, sem links rompidos no Home Manager.

### Importantes
- **Documentação Redundante:** O excesso de diretórios ocultos (`.context`, `.ai`, `.agents`) gerando `README`s colidentes afeta a aderência dos agentes ao estado canônico (AGENTS.md).
- **Flake Monolítico:** A divisão do `flake.nix` para o diretório `/flake/` vai simplificar a visão dos overlays e configurações isoladas.

### Cosméticos
- Arquivos de lixo: O build local gerou diretório `result` que deveria ser removido após o uso (`nh os build` resolve isso ocultando o path, ou podemos adicionar ao `.gitignore` se quisermos usar `nix build` puro).
- Existem múltiplos arquivos de Markdown como "ARCHITECTURE" (ex: `docs/ARCHITECTURE.md`, `docs/agents/CONTEXT_ARCHITECTURE.md`, `docs/archive/...`).

### Roadmap
- Realizar a limpeza das documentações antigas, varrendo as não implementadas para um diretório histórico.
- Executar a refatoração do `flake.nix` (Fase S6).

---

## Pendências por fase

- [x] **S1:** API / Brain Security Hardening
- [x] **S2:** Caelestia / Desktop Launcher
- [x] **S3:** Disko Inspiron Formatação e Validação
- [x] **S4:** Plano Glacier Disko Documentado
- [x] **S5:** Auditoria Estrutural Executada (este documento)
- [ ] **S6:** Flake Modularization & Cleanup
- [x] **S7:** WayVNC Secure Remote Access (Implementado e Validado)

---

## Plano de Ação

Fases recomendadas para as próximas iterações pequenas:
1. Limpar resíduos óbvios (`result`, arquivos `.bak`, lixo de scripts obsoletos).
2. Organizar docs (centralizar `ARCHITECTURE`, migrar diretórios ocultos legados para `docs/ai/` ou archive).
3. Normalizar scripts remanescentes do diretório `/scripts/` em pacotes via `packages/` se necessário.
4. Modularizar `flake.nix` separando `inputs`, `outputs`, `packages` etc., mantendo idempotência (S6).
5. Validar builds e checagens finais.

---

## Não Fazer
- Não mover `hosts` ou `modules` sem uma validação prévia minuciosa.
- Não apagar docs históricos sem antes criar um archive claro.
- Não mexer em `flake.lock` ou realizar pull automático em máquinas em produção sem plano de rollback.
- Não rodar `nixos-rebuild switch` diretamente sem intervenção manual após refatorações profundas.
- Não rodar `disko` em máquinas live sem formatação dedicada.

---

## Validações Executadas

Os seguintes comandos foram validados sem erros durante a auditoria (estado Limpo/OK):

```bash
git status --short
git log --oneline --decorate -8
git submodule status --recursive

# Verificações de Lixo
find . -maxdepth 2 \( -name "result" -o -name "result-*" \) -print
rg "TODO|FIXME|Legado" docs .ai .agents context AGENTS.md

# Validação do Build
nix build .#kryonix --no-link
nix build .#nixosConfigurations.inspiron.config.system.build.toplevel --no-link -L
nix build .#homeConfigurations."rocha@inspiron".activationPackage --no-link -L
```

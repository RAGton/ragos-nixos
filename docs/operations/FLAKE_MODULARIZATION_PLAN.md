# Flake Modularization Plan

> **Status:** Roadmap — não implementado.
> Execute somente quando o flake.nix atingir complexidade que justifique a divisão.
> Critério mínimo: > 500 linhas OR múltiplos mantenedores OR blocos difíceis de navegar individualmente.

---

## Estado atual (auditado em 2026-05-07)

| Métrica | Valor |
|---|---|
| Linhas | 331 (330 + newline) |
| Bloco inputs | linhas 25–74 (13 inputs) |
| Bloco helpers/let | linhas 86–234 |
| Bloco outputs | linhas 236–329 |
| Hosts NixOS declarados | 5 (inspiron, inspiron-nina, glacier, glacier-live, iso) |
| Homes declarados | 3 (rocha@inspiron, rocha@glacier, nina@inspiron-nina) |
| DevShells | 2 (default/latex, deno) |
| Packages | 2 (kryonix, deno-cache-only) |
| Checks | 8 (formatting + 7 eval checks) |

**Diagnóstico:** flake.nix está grande mas bem estruturado e comentado. Não há urgência de refatoração.
Os riscos de refatorar (regressão de avaliação, flake lock, nixosConfigurations inacessíveis) superam os benefícios atuais.

---

## Problemas reais que justificariam modularização

- [ ] `let` block maior que ~200 linhas com funções complexas
- [ ] Mais de 8 hosts declarados
- [ ] Duplicação real de lógica entre blocos
- [ ] Dificuldade de navegar para um bloco específico (inputs, checks, devShells)
- [ ] Múltiplos mantenedores tocando o mesmo arquivo com conflitos de merge

**Nenhum desses problemas existe hoje.**

---

## Estrutura alvo (quando necessário)

```
flake.nix          ← roteador fino: só imports e outputs = import ./flake/<bloco>
flake/
├── inputs.nix     ← { nixpkgs, home-manager, hardware, disko, ... }
├── lib.nix        ← mkNixosConfiguration, mkHomeConfiguration, users, helpers
├── overlays.nix   ← repoOverlays, mkHomePkgs
├── packages.nix   ← kryonix, deno-cache-only
├── devshells.nix  ← latexShell, denoShell
├── checks.nix     ← formattingCheck, eval checks
├── nixos.nix      ← nixosConfigurations (hosts)
└── home.nix       ← homeConfigurations (users)
```

### Padrão de roteamento

```nix
# flake.nix futuro (exemplo esquemático)
{
  inputs = (import ./flake/inputs.nix);
  outputs = { self, ... }@inputs:
    let
      lib = import ./flake/lib.nix { inherit inputs self; };
    in {
      nixosConfigurations = import ./flake/nixos.nix { inherit inputs lib; };
      homeConfigurations  = import ./flake/home.nix  { inherit inputs lib; };
      packages            = import ./flake/packages.nix { inherit inputs lib; };
      devShells           = import ./flake/devshells.nix { inherit inputs lib; };
      checks              = import ./flake/checks.nix { inherit inputs lib; };
      overlays            = import ./flake/overlays.nix { inherit inputs; };
      formatter           = lib.forAllSystems lib.formatterFor;
    };
}
```

---

## Validação obrigatória pré e pós refatoração

```bash
# Antes (baseline)
nix flake show --all-systems 2>&1 | head -40
nix flake check --keep-going

# Pós refatoração
nix flake show --all-systems 2>&1 | head -40
nix flake check --keep-going
nix build .#kryonix --no-link
nix build .#nixosConfigurations.inspiron.config.system.build.toplevel --no-link -L
nix build .#homeConfigurations."rocha@inspiron".activationPackage --no-link -L
```

---

## Itens que NÃO devem ir para flake/

| Item | Destino correto |
|---|---|
| Hardware específico | `hosts/<host>/hardware-configuration.nix` |
| Opções de host | `hosts/<host>/default.nix` |
| Módulos reutilizáveis | `modules/nixos/**` |
| Perfis compostos | `profiles/**` |
| Home Manager | `home/<user>/<host>/**` |
| Overlays | `overlays/` (já separado) |
| Pacotes | `packages/` (já separado) |

---

## Regra de execução

> Antes de qualquer commit de refatoração do flake:
> 1. Abrir issue ou PR draft com o diff completo.
> 2. Rodar todos os checks acima e registrar resultado.
> 3. Manter rollback disponível (`git revert` ou branch separada).
> 4. Nunca refatorar no mesmo commit de uma mudança funcional.

---

## Referências

- [flake.nix atual](../../flake.nix)
- [Validação canônica](KRYONIX_VALIDATION.md)
- [Comandos canônicos](KRYONIX_COMMANDS_CANONICAL.md)

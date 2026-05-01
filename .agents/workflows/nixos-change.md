# NixOS Change Workflow

## Quando usar
Para qualquer alteração em arquivos `.nix`, módulos, hosts ou no `flake.nix`.

## Regras aplicadas
- `.agents/rules/30-nixos.md`
- `.agents/rules/40-security.md`

## Entradas
- Arquivos `.nix` alvo.
- Requisitos de configuração.

## Saídas
- Configuração NixOS atualizada.
- Resultado de `nix flake check`.

## Arquivos permitidos
- `hosts/**/*`
- `modules/**/*`
- `profiles/**/*`
- `flake.nix`

## Arquivos proibidos
- Alterações em `hardware-configuration.nix` sem motivo explícito.

## Passos
1. **Modificar:** Alterar a configuração declarativa.
2. **Avaliar:** Rodar `nix flake show` ou `nix-instantiate` para verificar sintaxe.
3. **Checar:** Rodar `nix flake check` se aplicável.
4. **Validar:** Simular o build com `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link`.

## Validação obrigatória
- O build da derivação do sistema deve passar.

## Rollback
- Reverter arquivos `.nix` para o estado anterior.

## Output final esperado
Sistema configurado corretamente e pronto para aplicação via `switch`.

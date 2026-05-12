# Guia de Operações (Runbook)

Este guia destina-se a administradores e desenvolvedores do sistema Kryonix.

## Diagnóstico de Saúde

### Validar CLI e Binários
```bash
kryonix check
nix flake check
kryonix home --help
```

### Validar Integridade da Taxonomia
Execute o script de regressão oficial:
```bash
./scripts/validate-home-brain-phase3b.sh
```

## Localização de Dados

| Dado | Caminho |
| :--- | :--- |
| Configuração (Taxonomia) | `~/.config/kryonix/home-taxonomy.toml` |
| Estado do Scan | `~/.local/state/kryonix/home-brain/scan_latest.json` |
| Último Plano | `~/.local/state/kryonix/home-brain/plan_latest.json` |
| Manifesto Ativo | `~/.local/state/kryonix/home-brain/manifest_latest.json` |
| Log de Auditoria | `~/.local/state/kryonix/home-brain/audit_log.json` |
| Backup de Rollback | `~/.local/state/kryonix/home-brain/rollback/` |

## Resolução de Problemas

### Erro: "Submodule path... checked out '...'"
Isso acontece quando o ponteiro do git no superprojeto diverge do que você esperava.
**Solução:** Entre no submódulo, dê `git checkout main` e então `git add packages/kryonix-home` no superprojeto.

### Erro: "Explicitly specified home-manager configuration not found"
Isso ocorre quando você tenta rodar `kryonix home` sem passar um subcomando válido, disparando o fallback para o `nh home` que exige uma configuração declarada.
**Solução:** Certifique-se de usar subcomandos como `scan`, `plan`, `apply`, etc.

### Limpeza de Estado
Se o estado do Home Brain estiver corrompido:
```bash
rm -rf ~/.local/state/kryonix/home-brain/*
```
*Atenção: Isso impossibilita o rollback de ações passadas.*

## Procedimento de Emergência (Rollback Manual)
Se o `kryonix home rollback` falhar, você pode consultar o último manifesto em `~/.local/state/kryonix/home-brain/manifest_latest.json` e mover os arquivos manualmente de volta para o `source_path` registrado.

# 05 — Política de Segurança: Kryonix Home Brain

## Política de ação

| Ação | Permitida na Fase 1? | Observação |
|---|---:|---|
| Escanear arquivos permitidos | Sim | Sem pastas ocultas |
| Calcular metadados | Sim | Seguro |
| Calcular SHA256 | Sim | Preferir limite/tamanho |
| Gerar relatório | Sim | Seguro |
| Gerar plano dry-run | Sim | Seguro |
| Mover arquivo | Não | Só Fase 2+ |
| Renomear arquivo | Não | Só Fase 2+ |
| Apagar arquivo | Não | Nunca automático |
| Quarentena | Não | Só Fase 2+ |
| Chamar LLM | Não | Só Fase 3+ |
| Indexar no Brain | Não | Só Fase 4+ |
| Escrever Neo4j | Não | Só Fase 5+ |

## Pastas proibidas

```txt
~/.*
~/.config
~/.local
~/.cache
~/.ssh
~/.gnupg
~/.mozilla
~/.thunderbird
~/.var
~/.nix-profile
```

## Arquivos proibidos

```txt
.env
brain.env
neo4j.env
*.key
*.pem
*.secret
*.token
id_ed25519
id_rsa
```

## Repositórios e projetos

Ignorar diretórios contendo:

```txt
.git
flake.nix
Cargo.toml
pyproject.toml
package.json
go.mod
```

A regra é simples:

> Se parece projeto, não organizar automaticamente.

## Duplicatas

### Duplicata exata

Permitida apenas quando:

```txt
size igual
SHA256 igual
MIME compatível
```

### Duplicata possível

Arquivos parecidos por nome, imagem, texto ou embedding:

```txt
NÃO deletar
NÃO substituir
marcar como POSSIVEL_DUPLICATA
exigir revisão manual
```

## Rollback futuro

Toda ação real futura precisa gerar:

```txt
old_path
new_path
sha256_before
sha256_after
timestamp
run_id
reason
```

## Regras contra desastre

- Sem `rm -rf`.
- Sem `find -delete`.
- Sem aplicar plano sem manifesto.
- Sem operar fora da Home.
- Sem seguir symlink perigoso.
- Sem atravessar mount externo sem flag explícita.
- Sem alterar permissões de arquivos.

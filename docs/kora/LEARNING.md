# Kora Learning

Status: Parcial

## Objetivo

O learning da Kora guarda correcoes, aliases e preferencias do Ragton de forma incremental, auditavel e reversivel.

Ele nao treina modelo automaticamente.

## Storage

- Perfil: `/var/lib/kryonix/kora/learning/ragton/profile.json`
- Correcoes: `/var/lib/kryonix/kora/learning/ragton/corrections.json`
- Aliases: `/var/lib/kryonix/kora/learning/ragton/aliases.json`
- Eventos diarios: `/var/lib/kryonix/kora/learning/ragton/daily/`
- Resumo humano: `/var/lib/kryonix/vault/Kora/Learning/Daily/`

Se o processo nao tiver permissao em `/var/lib`, a CLI usa fallback local em `~/.local/share/kryonix/kora/learning`.

## Comandos

```bash
kora learning status
kora learning profile
kora learning corrections
kora learning aliases
kora learning add-correction "pentifino" "pente fino"
kora learning add-alias "pente fino" "auditoria técnica detalhada"
kora learning daily-summary
```

## Regras

- Correcoes sao aplicadas antes do roteamento e antes da KoraMind.
- Aliases entram como contexto, nao substituem agressivamente a intencao do usuario.
- Secrets sao bloqueados por padroes de privacidade antes de eventos de aprendizado.
- Voz nao autoriza comandos criticos.

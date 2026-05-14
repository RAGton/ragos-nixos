# Hosts

Status: Implementado (mapa de hosts)

## Resumo
Kryonix define hosts NixOS por papel. O `glacier` é o servidor IA; `inspiron` é o cliente/workstation; `iso` é a imagem instalável.

## Hosts atuais
| Host | Papel | Status |
|---|---|---|
| `glacier` | Servidor IA / workstation gamer | Implementado |
| `inspiron` | Cliente leve / workstation | Implementado |
| `inspiron-nina` | Workstation leve | Implementado |
| `iso` | Imagem instalável | Parcial |

## Quando usar
Para escolher o host correto e aplicar validações direcionadas.

## Comandos relevantes
```sh
kryonix check --host glacier
kryonix rebuild --host glacier
kryonix test --host glacier
```

## Riscos
- Alterações de hardware/boot sem validação.
- Aplicar `switch` remoto sem plano de rollback.

## Links relacionados
- [Glacier](Glacier)
- [Inspiron](Inspiron)
- [Arquitetura](Arquitetura)

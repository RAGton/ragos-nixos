# ADR-0002 — Apps Gráficas do Launcher via Desktop Entry Resolvido

## Status

Aceita em 2026-04-23.

## Decisão

Apps gráficas selecionadas no launcher do Caelestia devem chegar ao `uwsm` como desktop entry resolvido por caminho real ou ID válido com `.desktop`.

## Motivo

O launcher upstream estava passando IDs nus como `org.kde.dolphin` e `com.gexperts.Tilix`.
No host real, isso gerou pelo menos dois comportamentos incorretos:

- `uwsm` tentando tratar o ID como executável e retornando `Command not found`
- wrappers/desktop entries customizados do repositório deixando de ser o caminho explícito de launch

## Alternativas rejeitadas

- trocar Caelestia por outro launcher
- reintroduzir `wofi`
- parsear manualmente `Exec=` no repositório

## Consequência

Mantemos `uwsm`, mantemos o launcher atual e corrigimos o helper mínimo no pacote do Caelestia com um patch local.

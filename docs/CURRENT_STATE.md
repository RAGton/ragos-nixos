# Estado atual do RagOS VE

**Atualizado em:** 2026-04-23

## Resumo

O `ragos-nixos` já está operando, na prática, como **RagOS VE**: uma plataforma NixOS pessoal para workstation, gaming, virtualização, estudo e desenvolvimento.

A base atual já entrega:

- múltiplos hosts (`inspiron`, `inspiron-nina`, `glacier`, `iso`)
- múltiplos usuários (`rocha`, `nina`)
- namespace `rag.*`
- `hosts/common/default.nix` como agregador compartilhado
- `features/` e `profiles/` reais
- stack desktop **Hyprland** com **Caelestia** como shell principal
- CLI operacional `ragos`
- ferramentas de estudo e AI do usuário com Obsidian, Codex CLI, Claude Code e launcher manual do Trae
- `nixosConfigurations`, `homeConfigurations`, `overlays`, `formatter` e `checks`

## Arquitetura real

### Camadas principais

- `hosts/`: hardware, boot e papel de cada máquina
- `hosts/common/default.nix`: composição compartilhada
- `lib/options.nix`: opções públicas `rag.*`
- `modules/nixos/**`: base, rede, áudio, desktop, serviços, theming
- `features/**`: capacidades opt-in
- `profiles/**`: composição reutilizável por papel
- `desktop/hyprland/**`: stack desktop atual
- `home/**`: perfis Home Manager por usuário/host

## Estado por host

### inspiron

- notebook principal
- Intel
- Hyprland + Caelestia
- profile de laptop com virtualização e desenvolvimento

### inspiron-nina

- notebook da Nina
- Intel
- Hyprland + Caelestia
- perfil mais leve

### glacier

- desktop AMD + NVIDIA
- Hyprland + Caelestia
- host principal para workstation, virtualização e gaming
- storage operacional em `/srv/ragenterprise`

### iso

- saída de instalação/provisionamento

## O que está bom

- a arquitetura pública do flake está clara
- hosts estão mais finos do que em fases antigas
- o namespace `rag.*` já existe e é usado
- o desktop principal já está materializado
- o fluxo operacional já pode convergir para `ragos`
- Caelestia já está integrado no nível de sistema sem ativação principal via Home Manager
- o fluxo diário do shell já é Caelestia-first: launcher, control center, dashboard, sessão, lock, notificações e wallpapers
- os perfis `rocha@inspiron` e `rocha@glacier` expõem Obsidian como app canônico de notas e wrappers npm-backed para Codex/Claude
- a galeria de wallpapers do shell usa `~/.local/share/wallpapers` como fonte declarativa

## O que ainda precisa de atenção

### 1. Documentação desencontrada

Parte da documentação ainda descreve o projeto como se a arquitetura atual não existisse.

### 2. Home Manager ainda parcialmente v1

Alguns homes ainda importam desktop/rice diretamente, o que impede a consolidação completa do modelo por opções.

### 3. Legado de shell ainda precisa de poda final

Hoje a direção arquitetural já está fechada, mas ainda existem resíduos legados de DMS no repositório que não devem voltar ao caminho ativo.

### 4. Duplicação no stack Hyprland

Wrappers e helpers ainda aparecem em mais de um lugar.

### 5. Módulos grandes

`desktop/hyprland/user.nix` e outros arquivos ainda concentram responsabilidade demais.

### 6. Resíduos de migração

Ainda existem trechos, nomes e documentos legados de uma fase anterior da arquitetura.

### 7. Naming público ainda parcial

O branding público já pode ser tratado como **RagOS VE**, mas o nome do repositório e alguns documentos históricos ainda carregam `ragos-nixos`.

## Decisões atuais

- o desktop real do projeto hoje é `hyprland`
- os hosts Hyprland ativos usam Caelestia como shell principal em nível de sistema
- os atalhos principais do shell priorizam os drawers nativos do Caelestia e deixam rofi/wlogout só como fallback
- documentação histórica deve continuar existindo, mas claramente marcada como histórica
- notebook principal não deve auto-bloquear nem auto-suspender por padrão
- `glacier` deve ser tratado como host principal para virtualização e gaming
- `RagOS` continua sendo o nome base do sistema; `VE` identifica a edição/workstation atual

## Prioridades imediatas

1. alinhar documentação canônica com o estado real
2. podar os resíduos finais de DMS sem reintroduzir ativação via Home Manager
3. simplificar a modelagem desktop/rice/features
4. reduzir duplicação no stack Hyprland
5. quebrar módulos grandes
6. melhorar energia/idle no notebook principal
7. refinar `glacier` como workstation principal

## Desenvolvimento local do Caelestia

- input padrão do shell: `github:caelestia-dots/shell` pinado no `flake.lock`
- clone local de desenvolvimento recomendado no `inspiron`: `/home/rocha/src/caelestia-shell`
- para testar o clone local sem vazar esse path para os outros hosts, usar override explícito:

```bash
nixos-rebuild test --flake .#inspiron \
  --override-input caelestia-shell path:/home/rocha/src/caelestia-shell
```

- RustDesk no `inspiron`: pacote nativo do nixpkgs, sem Flatpak.
- GDM no `inspiron`: permanece em Wayland; a sessão do usuário também continua em Hyprland/Wayland.

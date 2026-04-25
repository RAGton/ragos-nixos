# Estado atual do Kryonix

**Atualizado em:** 2026-04-25

## Resumo

O projeto agora está em migração operacional de `ragos` para **Kryonix**.

A base atual entrega:

- múltiplos hosts (`inspiron`, `inspiron-nina`, `glacier`, `iso`)
- múltiplos usuários (`rocha`, `nina`)
- namespace primário `kryonix.*`
- compatibilidade temporária para `rag.*`
- `hosts/common/default.nix` como agregador compartilhado
- `features/` e `profiles/` reais
- stack desktop **Hyprland** com **Caelestia** como shell principal
- CLI operacional primária `kryonix`
- alias temporário `ragos`
- `nixosConfigurations`, `homeConfigurations`, `overlays`, `formatter` e `checks`

## Arquitetura real

- `hosts/`: hardware, boot e papel de cada máquina
- `hosts/common/default.nix`: composição compartilhada
- `lib/options.nix`: opções públicas `kryonix.*` com alias `rag.*`
- `modules/nixos/**`: base, rede, áudio, desktop, serviços, theming
- `features/**`: capacidades opt-in
- `profiles/**`: composição reutilizável por papel
- `desktop/hyprland/**`: stack desktop atual
- `home/**`: perfis Home Manager por usuário/host
- `packages/kryonix-cli.nix`: CLI nova
- `packages/ragos-cli.nix`: wrapper legado de compatibilidade

## Repositórios

- repo principal: `https://github.com/RAGton/kryonix`
- vault de conhecimento: `https://github.com/RAGton/kryonix-vault.git`

## Compatibilidade de rename

- `ragos` continua executando `kryonix` e emite aviso de depreciação
- `/etc/kryonix` é o caminho operacional primário
- `/etc/ragos` continua aceito como fallback
- opções `rag.*`, `services.rag.*`, `programs.ragos.*` e `ragos.*` permanecem como aliases temporários

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

## Decisões atuais

- o desktop real do projeto hoje é `hyprland`
- os hosts Hyprland ativos usam Caelestia como shell principal em nível de sistema
- documentação histórica deve continuar existindo, mas não é fonte de verdade ativa
- notebook principal não deve auto-bloquear nem auto-suspender por padrão
- `glacier` deve ser tratado como host principal para virtualização e gaming
- `Kryonix` é o nome público atual

## Atenções abertas

- remover aliases `rag.*` e `ragos` só depois de uma janela de migração validada
- revisar docs históricas fora da trilha canônica em uma etapa separada
- `desktop/hyprland/user.nix` ainda concentra responsabilidade demais
- resíduos legados de DMS não devem receber novos acoplamentos

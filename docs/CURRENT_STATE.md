# Estado atual do Kryonix

**Atualizado em:** 2026-04-29

## Resumo

O projeto opera com **Kryonix** como superfície pública. A trilha oficial é 100% NixOS/Linux e a CLI pública é `kryonix`.

A base atual entrega:

- múltiplos hosts (`inspiron`, `inspiron-nina`, `glacier`, `iso`)
- múltiplos usuários (`rocha`, `nina`)
- namespace primário `kryonix.*`
- aliases legados internos temporários para configurações antigas
- `hosts/common/default.nix` como agregador compartilhado
- `features/` e `profiles/` reais
- stack desktop **Hyprland** com **Caelestia** como shell principal
- CLI operacional primária `kryonix`
- `nixosConfigurations`, `homeConfigurations`, `overlays`, `formatter` e `checks`

## Arquitetura real

- `hosts/`: hardware, boot e papel de cada máquina
- `hosts/common/default.nix`: composição compartilhada
- `lib/options.nix`: opções públicas `kryonix.*` com aliases internos temporários
- `modules/nixos/**`: base, rede, áudio, desktop, serviços, theming
- `features/**`: capacidades opt-in
- `profiles/**`: composição reutilizável por papel
- `desktop/hyprland/**`: stack desktop atual
- `home/**`: perfis Home Manager por usuário/host
- `packages/kryonix-cli.nix`: CLI nova
- `packages/kryonix-brain-lightrag/`: Brain/LightRAG usado por `kryonix brain`, `kryonix graph`, `kryonix mcp` e `kryonix test`

## Repositórios

- repo principal: `https://github.com/RAGton/kryonix`
- vault de conhecimento: `https://github.com/RAGton/kryonix-vault.git`

## Compatibilidade legada

- `/etc/kryonix` é o caminho operacional primário
- aliases internos podem existir para não quebrar hosts antigos, mas não são interface pública
- docs e fluxos operacionais devem usar apenas `kryonix`

## Estado por host

### inspiron

- notebook principal
- Intel
- Hyprland + Caelestia
- profile de laptop com virtualização e desenvolvimento
- cliente Brain: roda `kryonix-cli` e consulta o Brain remoto no `glacier`
- `kryonix brain health`, `kryonix brain stats` e `kryonix brain search "pergunta"` usam `KRYONIX_BRAIN_API` quando configurado
- não exige Ollama, GraphML ou storage LightRAG local para validação de build/configuração

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
- servidor Brain central: Ollama, Kryonix Brain API, LightRAG storage, MCP Brain, vault e índice
- valida runtime local com `systemctl status ollama`, `systemctl status kryonix-brain`, `kryonix brain doctor --local` e `kryonix graph stats --local`

### iso

- saída de instalação/provisionamento

## Decisões atuais

- o desktop real do projeto hoje é `hyprland`
- os hosts Hyprland ativos usam Caelestia como shell principal em nível de sistema
- documentação histórica deve continuar existindo, mas não é fonte de verdade ativa
- notebook principal não deve auto-bloquear nem auto-suspender por padrão
- `glacier` deve ser tratado como host principal para virtualização e gaming
- `Kryonix` é o nome público atual
- pronto em nível de build/configuração não depende de Ollama ou GraphML local no `inspiron`
- pronto em nível de runtime/infra só é validado no `glacier`

## Atenções abertas

- remover aliases internos só depois de uma janela de migração validada
- revisar docs históricas fora da trilha canônica em uma etapa separada
- `desktop/hyprland/user.nix` ainda concentra responsabilidade demais
- resíduos legados de DMS não devem receber novos acoplamentos
- validação server-side depende do `glacier` estar online

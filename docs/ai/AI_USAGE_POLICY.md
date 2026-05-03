# AI_USAGE_POLICY

## O que o agente pode fazer sozinho

- Ler indices curtos e arquivos diretamente relacionados a tarefa.
- Atualizar documentacao e contexto.
- Propor patches pequenos.
- Fazer alteracoes nao destrutivas em Nix, docs ou scripts quando a tarefa pedir.
- Rodar comandos de inspecao sem efeito colateral.
- Rodar formatacao/checks locais nao destrutivos quando fizer sentido.
- Criar issues pequenas e checklist de validacao.

## O que precisa de aprovacao humana

- Aplicar configuracao no sistema ativo.
- Rodar comandos com `sudo`.
- Alterar discos, particoes, bootloader, initrd ou hardware config.
- Alterar secrets, auth, Tailscale, SSH, GPG ou CI secrets.
- Atualizar `flake.lock` quando isso nao for o objetivo principal.
- Remover compatibilidade `kryonix`/`rag.*`.
- Alterar firewall, bridges, libvirt, Tailscale ou acesso remoto.
- Fazer deploy, sync ou switch em host real.

## O que e proibido

- Commitar secrets.
- Colocar secrets no Nix store.
- Ler vault inteiro ou repo inteiro sem necessidade.
- Executar comandos destrutivos sem pedido explicito.
- Reverter mudancas do usuario sem autorizacao.
- Misturar refactor amplo com mudanca pequena.
- Inventar estado de host, comando ou contrato sem validar no codigo real.

## Comandos permitidos por padrao

```sh
git status --short
git diff -- <arquivo>
nix flake show --all-systems
nix flake check --keep-going
nix fmt
make help
make flake-show
make flake-check
kryonix doctor
kryonix diff
```

Observacao: mesmo comandos permitidos podem ser caros. Use criterio e explique quando nao executar.

## Comandos proibidos sem aprovacao

```sh
sudo *
kryonix switch
kryonix boot
kryonix test
kryonix deploy
kryonix sync
make nixos-rebuild
make home-manager-switch
make flake-update
make nix-gc
make format-full ALLOW_DANGEROUS=1
make format-system ALLOW_DANGEROUS=1
make install-system ALLOW_DANGEROUS=1
disko
nixos-install
mkfs.*
parted
fdisk
wipefs
rm -rf
git reset --hard
git checkout -- .
```

## Checklist de validacao

- [ ] Escopo ficou pequeno?
- [ ] Codigo real foi priorizado sobre docs antigas?
- [ ] Nenhum secret foi exposto?
- [ ] `flake.lock` ficou intacto salvo necessidade?
- [ ] Comando destrutivo nao foi executado?
- [ ] Mudanca tem rollback claro se afetar sistema?
- [ ] Docs/contexto foram atualizados quando comportamento publico mudou?
- [ ] Validacao adequada foi executada ou motivo foi registrado?
- [ ] PR pode ser revisado sem contexto excessivo?

<!-- BEGIN OBSIDIAN_CLI_POLICY_REFERENCE -->

## Obsidian CLI Requirement

Any AI agent working on this project must follow:

docs/ai/OBSIDIAN_CLI_POLICY.md

Before consulting or updating the Obsidian vault, the agent must run:

kryonix vault scan

Direct vault filesystem access is forbidden unless explicitly approved by the user.

When the CLI cannot perform the required vault operation, the agent must create or update:

docs/ai/VAULT_ACCESS_REQUEST.md
docs/ai/VAULT_UPDATE_PROPOSAL.md

<!-- END OBSIDIAN_CLI_POLICY_REFERENCE -->

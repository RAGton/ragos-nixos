# Guia do Makefile

O `Makefile` do repositório foi dividido em dois grupos:

- alvos públicos e seguros para operação do dia a dia
- alvos destrutivos e específicos do `inspiron`, protegidos por opt-in explícito

## Alvos seguros

```sh
make help
make flake-show
make flake-check
make flake-update
make nixos-rebuild HOSTNAME=inspiron
make home-manager-switch HOME_TARGET=.#rocha@inspiron
make home-manager-news HOME_TARGET=.#rocha@inspiron
make nix-gc
```

### Variáveis principais

- `HOSTNAME`: host usado para montar `FLAKE`
- `USERNAME`: usuário atual para montar `HOME_TARGET`
- `FLAKE`: alvo do sistema, default `.#$(HOSTNAME)`
- `HOME_TARGET`: alvo do Home Manager, default `.#$(USERNAME)@$(HOSTNAME)`

## Alvos destrutivos

Os alvos abaixo continuam disponíveis porque ainda são úteis para recuperação e reinstalação do `inspiron`, mas não fazem parte do fluxo público normal:

```sh
make dangerous-help
make format-full ALLOW_DANGEROUS=1
make format-system ALLOW_DANGEROUS=1
make install-system ALLOW_DANGEROUS=1 INSTALL_HOST=inspiron INSTALL_USER=rocha
```

### Regras desses alvos

- exigem `ALLOW_DANGEROUS=1`
- são machine-specific
- podem apagar disco ou recriar partições
- devem ser usados só depois de revisar o layout em `hosts/inspiron/`

## Bootstrap de senha

`install-system` não embute senha pública no repositório. O `nixos-install` cuidará da senha do `root`, e depois você pode ajustar manualmente o usuário instalado:

```sh
sudo nixos-enter --root /mnt -c 'passwd rocha'
```

## Dica prática

Se o objetivo for só aplicar configuração em uma máquina já instalada, ignore completamente os alvos destrutivos e fique apenas com:

```sh
make nixos-rebuild
make home-manager-switch
```

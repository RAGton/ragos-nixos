# Obsidian CLI Safe Commands

Vault:

kryonix-vault

## Safe read commands

obsidian vault info=path vault=kryonix-vault
obsidian files ext=md vault=kryonix-vault
obsidian files folder="01-MOCs" ext=md vault=kryonix-vault
obsidian files folder="03-Projetos" ext=md vault=kryonix-vault
obsidian read path="README.md" vault=kryonix-vault
obsidian read path="03-Projetos/Kryonix.md" vault=kryonix-vault
obsidian search query="Kryonix" limit=10 vault=kryonix-vault
obsidian search:context query="NixOS" path="01-MOCs" limit=10 vault=kryonix-vault
obsidian backlinks path="03-Projetos/Kryonix.md" vault=kryonix-vault
obsidian links path="03-Projetos/Kryonix.md" vault=kryonix-vault
obsidian tags vault=kryonix-vault
obsidian properties vault=kryonix-vault

## Write commands requiring approval

obsidian create path="03-Projetos/Kryonix.md" content="..." vault=kryonix-vault
obsidian append path="03-Projetos/Kryonix.md" content="..." vault=kryonix-vault
obsidian prepend path="03-Projetos/Kryonix.md" content="..." vault=kryonix-vault
obsidian property:set path="03-Projetos/Kryonix.md" name="status" value="active" type=text vault=kryonix-vault

## Dangerous commands requiring explicit approval

obsidian delete path="..." vault=kryonix-vault
obsidian move path="..." to="..." vault=kryonix-vault
obsidian rename path="..." name="..." vault=kryonix-vault
obsidian history:restore path="..." version=1 vault=kryonix-vault
obsidian plugin:install id="..." vault=kryonix-vault
obsidian plugin:disable id="..." vault=kryonix-vault
obsidian plugin:enable id="..." vault=kryonix-vault
obsidian sync off vault=kryonix-vault
obsidian sync on vault=kryonix-vault

## Agent rule

The agent may run safe read commands without additional approval after passing:

kryonix vault scan

The agent must request approval before write or dangerous commands.

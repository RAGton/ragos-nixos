# Skill: Virtualization

## Escopo

Virtualização do Kryonix com foco em libvirt/KVM.

## Regras

- tratar `/srv/ragenterprise` como storage operacional
- evitar ações destrutivas em imagens, templates e backups
- separar hardware base do host e storage operacional do hypervisor
- não abrir escopo para outras stacks sem necessidade

## Prioridade

- segurança operacional
- clareza do layout
- mudanças reversíveis

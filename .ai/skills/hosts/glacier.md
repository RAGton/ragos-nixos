# Host Skill: Glacier

`glacier` é o host principal do Kryonix VE.

Papel:

- workstation diária
- gaming
- virtualização com libvirt/KVM

Regras:

- preservar o host instalado e seu `hardware-configuration.nix`
- tratar `/srv/ragenterprise` como storage operacional crítico
- evitar ações destrutivas de provisionamento no host atual
- priorizar validação e rollback antes de mudanças de maior risco

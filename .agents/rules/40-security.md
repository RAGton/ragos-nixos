# Security Rules

Regras de segurança obrigatórias.

- **Não commitar secrets:** Nunca inclua tokens, chaves, senhas ou credenciais no repositório.
- **Não expor tokens:** Evite imprimir ou registrar tokens em logs de build ou execução.
- **Revisar acessos:** Sempre que alterar SSH, Tailscale, firewall ou serviços systemd, valide se não houve abertura excessiva de permissões.

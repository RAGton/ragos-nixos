# Security Rules

Regras de segurança obrigatórias.

- **Não commitar secrets:** Nunca inclua tokens, chaves, senhas ou credenciais no repositório. O arquivo `.mcp.json` real fica no `.gitignore` e o `.mcp.example.json` serve como template.
- **KRYONIX_BRAIN_API_KEY Governança:**
  - A Kryonix Brain API usa exclusivamente a variável `KRYONIX_BRAIN_API_KEY` (nunca use `KRYONIX_BRAIN_KEY`).
  - No Glacier, a chave deve residir fora do repositório em `/etc/kryonix/brain.env`, com permissões estritas de `root:root 0600`.
  - O endpoint `/health` é público, enquanto `/stats`, `/search` e `/graph/*` exigem a validação do header `X-API-Key`.
  - Nunca imprima a chave em logs, readme, walkthrough, outputs ou issues. Se houver vazamento, use `kryonix brain api-key rotate` imediatamente.
- **Não expor tokens:** Evite imprimir ou registrar tokens em logs de build ou execução.
- **Revisar acessos:** Sempre que alterar SSH, Tailscale, firewall ou serviços systemd, valide se não houve abertura excessiva de permissões. Limite a exposição de portas sensíveis (como `8000`, `11434`, `2224`) à rede VPN local ou Tailscale.
- **Isolamento de privilégios de voz:** Comandos falados ou capturados por biometria de voz não podem disparar ações administrativas diretas (`sudo`) sem confirmação local explícita no sistema operacional.
- **MCP Security:** O servidor de arquivos deve operar em modo read-only e limitar o acesso apenas a diretórios autorizados (como o Vault do Obsidian).

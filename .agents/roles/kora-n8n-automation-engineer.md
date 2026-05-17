# Agente: Kora n8n Automation Engineer

## Missão
Integrar a Kora de forma segura e responsiva com workflows locais de automação no n8n e Home Assistant, permitindo que a assistente execute ações inteligentes e proativas no ambiente com verificação rígida e barreira de segurança humana.

---

## Escopo
- Integração da Kora API com o ecossistema do n8n local (`packages/kora/kora/integrations/n8n.py`).
- Implementação de Action Proposals ativas e fluxos de confirmação do operador.
- Segurança na barreira física (sem exposição pública de endpoints locais do n8n).
- Gerenciamento declarativo da suite n8n local no NixOS (`modules/nixos/services/n8n/`).
- Logs, auditoria de payloads e resiliência a timeouts de rede.

---

## Restrições Operacionais de Arquivos

### Arquivos que deve ler:
- [n8n.py](file:///etc/kryonix/packages/kora/kora/integrations/n8n.py)
- [N8N_LOCAL.md](file:///etc/kryonix/docs/kora/N8N_LOCAL.md)
- Caminhos sob [workflows/](file:///etc/kryonix/docs/kora/workflows/)
- [default.nix](file:///etc/kryonix/modules/nixos/services/n8n/default.nix)

### Arquivos que pode alterar:
- [n8n.py](file:///etc/kryonix/packages/kora/kora/integrations/n8n.py)
- [N8N_LOCAL.md](file:///etc/kryonix/docs/kora/N8N_LOCAL.md)
- Caminhos sob [workflows/](file:///etc/kryonix/docs/kora/workflows/)
- [default.nix](file:///etc/kryonix/modules/nixos/services/n8n/default.nix) (Módulo NixOS do n8n)

### Arquivos proibidos:
- Arquivos de credenciais ou senhas reais do n8n em Glacier.
- Arquivos internos de banco de dados do RAG.

---

## Riscos Identificados
- **Execução Acidental**: Ativar automações físicas ou tarefas de sistema de alta gravidade devido a um falso positivo ou erro de interpretação da Kora.
- **Portas Abertas na LAN**: Expor endpoints do n8n local ou webhooks internos para a internet pública sem isolamento de firewall/Tailscale.
- **Vazamento de Payloads**: Enviar metadados privados do usuário em requisições de rede externas.

---

## Validações Obrigatórias
Antes de declarar concluído:
1. **Status do Serviço**: Confirmar que o serviço do n8n local no NixOS está saudável e rodando em background.
   ```bash
   systemctl status n8n --no-pager
   ```
2. **Proposta de Ação**: Validar a geração correta de payloads estruturados de ação.
   ```bash
   kora ask "crie um lembrete para amanhã"
   ```
3. **Fluxo de Aprovação Humana**: Testar se comandos de risco exigem explicitamente o comando de confirmação antes de disparar o webhook do n8n.
   ```bash
   kora confirmar
   ```

---

## Definition of Done (DoD)
- Toda automação de sistema gerada pela Kora passa pela barreira: **Requires Confirmation**. Nenhuma ação física ou de alta prioridade executa de forma 100% autônoma sem o gatilho `kora confirmar`.
- Webhooks de integração utilizam autenticação interna de tokens locais fortes, isolados de acessos externos.
- Endpoints do n8n rodam localmente na porta `5678` e são expostos unicamente via LAN interna ou VPN de rede privada do Tailscale.
- A assistente lida graciosamente com indisponibilidade de rede ou timeouts dos servidores de automação locais, reportando como `WARN` de forma elegante.

# n8n Local Workflow Integration (Fase 2.7)

Este documento descreve como configurar e utilizar o n8n localmente no Glacier como motor de automação para a assistente Kora.

## Arquitetura

1. **Kora (Gateway)**: Recebe comandos, decide ações e dispara webhooks locais.
2. **n8n (Motor)**: Executa fluxos visuais, integra APIs externas e controla o Home Assistant.
3. **Comunicação**: HTTP via 127.0.0.1 (não exposto).

## Configuração de Segurança

Para que o n8n e a Kora se comuniquem com segurança, crie o arquivo de ambiente no Glacier:

```bash
# No Glacier
sudo touch /etc/kryonix/n8n.env
sudo chmod 600 /etc/kryonix/n8n.env
```

Adicione uma chave de criptografia (pode gerar com `python3 -c "import secrets; print(secrets.token_hex(32))"`):

```env
N8N_ENCRYPTION_KEY=sua_chave_secreta_aqui
```

## Acesso Visual (Interface do n8n)

Como o n8n está restrito ao localhost do Glacier, use um túnel SSH do seu Inspiron:

```bash
ssh -p 2224 -N -L 15678:127.0.0.1:5678 glacier-public
```

Acesse no navegador: `http://localhost:15678`

## Exemplo de Uso

Ao pedir para a Kora: "Kora, ligue as luzes do escritório", ela identificará a intenção e enviará um JSON para o n8n:

```json
{
  "tool": "n8n",
  "path": "webhook/kora-home-assistant",
  "payload": {
    "action": "turn_on",
    "target": "light.office"
  }
}
```

O n8n receberá esse JSON e executará a ação no Home Assistant.

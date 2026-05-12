# Status da Rede e Tailscale

Este documento descreve como validar o estado da rede e a conectividade entre os hosts Kryonix (Inspiron e Glacier).

## 🛠️ Diagnóstico Rápido

O comando principal para validar a saúde da rede é:

```bash
kryonix doctor
```

Ele verifica:
- [ ] Conectividade com a Internet.
- [ ] Status do daemon Tailscale.
- [ ] Visibilidade do host remoto (Glacier <-> Inspiron).
- [ ] Resolução de nomes DNS do Kryonix.

## 🌐 Tailscale

O Kryonix utiliza Tailscale para malha de rede segura (SD-WAN).

### Comandos Úteis

- `tailscale status`: Mostra os nós conectados e seus IPs `100.x.y.z`.
- `tailscale ping <host>`: Testa a conectividade via túnel Tailscale.
- `tailscale ip -4`: Mostra seu IP na rede Tailscale.

## ❄️ Glacier (Servidor)

O Glacier deve estar acessível via IP LAN fixo (alvo `10.0.0.2`) ou via Tailscale.

Para verificar se os serviços de IA estão expostos corretamente:

```bash
# No Inspiron
curl -fsS http://glacier:8000/health
```

## 🔒 Firewall e Portas

As seguintes portas são abertas declarativamente via NixOS:

| Porta | Serviço | Alcance |
| :--- | :--- | :--- |
| 2224 | SSH (Glacier) | LAN / Tailscale |
| 8000 | Brain API | LAN / Tailscale |
| 11434 | Ollama | Localhost (padrão) |

---
*Documento canônico gerado para auditoria de links (Issue #16).*

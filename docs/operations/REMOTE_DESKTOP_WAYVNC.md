# Acesso Remoto Gráfico via WayVNC (Glacier)

Este documento descreve a topologia e as premissas de segurança para o acesso remoto gráfico ao servidor **Glacier** através do **WayVNC**.

## Arquitetura de Segurança
Para evitar riscos associados ao protocolo VNC, o WayVNC no Glacier está explicitamente preso ao **localhost (127.0.0.1)**. O tráfego externo só chega ao WayVNC se for encapsulado (tunelado) por uma conexão SSH segura (ou Tailscale).

Topologia:
```
[ Inspiron Cliente ]                       [ Glacier Servidor ]
127.0.0.1:5901 -----> Túnel SSH/Tailscale -----> 127.0.0.1:5900
                      (kryonix-glacier-vnc-tunnel)  (kryonix-wayvnc)
```

1. **WayVNC no Glacier:** Roda através de um User Systemd Service (`kryonix-wayvnc.service`). Ocupa a porta TCP 5900 apenas para `127.0.0.1`.
2. **Túnel no Inspiron:** Roda através de um User Systemd Service (`kryonix-glacier-vnc-tunnel.service`). Redireciona a porta local TCP 5901 para a porta remota do Glacier, utilizando `glacier-publico` como alvo.

## Como Usar (CLI)

O Kryonix CLI abstrai o gerenciamento dos túneis na máquina do cliente (Inspiron).

- **Checar o status da conexão VNC:**
  Verifica se o túnel local está rodando e tenta validar se o serviço do Glacier está ativo (via SSH).
  ```bash
  kryonix remote vnc status
  ```

- **Iniciar o túnel:**
  ```bash
  kryonix remote vnc start
  # ou kryonix remote vnc tunnel
  ```

- **Parar o túnel:**
  ```bash
  kryonix remote vnc stop
  ```

Após iniciar o túnel (quando o status informar que a "Conexão VNC está pronta"), basta abrir o cliente VNC no Inspiron apontando para a porta roteada **5901**:

```bash
vncviewer 127.0.0.1:5901
```

## Validação e Solução de Problemas

Se não conseguir se conectar, efetue as validações abaixo:

### 1. Verificar o Glacier (Servidor)
Confirme se o WayVNC está rodando e qual IP/Porta ele está ouvindo:
```bash
systemctl --user status kryonix-wayvnc --no-pager -l
ss -ltnp | grep "5900"
```
> **NOTA:** A saída do comando `ss` **nunca** deve listar `0.0.0.0:5900` ou `[::]:5900`. Se estiver listado, o VNC está exposto indevidamente. O correto é aparecer `127.0.0.1:5900`.

### 2. Verificar o Inspiron (Cliente)
Confirme se o túnel está ligado corretamente e segurando a porta `5901`:
```bash
systemctl --user status kryonix-glacier-vnc-tunnel --no-pager -l
ss -ltnp | grep "5901"
```

Erros frequentes:
- `bind: Address already in use`: Algo (talvez outro túnel) já está utilizando a porta `5901` no Inspiron.
- `Connection refused` no `vncviewer`: O túnel está de pé, mas o Glacier não está respondendo na porta `5900` (WayVNC caiu, sessão falhou ou SSH sem permissões locais).
- Falhas de DNS ou falha ao resolver `glacier-publico`: Verifique sua chave SSH ou a presença de `glacier-publico` no `/etc/hosts` / `~/.ssh/config`.

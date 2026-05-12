# Remote Desktop (VNC) no Kryonix

O Kryonix utiliza o **wayvnc** para prover acesso remoto declarativo em sessões Wayland/Hyprland.

## Arquitetura

- **Servidor:** `wayvnc` rodando como serviço systemd de usuário.
- **Cliente:** `tigervnc` + wrapper `kryonix-remote-desktop`.
- **Porta:** 5905 (TCP).
- **Segurança:** Atualmente configurado para bind em `0.0.0.0` e aberto no firewall, conforme solicitado para acesso público via roteador.

## Como usar

### No Servidor (Host que será acessado)

Habilite a feature no seu arquivo de host:

```nix
kryonix.features.remoteDesktop.server.enable = true;
```

Após o rebuild e login na sessão gráfica, o serviço `wayvnc` iniciará automaticamente. Você pode verificar o status com:

```bash
systemctl --user status wayvnc
```

### No Cliente (Host que vai acessar)

Habilite a feature de cliente:

```nix
kryonix.features.remoteDesktop.client.enable = true;
```

Use o wrapper para conectar:

```bash
kryonix-remote-desktop glacier
```

Ou conecte via IP:

```bash
kryonix-remote-desktop 10.0.0.2
```

## Acesso Headless

Se você precisar iniciar uma sessão VNC sem um monitor físico conectado, você pode criar um output virtual no Hyprland:

```bash
hyprctl output create headless
```

O `wayvnc` irá capturar automaticamente o output disponível. Se houver múltiplos, ele pode precisar de configuração extra via `--output` no arquivo de serviço (futura implementação se necessário).

## Segurança (Importante!)

> [!WARNING]
> O VNC por padrão não é criptografado. Ao abrir a porta 5905 no seu roteador, o tráfego estará exposto.
> Recomendamos fortemente o uso de **Tailscale** ou **SSH Tunnel** para acesso externo sempre que possível.

Para usar via SSH Tunnel (mesmo com a porta pública aberta):
```bash
ssh -L 5905:localhost:5905 -p 2224 rocha@glacier
# Depois conecte localmente:
vncviewer localhost::5905
```

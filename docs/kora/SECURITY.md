# Kora Security Policy

## API Authentication

Kora uses a shared secret for API authentication. This secret is stored in `/etc/kryonix/kora.env` on the server and must be provided in the `X-API-Key` header for all requests.

### Key Rotation

If the `KORA_API_KEY` is exposed in logs, terminals, or shared chats, it must be rotated immediately.

#### Rotation Procedure (Secure)

Run the following command on the Glacier host:

```bash
# Gera nova chave sem imprimir no terminal
NEW_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
tmp=$(mktemp)
printf "KORA_API_KEY=%s\n" "$NEW_KEY" > "$tmp"
# Preserva outras variáveis, se houver
sudo awk "!/^KORA_API_KEY=/" /etc/kryonix/kora.env >> "$tmp" 2>/dev/null
sudo install -m 600 -o root -g root "$tmp" /etc/kryonix/kora.env
rm -f "$tmp"
unset NEW_KEY
sudo systemctl restart kora.service
```

After rotation, all clients must run `kora login` again.

## Network Access

Kora is configured to listen on all interfaces (`0.0.0.0`) to allow access via Tailscale and LAN.

### Firewall Hardening

Access is restricted at the firewall level. The port `8787` is ONLY opened for the following interfaces:
- `tailscale0` (Tailscale VPN)
- `br0` (Local Bridge/LAN)

It remains **closed** for all other interfaces (e.g., `eth0`, `wlan0`).

## Client Security

The Kora CLI stores the API key in `~/.config/kryonix/kora.env` with `0600` permissions.

- Never share this file.
- `kora login` uses SSH to fetch the key and never prints the full secret to the terminal.

# Kora — User Management

A Kora possui um registro estruturado de usuários para gerenciar permissões e identidade.

## Estado Atual

- **User Registry**: Validado e funcional. Reconhece Ragton e Nicoly baseando-se no usuário Linux da sessão.
- **Sincronização**: Perfis são persistidos em JSON e documentados no Obsidian Vault.

## Storage Locations

- **System JSON**: `/var/lib/kryonix/kora/users/<user_id>.json`
- **Obsidian Vault**: `/var/lib/kryonix/vault/Kora/User/<DisplayName>.md`

## Permission Levels

| Level | Role | Capabilities |
|-------|------|--------------|
| `admin_owner` | `owner` | Full access, memory access, system commands |
| `trusted_user`| `trusted_partner` | Conversation, personal greeting, limited tools |
| `guest` | `visitor` | General conversation only |

## CLI Commands

### Initialize Defaults
```bash
kora user init
```

### Add User
```bash
kora user add --id <id> --display-name "<Name>" --role <role>
```

### List Users
```bash
kora user list
```

### Show User
```bash
kora user show <id>
```

### Remove User
```bash
kora user remove <id>
```

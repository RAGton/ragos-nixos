# =============================================================================
# Kora — User Registry
# =============================================================================

import os
import json
import logging
from dataclasses import dataclass, asdict
from datetime import datetime
from typing import List, Optional

logger = logging.getLogger("kora.core.users")

USER_STORAGE_DIR = "/var/lib/kryonix/kora/users"

@dataclass
class KoraUser:
    id: str
    display_name: str
    full_name: Optional[str] = None
    linux_user: Optional[str] = None
    github_user: Optional[str] = None
    role: str = "guest"
    permission_level: str = "guest"
    can_access_private_memory: bool = False
    can_request_commands: bool = False
    can_request_admin_actions: bool = False
    created_at: str = ""
    updated_at: str = ""

    def to_dict(self):
        return asdict(self)

    @classmethod
    def from_dict(cls, data):
        return cls(**data)

class UserRegistry:
    def __init__(self, storage_dir: str = USER_STORAGE_DIR):
        self.storage_dir = storage_dir
        if not os.path.exists(self.storage_dir):
            try:
                os.makedirs(self.storage_dir, mode=0o700, exist_ok=True)
            except PermissionError:
                logger.warning(f"No permission to create {self.storage_dir}. Using /tmp for now.")
                self.storage_dir = "/tmp/kora/users"
                os.makedirs(self.storage_dir, mode=0o700, exist_ok=True)

    def _get_path(self, user_id: str) -> str:
        return os.path.join(self.storage_dir, f"{user_id}.json")

    def save_user(self, user: KoraUser):
        now = datetime.now().isoformat()
        if not user.created_at:
            user.created_at = now
        user.updated_at = now

        path = self._get_path(user.id)
        with open(path, "w") as f:
            json.dump(user.to_dict(), f, indent=2, ensure_ascii=False)
        os.chmod(path, 0o600)
        logger.info(f"User {user.id} saved to {path}")

    def get_user(self, user_id: str) -> Optional[KoraUser]:
        path = self._get_path(user_id)
        if not os.path.exists(path):
            return None
        with open(path, "r") as f:
            data = json.load(f)
            return KoraUser.from_dict(data)

    def list_users(self) -> List[KoraUser]:
        users = []
        for filename in os.listdir(self.storage_dir):
            if filename.endswith(".json"):
                user_id = filename[:-5]
                user = self.get_user(user_id)
                if user:
                    users.append(user)
        return users

    def delete_user(self, user_id: str):
        path = self._get_path(user_id)
        if os.path.exists(path):
            os.remove(path)
            logger.info(f"User {user_id} deleted.")

    def find_by_linux_user(self, linux_user: str) -> Optional[KoraUser]:
        for user in self.list_users():
            if user.linux_user == linux_user:
                return user
        return None

    def sync_to_vault(self, user: KoraUser, vault_dir: str = "/var/lib/kryonix/vault/Kora/User"):
        if not os.path.exists(vault_dir):
            try:
                os.makedirs(vault_dir, mode=0o700, exist_ok=True)
            except PermissionError:
                logger.warning(f"No permission to create vault dir {vault_dir}")
                return

        path = os.path.join(vault_dir, f"{user.display_name}.md")

        content = f"""---
type: user_profile
user_id: {user.id}
display_name: {user.display_name}
full_name: {user.full_name or "null"}
linux_user: {user.linux_user or "null"}
github_user: {user.github_user or "null"}
permission_level: {user.permission_level}
status: active
---

# {user.display_name}

{user.display_name} é {user.full_name or user.display_name}, usuário do Kryonix.

## Permissões

- Pode acessar memória privada: {'Sim' if user.can_access_private_memory else 'Não'}
- Pode solicitar comandos do sistema: {'Sim' if user.can_request_commands else 'Não'}
- Ações administrativas: {'Permitidas' if user.can_request_admin_actions else 'Bloqueadas'}
- Nível de permissão: {user.permission_level}
"""
        with open(path, "w") as f:
            f.write(content)
        logger.info(f"User {user.id} profile synced to Vault at {path}")

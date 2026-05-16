"""
n8n.py — Adapter para acionar workflows locais do n8n via Webhook.
Garante que a Kora funcione como o gateway principal, disparando automações
visuais no Glacier sem expor portas publicamente.
"""
import httpx
import logging
import os
from typing import Any

logger = logging.getLogger("kora.integrations.n8n")

N8N_BASE_URL = os.environ.get("KORA_N8N_BASE_URL", "http://127.0.0.1:5678")
N8N_WEBHOOK_TOKEN = os.environ.get("KORA_N8N_WEBHOOK_TOKEN", "")

class N8nClient:
    """Client for triggering n8n local webhooks securely."""

    def __init__(self, base_url: str = N8N_BASE_URL, token: str = N8N_WEBHOOK_TOKEN):
        self.base_url = base_url.rstrip("/")
        self.token = token

    async def trigger_webhook(self, path: str, payload: dict[str, Any]) -> dict[str, Any]:
        """
        Aciona um webhook no n8n.
        Ex: path = 'webhook/kora-task'
        """
        # Sempre garantir formato de webhook
        if not path.startswith("webhook/"):
            path = f"webhook/{path.lstrip('/')}"

        url = f"{self.base_url}/{path}"

        headers = {}
        if self.token:
            headers["X-Kora-Token"] = self.token

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(url, json=payload, headers=headers)
                response.raise_for_status()

                try:
                    return response.json()
                except ValueError:
                    return {"status": "success", "raw_text": response.text}

        except httpx.HTTPStatusError as e:
            logger.error(f"n8n webhook error {e.response.status_code}: {e.response.text}")
            return {
                "status": "error",
                "error": f"O n8n retornou erro HTTP {e.response.status_code}",
                "details": e.response.text
            }
        except httpx.RequestError as e:
            logger.error(f"Failed to connect to n8n at {url}: {e}")
            return {
                "status": "error",
                "error": "Não foi possível conectar ao n8n local. Verifique se o serviço está ativo.",
                "details": str(e)
            }

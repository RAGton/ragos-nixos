"""
ha.py — Home Assistant Integration Stub.
Provides a thread-safe bridge to update device states or invoke services.
"""
import os
import httpx
import logging
from typing import Any

logger = logging.getLogger("kora.integrations.ha")

HA_BASE_URL = os.environ.get("KORA_HA_BASE_URL", "http://127.0.0.1:8123")
HA_TOKEN = os.environ.get("KORA_HA_TOKEN", "")

async def call_ha(entity_id: str, state: str) -> dict[str, Any]:
    """
    Atualiza o estado de uma entidade no Home Assistant.
    """
    logger.info(f"Home Assistant call: setting {entity_id} to {state}")
    
    url = f"{HA_BASE_URL}/api/states/{entity_id}"
    headers = {
        "Content-Type": "application/json",
    }
    if HA_TOKEN:
        headers["Authorization"] = f"Bearer {HA_TOKEN}"
        
    payload = {"state": state}
    
    if not HA_TOKEN:
        logger.warning("KORA_HA_TOKEN não configurada. Simulando chamada HA...")
        return {
            "status": "stub_success",
            "message": "Simulated state update (HA token not set)",
            "entity_id": entity_id,
            "state": state
        }
        
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, json=payload, headers=headers)
            response.raise_for_status()
            return response.json()
    except httpx.HTTPStatusError as e:
        logger.error(f"Home Assistant HTTP error {e.response.status_code}: {e.response.text}")
        return {
            "status": "error",
            "error": f"Home Assistant retornou erro HTTP {e.response.status_code}",
            "details": e.response.text
        }
    except Exception as e:
        logger.error(f"Home Assistant connection failed: {e}")
        return {
            "status": "error",
            "error": "Falha na conexão com o Home Assistant",
            "details": str(e)
        }

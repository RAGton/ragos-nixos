# =============================================================================
# Kora — HTTP Client
#
# Cliente HTTP para a Kora API.
# Usado pela CLI e integrações externas.
#
# Configuração via env:
#   KORA_API_URL  → URL da API (default: http://127.0.0.1:8787)
#   KORA_API_KEY  → chave de autenticação
#
# Nunca logar ou imprimir a API key.
# =============================================================================

from __future__ import annotations

import os
import sys
from typing import Any

import httpx


# ── Defaults ─────────────────────────────────────────────────────

DEFAULT_URL = "http://127.0.0.1:8787"
DEFAULT_TIMEOUT = 120


# ── URL & Auth resolution ────────────────────────────────────────

def resolve_url(override: str | None = None) -> str:
    """Resolve API URL: CLI flag > env > default."""
    if override:
        return override.rstrip("/")
    return os.getenv("KORA_API_URL", DEFAULT_URL).rstrip("/")


def resolve_api_key() -> str:
    """Resolve API key from environment.

    Priority:
    1. KORA_API_KEY env var
    2. Read from /etc/kryonix/kora.env if readable (Glacier local)
    """
    key = os.getenv("KORA_API_KEY", "")
    if key:
        return key

    # Try reading from env file on Glacier (if running as root or kryonix)
    env_file = "/etc/kryonix/kora.env"
    try:
        if os.path.isfile(env_file) and os.access(env_file, os.R_OK):
            with open(env_file) as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("KORA_API_KEY=") and not line.startswith("#"):
                        return line.split("=", 1)[1]
    except OSError:
        pass

    return ""


def _headers(api_key: str = "") -> dict[str, str]:
    """Build request headers with API key."""
    h: dict[str, str] = {
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    key = api_key or resolve_api_key()
    if key:
        h["X-API-Key"] = key
    return h


# ── Error types ──────────────────────────────────────────────────

class KoraClientError(Exception):
    """Base error for Kora client."""
    pass


class KoraOfflineError(KoraClientError):
    """API is not reachable."""
    pass


class KoraAuthError(KoraClientError):
    """Authentication failed (401/403)."""
    pass


class KoraTimeoutError(KoraClientError):
    """Request timed out."""
    pass


# ── Client class ─────────────────────────────────────────────────

class KoraClient:
    """Synchronous HTTP client for the Kora API."""

    def __init__(
        self,
        url: str | None = None,
        api_key: str | None = None,
        timeout: int = DEFAULT_TIMEOUT,
    ):
        self.url = resolve_url(url)
        self.api_key = api_key or resolve_api_key()
        self.timeout = timeout

    def _request(
        self,
        method: str,
        path: str,
        json_data: dict | None = None,
    ) -> dict[str, Any]:
        """Make an HTTP request with error handling."""
        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.request(
                    method=method,
                    url=f"{self.url}{path}",
                    headers=_headers(self.api_key),
                    json=json_data,
                )
        except httpx.ConnectError:
            raise KoraOfflineError(
                f"Kora API offline em {self.url}. "
                "Verifique se kora.service está ativo ou configure KORA_API_URL."
            )
        except httpx.TimeoutException:
            raise KoraTimeoutError(
                f"Timeout ({self.timeout}s) ao conectar com {self.url}."
            )
        except httpx.HTTPError as e:
            raise KoraClientError(f"Erro HTTP: {e}")

        if resp.status_code in (401, 403):
            msg = "API key ausente." if not self.api_key else "API key inválida."
            raise KoraAuthError(
                f"Autenticação falhou ({resp.status_code}): {msg} "
                "Configure KORA_API_KEY."
            )

        if resp.status_code >= 400:
            try:
                detail = resp.json().get("detail", resp.text)
            except Exception:
                detail = resp.text
            raise KoraClientError(
                f"Erro {resp.status_code}: {detail}"
            )

        try:
            return resp.json()
        except Exception:
            raise KoraClientError(
                f"Resposta não-JSON do servidor: {resp.text[:200]}"
            )

    # ── Public API ───────────────────────────────────────────────

    def health(self) -> dict[str, Any]:
        """GET /health — public, no auth required."""
        return self._request("GET", "/health")

    def status(self) -> dict[str, Any]:
        """GET /status — public, no auth required."""
        return self._request("GET", "/status")

    def capabilities(self) -> dict[str, Any]:
        """GET /capabilities — public, no auth required."""
        return self._request("GET", "/capabilities")

    def chat(
        self,
        message: str,
        mode: str = "auto",
        session_id: str = "cli",
    ) -> dict[str, Any]:
        """POST /chat — requires auth."""
        return self._request("POST", "/chat", {
            "message": message,
            "mode": mode,
            "session_id": session_id,
        })

    def ask(self, question: str) -> dict[str, Any]:
        """POST /ask — requires auth."""
        return self._request("POST", "/ask", {
            "question": question,
        })

    def memory_search(
        self,
        query: str,
        mode: str = "hybrid",
    ) -> dict[str, Any]:
        """POST /memory/search — requires auth."""
        return self._request("POST", "/memory/search", {
            "query": query,
            "mode": mode,
        })

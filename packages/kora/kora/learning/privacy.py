from __future__ import annotations

import re

SECRET_PATTERNS = [
    re.compile(pattern, re.IGNORECASE)
    for pattern in [
        r"api[_-]?key\s*[:=]\s*\S+",
        r"token\s*[:=]\s*\S+",
        r"secret\s*[:=]\s*\S+",
        r"password\s*[:=]\s*\S+",
        r"passwd\s*[:=]\s*\S+",
        r"bearer\s+[a-z0-9._\-]+",
        r"authorization\s*[:=]\s*\S+",
        r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
        r"KRYONIX_BRAIN_API_KEY\s*=\s*\S+",
        r"NEO4J_AUTH\s*=\s*\S+",
    ]
]


def sanitize_text(text: str) -> str:
    clean = text or ""
    for pattern in SECRET_PATTERNS:
        clean = pattern.sub("[REDACTED_SECRET]", clean)
    return clean


def contains_secret(text: str) -> bool:
    return any(pattern.search(text or "") for pattern in SECRET_PATTERNS)

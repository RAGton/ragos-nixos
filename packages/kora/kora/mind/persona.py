"""
kora.mind.persona — Persona constants and PersonaModulator.

Existing constants (KORA_PERSONA, GOOD_CASUAL_CHECK_RESPONSE, BAD_CASUAL_CHECK_TERMS)
are preserved for backward compatibility with mind.py and reflection.py.

PersonaModulator selects a communication-style persona (Engineer / Architect)
based on keyword scoring of the query, plan, and critique context. The selected
persona's style_directive is injected into the MindConstructor synthesis prompt
as a System Override block so the LLM adapts its voice without losing technical
accuracy.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import yaml as _yaml
except ImportError:
    _yaml = None  # type: ignore

logger = logging.getLogger("kora.mind.persona")

_MANIFEST_PATH = Path(__file__).parent / "assets" / "persona_manifest.yaml"

# ── Existing constants (used by mind.py and reflection.py) ───────────────────

KORA_PERSONA = """Kora e a assistente pessoal local do Ragton/Gabriel.

Ela e:
- tecnica;
- natural;
- direta;
- calma;
- levemente sofisticada;
- util;
- local-first;
- integrada ao Kryonix.

Ela nao e:
- chatbot generico;
- Alexa generica;
- programa que despeja status interno;
- assistente servil;
- entidade consciente humana.

Ela deve responder primeiro ao humano, depois ao sistema.
"""

GOOD_CASUAL_CHECK_RESPONSE = (
    "Sim, Ragton. Estou te ouvindo.\n\n"
    "Pode falar comigo naturalmente. Quando você parar por um instante, "
    "eu processo e respondo."
)

BAD_CASUAL_CHECK_TERMS = [
    "STT",
    "TTS",
    "openWakeWord",
    "modo de voz",
    "diagnostico tecnico",
]

# ── PersonaModulator ──────────────────────────────────────────────────────────


@dataclass
class PersonaContext:
    """Context passed to PersonaModulator.get_persona()."""
    query: str
    plan: dict[str, Any]
    critique: dict[str, Any]


class PersonaModulator:
    """
    Selects a synthesis persona based on task context.

    Loads persona definitions from persona_manifest.yaml and scores the context
    against each persona's keyword signals. Defaults to 'engineer' when signals
    are ambiguous (zero score on all personas) or the manifest is unavailable.
    """

    def __init__(self, manifest_path: Path | None = None) -> None:
        self._path = manifest_path or _MANIFEST_PATH
        self._manifest: dict[str, Any] = self._load_manifest()

    # ── Public API ───────────────────────────────────────────────────────────

    def get_persona(self, context: PersonaContext) -> dict[str, Any]:
        """
        Return the persona dict (including style_directive) for the given context.
        Always returns a non-empty dict — falls back to the default persona.
        """
        personas: dict[str, Any] = self._manifest.get("personas", {})
        default_key: str = self._manifest.get("default_persona", "engineer")

        if not personas:
            logger.warning("Persona manifest has no personas — using empty fallback")
            return {}

        scores: dict[str, int] = {
            name: self._score(context, p.get("signals", {}))
            for name, p in personas.items()
        }

        # All-zero scores → use default (no signal in query)
        if all(v == 0 for v in scores.values()):
            chosen = default_key
        else:
            # Highest score wins; ties broken in favour of default_persona
            chosen = max(
                scores,
                key=lambda k: (scores[k], 1 if k == default_key else 0),
            )

        result = personas.get(chosen) or personas.get(default_key) or {}
        logger.debug("PersonaModulator selected: %s (scores=%s)", chosen, scores)
        return result

    # ── Internals ────────────────────────────────────────────────────────────

    def _score(self, context: PersonaContext, signals: dict[str, Any]) -> int:
        """Count how many signal keywords appear in the flattened context text."""
        text = self._flatten(context).lower()
        return sum(1 for kw in signals.get("keywords", []) if kw.lower() in text)

    @staticmethod
    def _flatten(context: PersonaContext) -> str:
        """Join query, plan sections/key_points, and critique into one string."""
        parts: list[str] = [context.query]
        plan = context.plan or {}
        parts.extend(plan.get("sections", []))
        parts.extend(plan.get("key_points", []))
        parts.append(str(plan.get("tone", "")))
        critique = context.critique or {}
        parts.extend(critique.get("missing_points", []))
        parts.append(str(critique.get("adjustments", "")))
        return " ".join(str(p) for p in parts)

    def _load_manifest(self) -> dict[str, Any]:
        if _yaml is None:
            logger.warning("PyYAML not installed — using built-in persona fallback")
            return _builtin_manifest()
        try:
            return _yaml.safe_load(self._path.read_text(encoding="utf-8")) or {}
        except Exception as exc:
            logger.warning("Failed to load persona manifest %s: %s — using fallback", self._path, exc)
            return _builtin_manifest()


# ── Built-in fallback (used when YAML is unavailable) ────────────────────────

def _builtin_manifest() -> dict[str, Any]:
    return {
        "version": "1.0-fallback",
        "default_persona": "engineer",
        "personas": {
            "engineer": {
                "name": "Engineer",
                "style_directive": (
                    "## Style Override — Engineer Mode\n"
                    "Be direct and concise. No preambles or pleasantries.\n"
                    "Lead with the solution or command — explain after if needed.\n"
                    "Prefer code blocks and log excerpts over prose.\n"
                    "Use imperative voice. Maximum 3 sentences per point."
                ),
                "signals": {
                    "keywords": [
                        "error", "fail", "debug", "log", "exception", "crash",
                        "fix", "broken", "systemctl", "journalctl", "traceback",
                        "config", "deploy", "restart", "rebuild",
                        "falhou", "erro", "problema", "diagnostico",
                    ],
                },
            },
            "architect": {
                "name": "Architect",
                "style_directive": (
                    "## Style Override — Architect Mode\n"
                    "Think in systems: consider interactions, dependencies, and failure modes.\n"
                    "Present trade-offs explicitly before recommending a path forward.\n"
                    "Use structured sections (Overview, Options, Recommendation).\n"
                    "Suggest rather than prescribe where appropriate."
                ),
                "signals": {
                    "keywords": [
                        "design", "architecture", "arquitetura", "strategy", "integrate",
                        "approach", "structure", "trade-off", "tradeoff", "pattern",
                        "scalability", "migration", "refactor", "roadmap", "decision",
                        "modular", "pipeline", "estrategia", "integracao",
                    ],
                },
            },
        },
    }

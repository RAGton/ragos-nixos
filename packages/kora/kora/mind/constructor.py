"""
MindConstructor — Chain-of-Thought reflective reasoning for Kora.

Three-step pipeline: Plan → Critique → Synthesize.

Each step calls the LLM independently so failures are isolated.
The full chain-of-thought is persisted to KORA_DATA_DIR/thoughts/
before returning the final answer, providing complete auditability.

On any failure the caller receives an exception; the orchestrator
is responsible for falling back to KoraMind (direct LLM, no RAG).
"""
from __future__ import annotations

import asyncio
import json
import logging
import re
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any


@dataclass
class MindResult:
    """Return type of MindConstructor.execute()."""
    answer: str
    confidence: float = 1.0
    critique_approved: bool = True
    missing_points: list[str] = field(default_factory=list)
    persona: str = ""

    @property
    def is_low_confidence(self) -> bool:
        return self.confidence < 0.65

from ..core.config import KORA_DATA_DIR
from ..llm.ollama import chat
from .persona import PersonaContext, PersonaModulator

# Lazy singleton — loaded once per process, patchable in tests.
_PERSONA_MODULATOR: PersonaModulator | None = None


def _get_persona_modulator() -> PersonaModulator:
    global _PERSONA_MODULATOR
    if _PERSONA_MODULATOR is None:
        _PERSONA_MODULATOR = PersonaModulator()
    return _PERSONA_MODULATOR

logger = logging.getLogger("kora.mind.constructor")

_THOUGHTS_DIR = KORA_DATA_DIR / "thoughts"

# ── Step prompts ─────────────────────────────────────────────────────────────

_PLAN_SYSTEM = (
    "Você é o planejador estratégico da Kora. "
    "Analise o contexto do grafo de conhecimento (GraphRAG) e a query do usuário, "
    "depois produza um plano estruturado de resposta. "
    "Responda APENAS com JSON válido, sem nenhum texto adicional. "
    "Formato esperado:\n"
    '{"sections": ["tópico 1", "tópico 2"], '
    '"key_points": ["ponto essencial 1"], '
    '"tone": "técnico", '
    '"confidence": 0.85}'
)

_CRITIQUE_SYSTEM = (
    "Você é o crítico de qualidade da Kora. "
    "Avalie se o plano de resposta cobre completamente a query do usuário. "
    "Identifique lacunas ou imprecisões. "
    "Responda APENAS com JSON válido, sem nenhum texto adicional. "
    "Formato esperado:\n"
    '{"covers_query": true, '
    '"missing_points": [], '
    '"approved": true, '
    '"adjustments": ""}'
)

_SYNTHESIZE_FALLBACK_SYSTEM = (
    "Você é a Kora, assistente pessoal local do ecossistema Kryonix. "
    "Responda de forma técnica, direta e útil em português do Brasil."
)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _parse_json_safe(text: str, fallback: dict[str, Any]) -> dict[str, Any]:
    """Extract JSON from LLM output, handling markdown code blocks."""
    # Strip ```json ... ``` wrappers
    m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if m:
        text = m.group(1)

    try:
        return json.loads(text.strip())
    except (json.JSONDecodeError, ValueError):
        pass

    # Try to find the first {...} object in free text
    m = re.search(r"\{[^{}]*\}", text, re.DOTALL)
    if m:
        try:
            return json.loads(m.group())
        except (json.JSONDecodeError, ValueError):
            pass

    return fallback


async def _save_thought(record: dict[str, Any]) -> None:
    """Persist chain-of-thought record to disk. Best-effort — never raises."""
    try:
        _THOUGHTS_DIR.mkdir(parents=True, exist_ok=True)
        ts = datetime.now(timezone.utc)
        record["timestamp"] = ts.isoformat()
        filename = ts.strftime("%Y%m%dT%H%M%S%f") + ".json"
        path = _THOUGHTS_DIR / filename
        content = json.dumps(record, ensure_ascii=False, indent=2)
        await asyncio.to_thread(path.write_text, content, encoding="utf-8")
        logger.debug("Thought saved: %s", path.name)
    except Exception as exc:
        logger.warning("Failed to save thought record: %s", exc)


async def _llm_step(
    system: str,
    user: str,
    temperature: float = 0.3,
    step_name: str = "step",
) -> str:
    """Execute one LLM call. Raises RuntimeError on provider error."""
    result = await chat(
        messages=[
            {"role": "system", "content": system},
            {"role": "user",   "content": user},
        ],
        temperature=temperature,
    )
    if result.get("error"):
        raise RuntimeError(f"LLM error on {step_name}: {result['error']}")
    answer = result.get("answer", "").strip()
    if not answer:
        raise RuntimeError(f"LLM returned empty answer on {step_name}")
    return answer


# ── MindConstructor ───────────────────────────────────────────────────────────

class MindConstructor:
    """
    Reflective reasoning over Neo4j graph context.

    Usage:
        constructor = MindConstructor(session_id=session_id)
        answer = await constructor.execute(query, graph_context, system_prompt=...)

    Raises RuntimeError (or asyncio.TimeoutError) on any failure.
    The orchestrator is expected to catch and fall back to KoraMind.
    """

    def __init__(self, session_id: str = "default") -> None:
        self.session_id = session_id

    async def execute(
        self,
        query: str,
        graph_context: str,
        *,
        system_prompt: str = "",
        timeout: float = 90.0,
    ) -> MindResult:
        """
        Run the Plan → Critique → Synthesize chain.

        Parameters
        ----------
        query:
            Normalised user message.
        graph_context:
            Raw JSON of Neo4j nodes from Neo4jGraphProvider.format_for_prompt().
        system_prompt:
            Full Kora system prompt (identity, style, operational context).
        timeout:
            Maximum wall-clock seconds for the entire chain.

        Returns
        -------
        MindResult with answer, confidence, critique flags, and missing_points.
        """
        try:
            return await asyncio.wait_for(
                self._chain(query, graph_context, system_prompt),
                timeout=timeout,
            )
        except asyncio.TimeoutError:
            raise RuntimeError(
                f"MindConstructor chain exceeded {timeout}s timeout"
            )

    # ── Internal chain ───────────────────────────────────────────────────────

    async def _chain(
        self,
        query: str,
        graph_context: str,
        system_prompt: str,
    ) -> str:
        t0 = time.monotonic()

        plan_text, plan_data = await self._plan(query, graph_context)
        logger.debug(
            "MindConstructor Plan | session=%s confidence=%s",
            self.session_id,
            plan_data.get("confidence", "?"),
        )

        critique_text, critique_data = await self._critique(query, plan_text)
        logger.debug(
            "MindConstructor Critique | session=%s approved=%s missing=%s",
            self.session_id,
            critique_data.get("approved"),
            critique_data.get("missing_points"),
        )

        # ── Persona selection: inject style directive into synthesis prompt ──
        modulator = _get_persona_modulator()
        persona = modulator.get_persona(PersonaContext(
            query=query,
            plan=plan_data,
            critique=critique_data,
        ))
        persona_name = persona.get("name", "engineer")
        style_directive = persona.get("style_directive", "")
        synth_prompt = system_prompt or _SYNTHESIZE_FALLBACK_SYSTEM
        if style_directive:
            synth_prompt = synth_prompt + "\n\n" + style_directive
        logger.debug(
            "MindConstructor Persona | session=%s persona=%s",
            self.session_id,
            persona_name,
        )

        final_answer = await self._synthesize(
            query, graph_context, plan_text, critique_text, synth_prompt
        )

        if len(final_answer.strip()) < 10:
            raise RuntimeError("Synthesis returned a trivially short answer")

        elapsed_ms = int((time.monotonic() - t0) * 1000)
        await _save_thought({
            "session_id": self.session_id,
            "query":      query[:500],
            "plan":       plan_data,
            "critique":   critique_data,
            "synthesis_elapsed_ms": elapsed_ms,
        })

        logger.info(
            "MindConstructor chain done | session=%s elapsed_ms=%d",
            self.session_id,
            elapsed_ms,
        )
        return MindResult(
            answer=final_answer,
            confidence=float(plan_data.get("confidence", 1.0)),
            critique_approved=bool(critique_data.get("approved", True)),
            missing_points=list(critique_data.get("missing_points", [])),
            persona=persona_name,
        )

    async def _plan(
        self, query: str, graph_context: str
    ) -> tuple[str, dict[str, Any]]:
        user_msg = (
            f"Contexto do Grafo (GraphRAG — Neo4j):\n{graph_context}\n\n"
            f"Query do usuário: {query}\n\n"
            "Produza o plano de resposta em JSON."
        )
        text = await _llm_step(_PLAN_SYSTEM, user_msg, temperature=0.3, step_name="plan")
        data = _parse_json_safe(
            text,
            fallback={"sections": [], "key_points": [], "tone": "técnico", "confidence": 0.5},
        )
        return text, data

    async def _critique(
        self, query: str, plan_text: str
    ) -> tuple[str, dict[str, Any]]:
        user_msg = (
            f"Query do usuário: {query}\n\n"
            f"Plano proposto:\n{plan_text}\n\n"
            "Avalie o plano e retorne JSON de crítica."
        )
        text = await _llm_step(
            _CRITIQUE_SYSTEM, user_msg, temperature=0.2, step_name="critique"
        )
        data = _parse_json_safe(
            text,
            fallback={"covers_query": True, "missing_points": [], "approved": True, "adjustments": ""},
        )
        return text, data

    async def _synthesize(
        self,
        query: str,
        graph_context: str,
        plan_text: str,
        critique_text: str,
        system_prompt: str,
    ) -> str:
        user_msg = (
            f"Query do usuário: {query}\n\n"
            f"Contexto do Grafo (GraphRAG):\n{graph_context}\n\n"
            f"Plano aprovado:\n{plan_text}\n\n"
            f"Crítica aplicada:\n{critique_text}\n\n"
            "Gere a resposta final em português. Seja direto e técnico."
        )
        return await _llm_step(
            system_prompt or _SYNTHESIZE_FALLBACK_SYSTEM,
            user_msg,
            temperature=0.45,
            step_name="synthesize",
        )

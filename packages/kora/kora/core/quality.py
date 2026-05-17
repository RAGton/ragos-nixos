import logging
from dataclasses import dataclass
from typing import List

from .answer_planner import AnswerPlan

logger = logging.getLogger("kora.core.quality")

@dataclass
class QualityResult:
    passed: bool
    reason: str
    repaired_answer: str

class QualityGuard:
    """Evaluates the LLM's answer against the AnswerPlan and global constraints."""

    def __init__(self):
        self.generic_phrases = [
            "como posso ajudar",
            "em que posso ajudar",
            "sou um assistente",
            "não tenho certeza",
        ]

    def check_answer(self, user_text: str, answer: str, plan: AnswerPlan, context: dict) -> QualityResult:
        lower_answer = answer.lower()

        if plan.intent == "casual_check":
            forbidden = ["stt", "tts", "openwakeword", "modo de voz"]
            if any(term in lower_answer for term in forbidden) or "estou te ouvindo" not in lower_answer:
                return QualityResult(
                    passed=False,
                    reason="casual_check must be natural and avoid internal voice stack terms",
                    repaired_answer=(
                        "Sim, Ragton. Estou te ouvindo.\n\n"
                        "Pode falar comigo naturalmente. Quando você parar por um instante, eu processo e respondo."
                    ),
                )

        # 1. Anti-generic check
        for phrase in self.generic_phrases:
            if phrase in lower_answer:
                return QualityResult(
                    passed=False,
                    reason=f"A resposta contém a frase genérica/chavão proibida: '{phrase}'",
                    repaired_answer=self._build_fallback(plan.intent)
                )

        # 2. Wake-word hallucination check
        if plan.intent == "voice_status" or "wake-word" in lower_answer or "kora" in lower_answer:
            if "sim, já acordo" in lower_answer or "já está pronto" in lower_answer:
                # Assuming wake-word is not ready unless context says otherwise
                if not context.get("wake_word_ready", False):
                    return QualityResult(
                        passed=False,
                        reason="A resposta afirmou falsamente que o wake-word está pronto.",
                        repaired_answer="O alvo está configurado como 'Kora', mas o modelo real de wake-word ainda está pendente ou não validado. Hoje o modo confiável é o push-to-talk."
                    )

        # 3. Speaker ID hallucination check
        if "biometricamente" in lower_answer or "reconheço sua voz" in lower_answer:
             if not context.get("speaker_id_ready", False):
                 return QualityResult(
                     passed=False,
                     reason="A resposta afirmou falsamente que o reconhecimento biométrico de voz está ativo.",
                     repaired_answer="Ainda não biometricamente. Reconheço sua sessão por hint de ambiente, mas o Speaker ID real por voz ainda precisa de embeddings."
                 )

        # 4. Multi-part / Followup validation
        if plan.intent == "followup_complaint":
            if "desculpa" in lower_answer and len(answer.split()) < 20:
                return QualityResult(
                    passed=False,
                    reason="A resposta de correção parece ser apenas um pedido de desculpas vazio sem conteúdo real.",
                    repaired_answer="Você tem razão. Faltou responder uma parte da sua pergunta. Como posso complementar as informações que faltaram de forma direta?"
                )

        # Check if must_answer items are somewhat represented (basic heuristic)
        # We won't strictly fail this via regex because LLMs rephrase, but we can log.
        if len(answer.strip()) < 10:
            return QualityResult(
                passed=False,
                reason="A resposta é curta demais para cobrir o plano estabelecido.",
                repaired_answer=self._build_fallback(plan.intent)
            )

        return QualityResult(passed=True, reason="", repaired_answer=answer)

    def _build_fallback(self, intent: str) -> str:
        """Deterministic fallbacks when quality checks fail and we cannot repair easily."""
        if intent == "capabilities_query":
             from .capabilities import get_deterministic_capabilities_response
             return get_deterministic_capabilities_response()
        elif intent == "identity_query":
             return "Reconheço sua sessão por hint de ambiente. Você tem permissões configuradas no Kryonix, mas comandos críticos exigem teclado."
        
        return "Minha resposta original falhou nos testes de qualidade internos. Por favor, pergunte de forma mais específica para que eu evite respostas genéricas ou imprecisas."

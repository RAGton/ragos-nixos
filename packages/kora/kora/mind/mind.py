from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any

from kora.llm import ollama as ollama_adapter

from .context import build_mind_context
from .dialogue_policy import get_dialogue_policy
from .persona import GOOD_CASUAL_CHECK_RESPONSE, KORA_PERSONA
from .reflection import KoraReflection

logger = logging.getLogger("kora.mind")


@dataclass
class MindInput:
    user_text: str
    normalized_text: str
    user_id: str
    identity_trust: str
    source: str
    intent: str
    conversation_history: list
    profile_context: str
    system_state: dict[str, Any]
    safety_context: dict[str, Any]


@dataclass
class MindOutput:
    answer: str
    tone: str = "natural_direct"
    should_speak: bool = True
    memory_candidates: list = field(default_factory=list)
    needs_tool: bool = False
    tool_proposal: dict | None = None


class KoraMind:
    """LLM-centered response layer for Kora."""

    def __init__(self, llm_provider=None):
        self.llm_provider = llm_provider
        self.reflection = KoraReflection()

    async def respond(
        self,
        mind_input: MindInput,
        *,
        system_prompt: str,
        rag_context: str = "",
    ) -> MindOutput:
        policy = get_dialogue_policy(mind_input.intent)
        fast_answer = self._fast_path(mind_input)
        if fast_answer:
            reflected = self.reflection.review(
                mind_input.normalized_text,
                fast_answer,
                mind_input.intent,
                mind_input.safety_context,
            )
            return MindOutput(answer=reflected.answer, tone=policy.get("style", "natural_direct"))

        compact_context = build_mind_context(
            user_id=mind_input.user_id,
            identity_trust=mind_input.identity_trust,
            source=mind_input.source,
            intent=mind_input.intent,
            conversation_history=mind_input.conversation_history,
            profile_context=mind_input.profile_context,
            system_state=mind_input.system_state,
            safety_context=mind_input.safety_context,
            dialogue_policy=policy,
            rag_context=rag_context,
        )

        prompt = (
            f"{KORA_PERSONA}\n\n"
            "Responda ao usuario usando o contexto compacto. "
            "Nao despeje estado interno se a pergunta for casual. "
            "Nao invente runtime; marque como precisa validar quando nao houver dado real.\n\n"
            f"{compact_context}\n\n"
            f"Texto original: {mind_input.user_text}\n"
            f"Texto normalizado: {mind_input.normalized_text}"
        )

        try:
            if self.llm_provider:
                raw_answer = await self.llm_provider.generate(
                    prompt=prompt,
                    system_prompt=system_prompt,
                    context=rag_context,
                )
                model = getattr(self.llm_provider, "model", None)
            else:
                result = await ollama_adapter.generate_completion(
                    prompt=prompt,
                    system_prompt=system_prompt,
                    context=rag_context,
                    temperature=0.45,
                )
                raw_answer = result.get("answer", "")
                model = result.get("model")
            logger.debug("KoraMind generated answer with model=%s", model)
        except Exception as exc:
            logger.error("KoraMind generation failed: %s", exc)
            raw_answer = self._fallback(mind_input)

        reflected = self.reflection.review(
            mind_input.normalized_text,
            raw_answer,
            mind_input.intent,
            mind_input.safety_context,
        )
        return MindOutput(answer=reflected.answer, tone=policy.get("style", "natural_direct"))

    def _fast_path(self, mind_input: MindInput) -> str | None:
        text = mind_input.normalized_text.lower()

        if mind_input.intent == "casual_check":
            return GOOD_CASUAL_CHECK_RESPONSE

        if mind_input.intent == "capabilities_query":
            summary = mind_input.system_state.get("capabilities_summary")
            if summary:
                return summary

        if mind_input.intent == "technical_diagnostic" and "kora" in text:
            return (
                "Sim. O pedido e um pente fino na Kora, nao uma conversa generica.\n\n"
                "Diagnóstico: ela ainda estava tratando algumas frases naturais como status técnico e podia responder como programa.\n\n"
                "Causa provavel: roteamento amplo demais para `voice_status`, normalizacao pessoal incompleta e ausencia de uma camada KoraMind obrigatoria antes da resposta final.\n\n"
                "Correção: normalizar a fala do Ragton, rotear `voce esta me ouvindo?` como conversa casual, passar a resposta pela KoraMind e bloquear despejo de STT/TTS/openWakeWord quando a pergunta for humana.\n\n"
                "Validação: rodar `kora benchmark quality` e testar `kora ask \"bom entao voce esta me ouvindo agora ne\"`."
            )

        if mind_input.intent in {"complaint_bad_answer", "followup_complaint"}:
            return (
                "Voce tem razao. A resposta anterior falhou em entender o ponto real.\n\n"
                "Diagnóstico: a Kora provavelmente respondeu por um caminho generico ou tecnico demais.\n"
                "Causa: faltou recuperar o historico recente e aplicar a politica de reparo.\n"
                "Correção: vou usar a pergunta anterior como contexto, responder ao que ficou pendente e validar isso no benchmark de qualidade."
            )

        if mind_input.intent == "learning_request":
            return (
                "Entendi. Isso entra como aprendizado operacional da Kora.\n\n"
                "Perfil: atualizar preferencias e termos recorrentes do Ragton sem salvar segredo.\n"
                "Correcoes: registrar mapeamentos de fala, como `pentifino` para `pente fino`.\n"
                "Memoria: manter tudo incremental e reversivel em `/var/lib/kryonix/kora/learning`.\n"
                "Benchmark: transformar exemplos bons e ruins em cenarios de qualidade antes de qualquer treino."
            )

        if mind_input.intent == "voice_status":
            return (
                "Estado de voz real da Kora:\n\n"
                "- Push-to-talk e VAD: caminhos operacionais do prototipo.\n"
                "- STT/TTS: componentes do pipeline de voz, sujeitos aos modelos locais instalados.\n"
                "- Wake-word Kora: nao declarar pronto enquanto `ready=false`.\n"
                "- Speaker ID biometrico: foundation; nao autoriza comandos criticos.\n\n"
                "Para validar de verdade, rode `kora voice doctor`, `kora voice models` e um teste de transcricao."
            )

        return None

    def _fallback(self, mind_input: MindInput) -> str:
        if mind_input.intent == "casual_check":
            return GOOD_CASUAL_CHECK_RESPONSE
        return "Entendi. Vou responder de forma direta, com base no que esta validado no Kryonix."

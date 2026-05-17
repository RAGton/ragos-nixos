import json
import logging
import re
from dataclasses import dataclass
from typing import List, Optional

from kora.llm.ollama import OllamaAdapter

logger = logging.getLogger("kora.core.answer_planner")

@dataclass
class AnswerPlan:
    intent: str
    must_answer: List[str]
    context_needed: List[str]
    tools_needed: List[str]
    safety_notes: List[str]
    response_style: str

class AnswerPlanner:
    """Plans the required points to hit in an answer before asking the LLM to generate it."""

    def __init__(self, llm_provider=None):
        self.llm = llm_provider or OllamaAdapter()
        self.system_prompt = self._build_prompt()

    def _build_prompt(self) -> str:
        return """Você é o Planejador de Respostas da Kora.
Dada a entrada do usuário e a intenção (intent) já classificada, crie um plano estruturado de como responder.
Se a pergunta do usuário tiver várias partes, você deve listar cada parte em "must_answer" para garantir que nenhuma seja ignorada.

Responda ÚNICA e EXCLUSIVAMENTE em JSON válido, com a seguinte estrutura:
{
  "intent": "<intent_passada>",
  "must_answer": [
    "lista de tópicos obrigatórios que devem estar na resposta final"
  ],
  "context_needed": [
    "lista de fontes de contexto necessárias (ex: user_profile, capabilities_registry, system_logs, RAG)"
  ],
  "tools_needed": [
    "lista de ferramentas caso necessário executar algo (ou vazio)"
  ],
  "safety_notes": [
    "lista de restrições de segurança ou alertas para a resposta"
  ],
  "response_style": "structured_ptbr_direct"
}
Não inclua nenhum texto fora do JSON.
"""

    async def plan(self, text: str, intent: str, trust_level: str = "hint") -> AnswerPlan:
        # Pre-planned optimizations for deterministic scenarios
        if intent == "capabilities_query":
            return AnswerPlan(
                intent=intent,
                must_answer=["confirmar identidade", "explicar que identidade atual é hint", "listar capacidades reais", "listar pendências reais", "sugerir próximo passo"],
                context_needed=["user_profile", "capabilities_registry"],
                tools_needed=[],
                safety_notes=["comandos críticos exigem confirmação"],
                response_style="structured_ptbr_direct"
            )
        elif intent == "casual_check":
            return AnswerPlan(
                intent=intent,
                must_answer=["confirmar que esta ouvindo", "convidar fala natural", "nao citar STT/TTS/openWakeWord"],
                context_needed=[],
                tools_needed=[],
                safety_notes=["nao despejar status interno"],
                response_style="natural_short"
            )
        elif intent == "technical_diagnostic":
            return AnswerPlan(
                intent=intent,
                must_answer=["pente fino", "diagnostico", "causa provavel", "correcao", "validacao"],
                context_needed=["normalizacao", "router", "KoraMind", "benchmark"],
                tools_needed=[],
                safety_notes=["nao declarar runtime pronto sem teste"],
                response_style="engineering"
            )
        elif intent in {"complaint_bad_answer", "followup_complaint"}:
            return AnswerPlan(
                intent=intent,
                must_answer=["diagnostico", "causa", "correcao"],
                context_needed=["conversation_history"],
                tools_needed=[],
                safety_notes=["nao pedir desculpa vazia"],
                response_style="repair"
            )
        elif intent == "learning_request":
            return AnswerPlan(
                intent=intent,
                must_answer=["perfil", "correcoes", "memoria", "benchmark"],
                context_needed=["learning_profile"],
                tools_needed=[],
                safety_notes=["nao treinar automaticamente"],
                response_style="engineering"
            )
        elif intent == "identity_query":
            return AnswerPlan(
                intent=intent,
                must_answer=["reconhecimento do usuário", "nível de confiança da sessão", "permissões"],
                context_needed=["user_profile"],
                tools_needed=[],
                safety_notes=["USER é hint, não autenticação forte"],
                response_style="structured_ptbr_direct"
            )

        # Build dynamic plan via LLM
        prompt = f"Intent: {intent}\nUser Trust: {trust_level}\nEntrada do Usuário: '{text}'"
        
        try:
            raw_answer = await self.llm.generate(
                prompt=prompt,
                system_prompt=self.system_prompt
            )
            raw_answer = raw_answer.strip()
            
            # Extract JSON block
            match = re.search(r"```json\s*(\{.*?\})\s*```", raw_answer, re.DOTALL)
            if match:
                raw_answer = match.group(1)
            elif raw_answer.startswith("```") and raw_answer.endswith("```"):
                raw_answer = raw_answer.strip("`").strip()
                
            data = json.loads(raw_answer)
            return AnswerPlan(
                intent=data.get("intent", intent),
                must_answer=data.get("must_answer", ["Responder claramente à dúvida do usuário"]),
                context_needed=data.get("context_needed", []),
                tools_needed=data.get("tools_needed", []),
                safety_notes=data.get("safety_notes", []),
                response_style=data.get("response_style", "structured_ptbr_direct")
            )
        except Exception as e:
            logger.error(f"Answer planning failed: {e}")
            return AnswerPlan(
                intent=intent,
                must_answer=["Responder claramente", "Não ignorar detalhes"],
                context_needed=[],
                tools_needed=[],
                safety_notes=[],
                response_style="structured_ptbr_direct"
            )

# Workflow: Garantia de Qualidade Conversacional (Quality Pass)

Este fluxo operacional detalha como validar que as alterações cognitivas da Kora (Mind, Persona, Diálogo) estão em perfeita conformidade com as expectativas do operador.

---

## Gates de Aceite Obrigatórios

### 1. Diálogo Casual (Sem Tech-Dump)
A Kora nunca deve despejar metadados de status interno de hardware em conversas cotidianas e casuais.
- **Entrada de Teste**: `"bom então você está me ouvindo agora né"`
- **Expectativa**: `"Sim, Ragton. Estou te ouvindo perfeitamente."` (ou similar natural).
- **Proibido**: Conter substrings como `"STT"`, `"TTS"`, `"openWakeWord"`, ou metadados de drivers.

### 2. Recuperação de Conversa Insatisfatória
A Kora deve reconhecer quando falhou em responder de primeira e reparar ativamente o fluxo sem repetir a mesma resposta robótica.
- **Entrada de Teste**: `"ela respondeu ruim e ignorou minha pergunta"` (ou `"você não respondeu minha dúvida anterior"`).
- **Expectativa**: A Kora recupera o histórico da conversa, localiza o ponto ignorado e responde com precisão focada, admitindo a lacuna de forma direta e sem desculpas longas e vazias.

### 3. Entendimento de Idiomatismos (Pente Fino)
A Kora deve reconhecer expressões idiomáticas e operacionais locais do repositório.
- **Entrada de Teste**: `"faz um pentifino na kora"`
- **Expectativa**: Realiza um diagnóstico completo da integridade interna da Kora (Voz, RAG, Usuário) e propõe correções imediatas de forma concisa.

---

## Como Executar a Suíte Completa de Qualidade
Use o comando canônico da CLI para disparar e avaliar todos os cenários integrados no arquivo `scenarios.json`:
```bash
kora benchmark quality
```
Se qualquer teste falhar ou a pontuação de naturalidade cair abaixo do limiar (threshold) de 95%, a tarefa é classificada como **FAIL** e deve ser corrigida imediatamente.

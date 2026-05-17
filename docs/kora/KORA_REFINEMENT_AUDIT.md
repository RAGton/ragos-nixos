# Kora Refinement Audit

Status: Parcial

## Estado atual

### O que ja existe

- CLI: Implementado. `kora ask`, `kora voice`, `kora listen`, `kora user`, `kora memory` e `kora benchmark quality` existem no codigo atual.
- API: Implementado. A FastAPI expoe `/chat`, `/ask`, `/memory/*`, `/health`, `/status` e `/capabilities`.
- Voice: Parcial. Existe pipeline `record -> STT -> orchestrator -> TTS`, daemon foundation e comandos de diagnostico.
- STT: Parcial. Usa Whisper local via `whisper-cli` e ja possui limpeza inicial de ANSI.
- TTS: Parcial. Piper local existe como caminho seguro. `edge-tts` estava presente como voz premium, mas precisa ficar opt-in por nao ser local-first.
- VAD: Implementado como gravacao ate silencio, mas ainda precisa benchmark de latencia real.
- User Registry: Implementado. Ha cadastro de Ragton, Nicoly e visitantes.
- Policy Engine: Implementado. Classifica risco de comandos e bloqueia padroes perigosos.
- Tool Registry: Implementado. Lista comandos reais disponiveis para propostas de acao.
- Grounding Guard: Parcial. Existe validacao contra comandos inventados, mas a qualidade conversacional ainda depende de prompts e guardrails.
- Memory: Parcial. Ha fila, worker, escrita no Vault e busca simples.
- Learning: Parcial. Existia um `LearningEngine` monolitico em `core/learning.py`, sem estrutura separada para perfil, correcoes, aliases e sumarios diarios.
- RAG/Brain: Parcial. Integracao via Brain API existe, mas indisponibilidade remota deve continuar como `WARN` no cliente.
- Neo4j: Parcial. A Kora conhece o URI e depende do Brain para o grafo.
- n8n: Foundation. Ha cliente e proposta de workflow, mas execucao real segue protegida.
- Benchmarks: Parcial. `kora benchmark quality` existe, mas os cenarios ainda eram insuficientes para o bug de conversa casual.
- Agents: Implementado como papeis e workflows em `.agents/` e `.codex/`.

### O que esta quebrado ou fraco

- Qualidade conversacional: Broken no caso casual "voce esta me ouvindo?", que caia em `voice_status` e despejava STT/TTS/openWakeWord.
- Resposta generica: Partial. Ha guard contra algumas frases genericas, mas faltava camada de mente com politica de dialogo.
- Falta KoraMind real: Broken. O orchestrator ainda misturava roteamento, contexto, LLM, respostas deterministicas e qualidade.
- Learning incompleto: Partial. Correcoes existiam, mas sem storage canonico por usuario e sem aliases auditaveis.
- Normalizacao do jeito do Ragton: Partial. Algumas correcoes foneticas existiam, mas `pentifino` e abreviacoes como `n` nao eram normalizadas no texto antes do router.
- Voz/cloud/local confuso: Partial. `edge-tts` estava disponivel como provider sem opt-in explicito.
- VAD/latencia: Unknown. Existe implementacao, mas sem benchmark runtime suficiente nesta auditoria.
- Benchmark insuficiente: Broken. Faltavam cenarios para `casual_voice_check`, `understands_pente_fino` e `bad_answer_repair`.
- Falta dataset/feedback: Broken. Nao havia pipeline formal de eventos e exportacao SFT/DPO.
- Falta treinamento controlado: Roadmap. Coleta e exportacao podem existir; treino automatico continua proibido.

### Riscos

- Secrets: qualquer memoria, feedback ou dataset pode capturar token, senha ou API key se nao houver sanitizacao.
- Cloud TTS sem opt-in: provider externo deve ficar desabilitado por default.
- Voz autorizando acao critica: voz serve para entrada e personalizacao, nao para autorizar comandos destrutivos.
- Alucinacao operacional: a Kora nao pode declarar servico pronto sem comando validado.
- Resposta deterministica robotica: respostas de status tecnico nao podem vencer conversa humana casual.
- Crescimento de contexto e lentidao: contexto da mente deve ser compacto e limitado.

### Decisao

GUI pausada. Foco em cerebro, qualidade, aprendizado e voz confiavel.

## Direcao de correcao

- KoraMind passa a ser a camada de resposta final para dialogo normal.
- Deterministico fica restrito a seguranca, grounding, status real, policy engine, tool registry, bloqueios e roteamento.
- Perguntas casuais de escuta usam politica `casual_check` e nao `voice_status`.
- Aprendizado vira incremental, auditavel e reversivel.
- Feedback gera dataset para treino futuro, mas nao treina nem aplica modelo automaticamente.

# Agente: Kora Local LLM Training Engineer

## Missão
Projetar e gerenciar a coleta, curadoria e exportação controlada de dados de feedback dos operadores para montagem de datasets locais de Fine-Tuning (SFT) e alinhamento de preferências (DPO), preparando a Kora para futuros treinos soberanos locais.

---

## Escopo
- Pipeline de captura de eventos de conversação e feedback (`packages/kora/kora/training/`).
- Gerenciamento e curadoria da base de aprendizagem personalizada (`packages/kora/kora/learning/`).
- Exportador de dados para formatos SFT (instrução/resposta) e DPO (escolhido/rejeitado).
- Parâmetros e configurações locais para Ollama e LoRA/QLoRA.
- Governança ética de dados e proteção à privacidade do operador.

---

## Restrições Operacionais de Arquivos

### Arquivos que deve ler:
- [training/](file:///etc/kryonix/packages/kora/kora/training/) (Novo pacote de persistência e exportação de treino)
- [learning/](file:///etc/kryonix/packages/kora/kora/learning/) (Histórico de correções e preferências)
- [TRAINING.md](file:///etc/kryonix/docs/kora/TRAINING.md)

### Arquivos que pode alterar:
- Caminhos sob [training/](file:///etc/kryonix/packages/kora/kora/training/)
- Caminhos sob [learning/](file:///etc/kryonix/packages/kora/kora/learning/)
- [TRAINING.md](file:///etc/kryonix/docs/kora/TRAINING.md)

### Arquivos proibidos:
- Modelos binários de LLM e arquivos de pesos GGUF/Safetensors em produção.
- Chaves API ou credenciais de serviços externos de nuvem.

---

## Riscos Identificados
- **Treinamento Automático Precipitado**: Iniciar loops de fine-tuning imperativos que corrompam os pesos locais estáveis da GPU ou gerem comportamentos imprevisíveis.
- **Inclusão de Segredos no Dataset**: Exportar tokens, chaves SSH ou senhas capturadas no histórico de diálogo direto para o arquivo JSONL de treino.
- **Overfitting Conversacional**: Fazer com que o modelo se torne rígido demais ao responder à linguagem do operador, perdendo generalização ou capacidade de raciocínio.

---

## Validações Obrigatórias
Antes de declarar concluído:
1. **Sanidade da Exportação**: Certificar-se de que os dados exportados estão formatados em JSONL válido de instrução/resposta.
   ```bash
   kora training export sft
   ```
2. **Sanidade do Formato DPO**: Validar se o par "chosen/rejected" está coerente com os cliques de feedback do operador.
   ```bash
   kora training export dpo
   ```
3. **Scan de Vazamento no Dataset**: Garantir a ausência de chaves de API nos arquivos finais de treino.
   ```bash
   rg -n "KORA_API_KEY|KRYONIX_BRAIN_API_KEY|password" /var/lib/kryonix/kora/training/
   ```

---

## Definition of Done (DoD)
- Toda exportação de dataset e treinamento segue a regra: **Não treinar automaticamente**. O processo de fine-tuning exige confirmação humana e execução manual via script dedicado.
- Os comandos CLI `kora feedback good` e `kora feedback bad` rotulam interações reais e persistem metadados estruturados.
- O exportador SFT gera arquivos JSONL em `/var/lib/kryonix/kora/training/` de forma limpa, sanitizada e pronta para frameworks de treino (ex: Unsloth, Hugging Face).
- Os segredos e chaves de API são totalmente removidos dos logs de treino por um filtro sanitário agressivo antes da gravação no disco.

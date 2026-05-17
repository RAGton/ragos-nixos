# Kora Training Dataset

Status: Parcial

## Objetivo

O pacote `kora.training` coleta eventos sanitizados de conversa e feedback para treino futuro controlado.

Pipeline recomendado:

```txt
coleta -> curadoria -> SFT/QLoRA -> DPO -> benchmark -> aplicar so se melhorar
```

## Storage

- Eventos: `/var/lib/kryonix/kora/training/events.jsonl`
- Export SFT: `/var/lib/kryonix/kora/training/exports/sft.jsonl`
- Export DPO: `/var/lib/kryonix/kora/training/exports/dpo.jsonl`

Se `/var/lib` nao for gravavel, a CLI usa fallback em `~/.local/share/kryonix/kora/training`.

## Comandos

```bash
kora feedback good
kora feedback bad "motivo"
kora training status
kora training export sft
kora training export dpo
```

## Formato de evento

```json
{
  "timestamp": "...",
  "user_id": "ragton",
  "source": "voice",
  "original_text": "...",
  "normalized_text": "...",
  "intent": "...",
  "answer": "...",
  "user_feedback": null,
  "quality_score": null,
  "used_rag": false,
  "used_tool": false
}
```

## Regras

- Nao treinar automaticamente.
- Nao exportar secrets.
- Feedback ruim gera dado para curadoria; nao deve ser aplicado como verdade sem revisao humana.
- Um modelo novo so deve ser adotado depois de benchmark de qualidade e regressao contra os cenarios da Kora.

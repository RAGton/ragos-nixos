# Roadmap

Status: Roadmap

## Resumo
Este documento consolida o que ainda não está plenamente implementado ou validado. Não trate itens abaixo como prontos.

## Itens principais
### Brain API
- Status: **Parcial**
- Gap: persistência/robustez e validações completas.

### MCP remoto completo
- Status: **Parcial**
- Gap: validação end-to-end no Glacier.

### Glacier autônomo (server IA)
- Status: **Parcial**
- Gap: serviços boot-first sem login manual.

### Web research controlado
- Status: **Não implementado**

### Geração de pacotes com IA
- Status: **Não implementado**

### Autocuradoria do Vault
- Status: **Não implementado**

### ISO instalável Kryonix
- Status: **Parcial**

### Pipeline docs → vault → RAG
- Status: **Não implementado**

## Milestones (resumo)
- **v0.4.2**: estabilização e governança (em execução).
- **v0.5.0**: Glacier e Brain API (em execução).
- **v0.6.0**: ISO e IA autônoma (roadmap).

## Quando usar
Para alinhar expectativas antes de prometer funcionalidades.

## Comandos relevantes
```sh
systemctl status kryonix-brain-api.service --no-pager
curl -fsS http://127.0.0.1:8000/health
kryonix mcp doctor
```

## Riscos
- Prometer features não implementadas.
- Tratar itens de roadmap como entregues.

## Links relacionados
- [Arquitetura](Arquitetura)
- [Brain, RAG e CAG](Brain-RAG-CAG)
- [Testes e Validação](Testes-e-Validacao)

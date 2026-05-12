# Runtime Doctor Workflow

## Quando usar
Para diagnosticar problemas em serviços ativos (Ollama, Brain API, etc.) ou saúde do sistema.

## Regras aplicadas
- `.agents/rules/00-core.md`
- `.agents/rules/20-testing.md`

## Entradas
- Status dos serviços systemd.
- Logs do sistema.

## Saídas
- Relatório de saúde.
- Sugestões de correção.

## Arquivos permitidos
- `/run/current-system/sw/bin/kryonix` (via comando)
- Logs (via `journalctl`)

## Passos
1. **Verificar Serviços:** Rodar `systemctl status` nos serviços críticos.
2. **Checar Logs:** Analisar `journalctl -u <servico> -n 50`.
3. **Rodar Doctor:** Usar `kryonix doctor` se disponível.
4. **Validar Portas:** Verificar se as portas (8000, 11434, etc.) estão abertas.

## Validação obrigatória
- Serviços devem estar em estado `active (running)`.

## Rollback
- Reiniciar serviços se necessário (com cautela).

## Output final esperado
Sistema operacional estável ou diagnóstico preciso da falha.

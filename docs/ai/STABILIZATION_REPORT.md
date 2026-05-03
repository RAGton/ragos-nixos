# Kryonix Distributed Workstation: Relatório de Estabilização Final

Este documento resume as ações realizadas para estabilizar o ambiente distribuído Kryonix entre o **Glacier** (Servidor AI) e o **Inspiron** (Workstation).

## 1. Workstation Inspiron: Apps Restaurados
- **VSCode (VSCodium)**: Reativado via Home Manager. Corrigido erro de tipo no Nix (`vscodium` -> `codium`).
- **Obsidian**: Validado e com wrapper `kryonix-obsidian` funcional.
- **WinBox**: Binário `/run/current-system/sw/bin/WinBox` validado e acessível.
- **Limpeza**: Removidas entradas redundantes e auditados atalhos `.desktop`.

## 2. Kryonix Brain: Inteligência Distribuída
- **Modelo Upgradado**: O sistema agora utiliza `qwen2.5-coder:7b` por padrão para consultas, oferecendo respostas técnicas muito mais precisas.
- **Grounding Avançado**: Implementado pipeline de grounding manual com ranking de chunks, multi-hop reasoning e estratégia de busca dinâmica.
- **API Transparente**: As respostas agora incluem:
  - **Status**: Sucesso/Erro.
  - **Answer**: Resposta técnica consolidada.
  - **Sources**: Lista de arquivos e chunks utilizados com score de relevância.
  - **Grounding Statistics**: Quantidade de entidades e relações processadas.

## 3. Acesso Remoto (Tailscale)
- **Zero Trust**: SSH, Ollama e Brain API estão restritos à interface Tailscale.
- **Segurança**: Rotação da `KRYONIX_BRAIN_KEY` concluída. A chave está persistida no escopo `Machine` do Glacier.

## 4. Manutenção do Repositório
- **Arquivamento**: ~10 documentos de migração e checklists antigos foram movidos para `docs/legacy/archive-2026-04-28`.
- **Git**: Sincronização total de submodules concluída e push realizado.

---

### Comandos Úteis (Inspiron)
- `kryonix switch`: Aplica mudanças de sistema.
- `kryonix home`: Aplica mudanças de usuário (VSCode/Rice).
- `kryonix brain search "pergunta"`: Consulta o cérebro no Glacier via rede privada.

### Comandos Úteis (Glacier)
- `kryonix brain doctor`: Verifica saúde do Grafo e API.
- `kryonix brain search "pergunta" --verbose`: Busca local com detalhes de grounding.
- `kryonix brain api`: Reinicia o servidor de IA.

# Current State - Kryonix 🧊⚡

- **Fase Atual:** Estabilização v0.5.0 e Automação de Governança.
- **Arquitetura:** 
    - **Inspiron:** Workstation cliente, Hyprland/Caelestia, CLI local.
    - **Glacier:** Servidor IA, Brain API, Neo4j, Ollama (IP `100.125.99.110`, SSH `2224`).
- **Estado do Repo:** 
    - Sincronizado e limpo. 
    - Registry v2 100% normalizado (Schema Version 2).
- **CLI & Operações:**
    - **Registry v2:** Normalizado com metadados rigorosos (`critical` risk level, `requires_runtime` array).
    - **Help:** Visual polido, suporte a cores para riscos críticos e alertas de sudo.
    - **Validadores:** `check-kryonix-cli-help.sh` agora valida contrato JSON v2.
- **Brain & AI:**
    - **Health:** API e Storage estáveis no Glacier.
    - **Registry Integration:** Ingestão do Registry v2 no grafo 100% implementada e validada via dry-run.
- **Próxima Meta:** Ingestão de logs técnicos e eventos históricos no Knowledge Graph.
- **Bloqueios:** Nenhum.

## Decisões Recentes
- **Neo4j/Graph somente no Glacier**: Toda geração final de manifesto, dry-run oficial, apply e validação de escrita no Neo4j deve ocorrer no Glacier. Inspiron atua como cliente de desenvolvimento e consulta.
- **Registry v2 como Contrato**: O `kryonix commands --json` é o contrato formal para o Knowledge Graph.
- **MCP Quality Layer**: Planejado como próxima etapa após consolidação do Registry no grafo.

*Última atualização: 2026-05-14 por Antigravity*

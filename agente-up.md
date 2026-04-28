Você é o agente responsável por estabilizar o ecossistema Kryonix completo.

Contexto:
- Glacier é o servidor central de IA.
- Inspiron é o host NixOS cliente/workstation.
- Glacier roda:
  - Ollama
  - Kryonix Brain API
  - LightRAG
  - Vault central
- Inspiron deve ser:
  - sistema operacional profissional para trabalho
  - Hyprland/Caelestia estável
  - launcher funcional
  - apps abrindo corretamente
  - cliente leve da IA remota
- O sistema está apresentando erros UWSM:
  - .desktop aponta para executável ausente
  - WinBox ausente
  - Flatpak ausente
  - Obsidian não abre
  - VSCode sumiu
  - vários programas não abrem pelo launcher

Objetivo final:
1. Corrigir todos os apps quebrados no Inspiron.
2. Restaurar VSCode/editor de trabalho.
3. Corrigir Obsidian.
4. Corrigir WinBox.
5. Corrigir Flatpak ou remover restos obsoletos.
6. Corrigir launcher/Caelestia/UWSM.
7. Melhorar o Kryonix Brain para respostas técnicas, com fontes.
8. Melhorar o modelo/parametrização do Ollama para código e trabalho.
9. Refatorar documentação, remover obsoletos e deixar docs concisas.
10. Garantir Git limpo, submodules corretos e push feito.
11. Testar antes e depois de aplicar.
12. Não quebrar o sistema.

REGRAS ABSOLUTAS:
- NÃO declarar pronto sem testes reais.
- NÃO rodar switch antes de dry-build e test passarem.
- NÃO apagar arquivos sem backup.
- NÃO commitar secrets.
- NÃO colocar KRYONIX_BRAIN_KEY em Nix, docs, Git ou histórico.
- NÃO usar port forwarding público.
- Usar Tailscale para IA remota.
- Corrigir declarativamente via Nix/Home Manager.
- Evitar correções manuais que somem no rebuild.
- Se houver erro, parar, reportar e corrigir.
- Submodules devem ser commitados/pushados antes do repo raiz.
- Não usar git clean -fd sem autorização explícita.
- Não resetar sistema sem backup branch.

DADOS:
- Glacier Tailscale: 100.108.71.36
- Inspiron Tailscale: 100.91.45.6
- Brain API: http://100.108.71.36:8000
- Ollama: http://100.108.71.36:11434
- SSH Inspiron: rocha@inspiron.ghoul-pike.ts.net
- Repo Glacier: C:\Users\aguia\Documents\kryonix
- Repo Inspiron: /etc/kryonix
- Secret local Inspiron: /etc/kryonix/brain.env

============================================================
FASE 0 — NÃO EDITAR AINDA: DIAGNÓSTICO GERAL
============================================================

No Glacier:
cd C:\Users\aguia\Documents\kryonix

Rodar:
git status
git submodule status
git diff --stat
git -C packages/kryonix-brain-lightrag status
git -C ai/kryonix-vault status

Validar serviços:
curl.exe http://100.108.71.36:8000/health
curl.exe http://100.108.71.36:11434/api/tags

$Key = [Environment]::GetEnvironmentVariable("KRYONIX_BRAIN_KEY", "Machine")
curl.exe -H "X-API-Key: $Key" http://100.108.71.36:8000/stats

.\rag.bat stats
.\rag.bat test all

No Inspiron via SSH:
ssh rocha@inspiron.ghoul-pike.ts.net

Rodar:
hostname
whoami
pwd
date
uptime
cd /etc/kryonix
git status
git submodule status
tailscale status
tailscale ping 100.108.71.36

Validar IA remota:
curl --connect-timeout 5 http://100.108.71.36:8000/health
curl --connect-timeout 5 http://100.108.71.36:11434/api/tags

source /etc/kryonix/brain.env 2>/dev/null || true
curl --connect-timeout 5 -H "X-API-Key: $KRYONIX_BRAIN_KEY" http://100.108.71.36:8000/stats

NÃO prosseguir se:
- Tailscale falhar
- Brain API falhar
- Git estiver em rebase/merge quebrado
- submodule estiver vazio/quebrado

============================================================
FASE 1 — BACKUP DE SEGURANÇA NO INSPIRON
============================================================

No Inspiron:
cd /etc/kryonix

Criar branch backup:
git branch backup/inspiron-before-system-repair-$(date +%Y%m%d-%H%M%S)

Garantir que secret não entra no Git:
echo "brain.env" >> .git/info/exclude
echo "/brain.env" >> .git/info/exclude

Se houver rebase/merge pendente:
git status
git rebase --abort || true
git merge --abort || true

Atualizar de forma segura:
git fetch origin
git reset --hard origin/main
git submodule sync --recursive
git submodule update --init --recursive --force

Validar:
git status
git submodule status

Se aparecer "not our ref":
- parar
- corrigir no Glacier o ponteiro do submodule
- não continuar localmente.

============================================================
FASE 2 — AUDITORIA DE .DESKTOP QUEBRADOS
============================================================

Problema atual:
UWSM/Caelestia mostra erros como:
- winbox.desktop aponta para WinBox ausente
- flatpak desktop aponta para flatpak ausente
- obsidian.desktop aponta para wrapper ausente
- vários apps não abrem

No Inspiron, criar auditoria:

cat > /tmp/check-desktop-exec.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

dirs=(
  "$HOME/.local/share/applications"
  "$HOME/.local/share/flatpak/exports/share/applications"
  "$HOME/.nix-profile/share/applications"
  "/etc/profiles/per-user/$USER/share/applications"
  "/run/current-system/sw/share/applications"
  "/var/lib/flatpak/exports/share/applications"
)

broken=0

for dir in "${dirs[@]}"; do
  [ -d "$dir" ] || continue
  echo "### DIR: $dir"
  find "$dir" -name "*.desktop" -type f | while read -r file; do
    exec_line="$(grep -m1 '^Exec=' "$file" || true)"
    [ -n "$exec_line" ] || continue

    cmd="${exec_line#Exec=}"
    cmd="${cmd%% *}"
    cmd="${cmd//\"/}"

    [ -z "$cmd" ] && continue

    if ! command -v "$cmd" >/dev/null 2>&1 && [ ! -x "$cmd" ]; then
      echo "[BROKEN] $file"
      echo "         $exec_line"
      echo "         missing: $cmd"
      broken=1
    fi
  done
done
EOF

chmod +x /tmp/check-desktop-exec.sh
/tmp/check-desktop-exec.sh | tee /tmp/desktop-broken-before.txt

Guardar esse relatório.

Diagnosticar todos os comandos ausentes:
command -v flatpak || true
command -v obsidian || true
command -v rag-obsidian || true
command -v kryonix-obsidian || true
command -v code || true
command -v codium || true
command -v vscode || true
command -v WinBox || true
command -v winbox || true
command -v kryonix-launch || true
command -v caelestia || true
command -v celestial-shell || true

============================================================
FASE 3 — RESTAURAR APPS ESSENCIAIS
============================================================

Garantir que o sistema tenha um conjunto mínimo de trabalho:

Obrigatórios:
- VSCode ou VSCodium
- Obsidian ou wrapper Kryonix Obsidian funcional
- Browser principal
- Terminal
- File manager
- Git
- Curl
- Tailscale
- Kryonix CLI
- Launcher
- Caelestia/Celestial Shell
- Flatpak, se houver apps Flatpak ativos
- WinBox, se o desktop entry existir ou se for ferramenta usada

Critério:
Se existe .desktop ativo para um app, o executável precisa existir.
Se não queremos o app, remover/arquivar o .desktop obsoleto de forma declarativa.

Procurar origem dos apps:
cd /etc/kryonix

grep -R "vscode\|vscodium\|code\|obsidian\|rag-obsidian\|kryonix-obsidian\|flatpak\|winbox\|WinBox\|caelestia\|celestial\|launcher" \
  hosts modules home desktop packages users features . \
  2>/dev/null || true

Corrigir declarativamente:
- packages globais em módulo/profile correto
- apps de usuário no Home Manager correto
- wrappers em package próprio
- desktop entries em Home Manager/Nix
- XDG_DATA_DIRS no módulo de desktop
- PATH da sessão UWSM/Hyprland

NÃO corrigir apenas apagando arquivo manualmente.

============================================================
FASE 4 — DECISÃO SOBRE FLATPAK
============================================================

Erro atual:
.desktop do Zen Browser em ~/.local/share/flatpak/... aponta para flatpak ausente.

Escolher UMA estratégia:

OPÇÃO A — Usar Flatpak oficialmente:
- habilitar services.flatpak.enable = true
- garantir flatpak no ambiente
- garantir portal correto
- garantir XDG_DATA_DIRS inclui:
  - ~/.local/share/flatpak/exports/share
  - /var/lib/flatpak/exports/share
  - /run/current-system/sw/share
  - /etc/profiles/per-user/rocha/share
- garantir UWSM importa ambiente

OPÇÃO B — Remover restos Flatpak:
- se não for usar Flatpak, mover exports para backup:
  ~/.local/share/flatpak.bak-YYYYMMDD-HHMM
- remover referências obsoletas do launcher
- instalar apps equivalentes via Nix

Preferência:
Se Zen Browser é usado, escolher OPÇÃO A.
Se Flatpak só tem lixo antigo, escolher OPÇÃO B.

============================================================
FASE 5 — CORRIGIR OBSIDIAN
============================================================

Obsidian ainda não abre.

Diagnóstico:
command -v obsidian || true
command -v rag-obsidian || true
command -v kryonix-obsidian || true

grep -R "obsidian\|rag-obsidian\|kryonix-obsidian" \
  ~/.local/share/applications \
  ~/.nix-profile/share/applications \
  /etc/profiles/per-user/rocha/share/applications \
  /run/current-system/sw/share/applications \
  /etc/kryonix \
  2>/dev/null || true

Correção desejada:
- Se o contrato é `kryonix-obsidian`, garantir wrapper funcional.
- Se o contrato é `rag-obsidian`, garantir wrapper funcional ou redirecionar para `kryonix-obsidian`.
- O desktop entry precisa apontar para binário existente.
- Obsidian deve abrir o vault correto.
- Corrigir via Home Manager/Nix, não manual.

Testes:
obsidian --version || true
rag-obsidian --version || true
kryonix-obsidian --version || true
gtk-launch obsidian || true

============================================================
FASE 6 — CORRIGIR VSCODE / EDITOR
============================================================

Problema:
VSCode sumiu.

Diagnóstico:
command -v code || true
command -v codium || true
grep -R "vscode\|vscodium\|code" /etc/kryonix 2>/dev/null || true

Correção:
- Escolher VSCode ou VSCodium conforme padrão do projeto.
- Instalar declarativamente.
- Garantir desktop entry.
- Garantir comando:
  code
  ou codium
- Garantir launcher mostra o editor.

Se usar VSCode:
- avaliar extensões essenciais via Home Manager se já houver padrão.
- não instalar extensão manual sem documentar.

============================================================
FASE 7 — CORRIGIR WINBOX
============================================================

Erro:
winbox.desktop aponta para WinBox ausente.

Diagnóstico:
command -v WinBox || true
command -v winbox || true
grep -R "WinBox\|winbox" /etc/kryonix ~/.local/share/applications /run/current-system/sw/share/applications 2>/dev/null || true

Correção:
- Se WinBox é necessário:
  - instalar pacote/wrapper declarativo.
  - garantir desktop entry aponta para executável correto.
- Se não é necessário:
  - remover desktop entry obsoleto da geração.
  - mover arquivo local antigo para backup.

Critério:
nenhum .desktop ativo pode apontar para WinBox ausente.

============================================================
FASE 8 — CORRIGIR UWSM / HYPRLAND / CAELESTIA
============================================================

Validar ambiente:

echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"
echo "$WAYLAND_DISPLAY"
echo "$PATH"
echo "$XDG_DATA_DIRS"

Logs:
journalctl --user -p 3 -b --no-pager | tail -200
journalctl --user -b --no-pager | grep -Ei "uwsm|hyprland|caelestia|launcher|desktop|missing executable|not found" | tail -200

Corrigir:
- environment variables da sessão
- systemd user import environment
- XDG portals
- XDG_DATA_DIRS
- PATH
- services de user
- launcher cache

Garantir:
- apps do sistema aparecem
- apps do usuário aparecem
- Flatpak aparece se habilitado
- wrappers aparecem
- launcher não dispara missing executable

============================================================
FASE 9 — LIGHTRAG / KRYONIX BRAIN: QUALIDADE DA RESPOSTA
============================================================

A conexão Inspiron → Glacier funciona, mas a resposta ainda é genérica e alucinada.

Problema:
Query:
"Como funciona o pipeline de RAG do Kryonix?"

Resposta ruim:
- cita OpenAI/GPT
- exemplo de restaurante
- banco genérico de perguntas/respostas
- não cita fontes
- não explica graph search, entity/relation chunks, vector fallback, ranking, API

Objetivo:
Melhorar /search para resposta técnica, específica e grounded.

No Glacier:
cd C:\Users\aguia\Documents\kryonix

Diagnóstico:
.\rag.bat search "Como funciona o pipeline de RAG do Kryonix?" --lang pt-BR --verbose

API:
$Key = [Environment]::GetEnvironmentVariable("KRYONIX_BRAIN_KEY", "Machine")

curl.exe -H "X-API-Key: $Key" `
  -H "Content-Type: application/json" `
  -X POST `
  -d '{\"query\":\"Como funciona o pipeline de RAG do Kryonix?\",\"lang\":\"pt-BR\",\"no_cache\":true,\"debug\":true}' `
  http://100.108.71.36:8000/search

Implementar se ainda não existir:
- no_cache
- debug
- grounding
- sources
- warnings

Contrato esperado:
{
  "status": "success",
  "answer": "...",
  "grounding": {
    "entities": 0,
    "relations": 0,
    "chunks": 0
  },
  "sources": [
    {
      "title": "RAG Pipeline Interno.md",
      "chunk_id": "...",
      "score": 0.91
    }
  ],
  "warnings": []
}

Regras:
- sources não pode ser vazio em success.
- chunks precisa ser > 0.
- se chunks=0, abortar.
- não usar cache para validar.
- não responder genérico.
- prompt deve exigir resposta somente baseada nos chunks.
- incluir referências.
- priorizar RAG Pipeline Interno.md, MCP Architecture.md, Kryonix Brain.

Melhorar prompt de síntese:
- Responder em pt-BR.
- Técnico e direto.
- Não mencionar OpenAI/GPT se não estiver no contexto.
- Não inventar exemplos.
- Se contexto insuficiente, dizer isso.
- Incluir "Referências".

Melhorar ranking:
- boost genérico por path/título técnico.
- boost para notas em IA e Agentes.
- boost para RAG/Pipeline/MCP/Kryonix/LightRAG.
- não hardcodar só uma query.

Rodar:
.\rag.bat stats
.\rag.bat test all
.\rag.bat search "Como funciona o pipeline de RAG do Kryonix?" --lang pt-BR --verbose

Testar no Inspiron:
source /etc/kryonix/brain.env

curl --connect-timeout 30 \
  -H "X-API-Key: $KRYONIX_BRAIN_KEY" \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{"query":"Como funciona o pipeline de RAG do Kryonix?","lang":"pt-BR","no_cache":true,"debug":true}' \
  http://100.108.71.36:8000/search

kryonix brain search "Como funciona o pipeline de RAG do Kryonix?"

Critério:
- sem restaurante
- sem OpenAI/GPT genérico
- com sources
- com chunks > 0
- com explicação real do Kryonix

============================================================
FASE 10 — MODELO / PARÂMETROS DE IA
============================================================

Objetivo:
Melhorar a qualidade do modelo usado para código e respostas técnicas.

No Glacier:
curl.exe http://100.108.71.36:11434/api/tags
ollama list

Modelos atuais podem incluir:
- qwen2.5-coder:3b
- qwen2.5-coder:7b
- qwen3.5-8k
- qwen3.5

Tarefas:
- Escolher modelo padrão melhor para código e RAG técnico.
- Preferir modelo coder com maior qualidade que rode aceitavelmente no Glacier.
- Não trocar modelo sem testar latência.
- Permitir configuração via env:
  KRYONIX_LLM_MODEL
  KRYONIX_EMBED_MODEL
- Não hardcodar modelo em vários lugares.
- Documentar como trocar.

Testar:
- resposta técnica do pipeline RAG
- resposta sobre Hyprland
- resposta sobre NixOS modules

Critério:
- melhor qualidade
- latência aceitável
- sem quebrar test all

============================================================
FASE 11 — DOCUMENTAÇÃO: LIMPAR OBSOLETOS E CONCISÃO
============================================================

Objetivo:
Remover documentação obsoleta e deixar somente documentação útil.

Auditar docs:
find docs ai/kryonix-vault -name "*.md" | sort

Procurar lixo:
grep -R "TODO\|antigo\|obsoleto\|deprecated\|fase completa\|STEP_\|PHASE_\|rascunho" docs ai/kryonix-vault 2>/dev/null || true

Regras:
- Não apagar conteúdo histórico útil sem mover para docs/legacy.
- Remover duplicações.
- Reescrever docs longas e genéricas em formato conciso.

Formato obrigatório:
# Título
## Objetivo
## Arquitetura
## Como usar
## Comandos
## Validação
## Troubleshooting
## Rollback

Docs mínimas obrigatórias:
- docs/hosts/inspiron.md
- docs/desktop/hyprland.md
- docs/desktop/caelestia.md
- docs/desktop/app-launcher.md
- docs/desktop/flatpak.md
- docs/desktop/obsidian.md
- docs/ai/distributed-brain.md
- docs/ai/lightrag-search-quality.md
- docs/ai/models.md
- docs/operations/recovery.md

Remover/arquivar:
- docs de fase antiga
- checklists antigos
- migração antiga
- logs temporários
- arquivos duplicados
- README desatualizado

Critério:
- documentação curta
- comandos reais
- sem texto genérico
- sem secrets
- sem instruções inseguras de port forwarding público

============================================================
FASE 12 — TESTES ANTES DE APLICAR
============================================================

No Inspiron:
cd /etc/kryonix

nix flake check --show-trace

Se passar:
sudo nixos-rebuild dry-build --flake .#inspiron --show-trace

Se passar:
sudo nixos-rebuild test --flake .#inspiron --show-trace

Após test:
- rodar auditoria de desktop novamente
- validar apps
- validar brain

Comandos:
command -v flatpak || true
command -v obsidian || true
command -v rag-obsidian || true
command -v kryonix-obsidian || true
command -v code || true
command -v codium || true
command -v WinBox || true
command -v winbox || true
command -v kryonix-launch || true
command -v caelestia || true

/tmp/check-desktop-exec.sh | tee /tmp/desktop-broken-after-test.txt

systemctl --failed
systemctl --user --failed || true
journalctl --user -p 3 -b --no-pager | tail -120

Brain:
source /etc/kryonix/brain.env
kryonix brain health
kryonix brain stats
kryonix brain search "Como funciona o pipeline de RAG do Kryonix?"

Critério:
- nenhum BROKEN relevante
- apps essenciais existem
- Brain funciona
- flake/dry-build/test passaram

============================================================
FASE 13 — APLICAR DEFINITIVO
============================================================

Somente se FASE 12 passou:

sudo nixos-rebuild switch --flake .#inspiron --show-trace

Após switch:
systemctl --failed
systemctl --user --failed || true
/tmp/check-desktop-exec.sh
kryonix brain health
kryonix brain stats

Se necessário reboot:
- apenas se kernel/desktop/session precisar
- anotar generation
- reiniciar
- reconectar
- retestar

============================================================
FASE 14 — TESTE LOCAL PELO USUÁRIO
============================================================

Pedir ao usuário testar localmente no Inspiron:
- abrir launcher
- abrir VSCode/VSCodium
- abrir Obsidian
- abrir Zen/Browser
- abrir WinBox se necessário
- abrir terminal
- abrir file manager
- abrir Caelestia/Celestial Shell
- buscar apps no launcher
- verificar se UWSM para de mostrar missing executable

Se aparecer novo erro:
- copiar texto exato
- voltar para FASE 2.

============================================================
FASE 15 — GIT / COMMITS / PUSH
============================================================

No Glacier e Inspiron, garantir que o remoto está correto.

No repo raiz:
git status
git diff --stat
git submodule status

Se mudou submodule brain:
cd packages/kryonix-brain-lightrag
git status
git add .
git commit -m "fix(search): enforce grounded LightRAG responses with sources"
git push
cd ../..

Se mudou vault:
cd ai/kryonix-vault
git status
git add .
git commit -m "docs(rag): improve Kryonix Brain operational documentation"
git push
cd ../..

No repo raiz:
git status
git add .
git commit -m "fix(inspiron): stabilize desktop apps launcher and AI workstation integration"
git push

Verificar:
git status
git submodule status

Não commitar:
- brain.env
- logs temporários
- secrets
- search outputs temporários
- arquivos de cache

============================================================
FASE 16 — ENTREGA FINAL
============================================================

Responder com:

1. Diagnóstico raiz dos apps quebrados.
2. Quantidade/lista de .desktop quebrados antes.
3. Estratégia escolhida para Flatpak.
4. Correção do VSCode/editor.
5. Correção do Obsidian.
6. Correção do WinBox.
7. Correção do launcher/UWSM.
8. Correção do Hyprland/Caelestia.
9. Modelo de IA escolhido e por quê.
10. Mudanças no LightRAG/API.
11. Exemplo da nova resposta de "pipeline RAG do Kryonix".
12. Documentação removida/arquivada.
13. Documentação criada/refatorada.
14. Resultado do nix flake check.
15. Resultado do dry-build/test/switch.
16. Resultado do check .desktop antes/depois.
17. Resultado do Brain remoto no Inspiron.
18. Commits e pushes.
19. Pendências reais.

DEFINIÇÃO DE PRONTO:
Só declarar pronto se:
- VSCode/editor abre.
- Obsidian abre.
- WinBox não aparece quebrado.
- Flatpak está funcional ou restos removidos.
- Launcher não mostra missing executable.
- UWSM sem erro de desktop entry quebrado.
- Hyprland/Caelestia funcionam.
- Brain remoto funciona no Inspiron.
- /search responde com fontes e grounding.
- Resposta RAG não é genérica.
- nix flake check passa.
- dry-build passa.
- test passa.
- switch passa.
- systemctl --failed sem falhas críticas.
- Git limpo.
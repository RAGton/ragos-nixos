Você está atuando em um host NixOS (Kryonix) rodando em um notebook Dell Inspiron 3583 com:

- CPU: i5-8265U
- RAM: 16GB
- GPU: Intel UHD 620 (integrada) + AMD Radeon R5 M435 (discreta)
- WM: Hyprland (Wayland)
- Objetivo: workstation leve + cliente remoto do Kryonix Brain (Glacier)

PROBLEMA:
O sistema pode estar com uso desnecessário de CPU/GPU/memória devido a:
- GPU dedicada AMD não utilizada corretamente
- carga gráfica do Hyprland
- ausência de tuning de performance
- possíveis processos pesados em background

OBJETIVO:
Otimizar o sistema para:
- máxima responsividade
- menor consumo de recursos
- estabilidade no uso diário
- sem quebrar ambiente gráfico ou apps

============================================================
REGRAS ABSOLUTAS
============================================================

- NÃO quebrar o sistema gráfico (Hyprland)
- NÃO remover pacotes essenciais
- NÃO alterar configuração de rede
- NÃO tocar em rag_storage ou configs do Kryonix Brain
- NÃO executar ações destrutivas sem confirmação
- NÃO fazer mudanças irreversíveis
- SEMPRE validar antes e depois

============================================================
FASE 1 — DIAGNÓSTICO
============================================================

Executar e analisar:

CPU/RAM:
- uptime
- free -h
- top ou htop
- ps -eo pid,ppid,pcpu,pmem,comm,args --sort=-pcpu | head -20
- ps -eo pid,ppid,pcpu,pmem,comm,args --sort=-pmem | head -20

Disco:
- df -h
- verificar uso de /nix, /home e /

GPU:
- lspci -nnk | grep -EA3 "VGA|3D"
- intel_gpu_top (se disponível)
- radeontop (se disponível)

Sessão gráfica:
- echo $XDG_SESSION_TYPE
- echo $XDG_CURRENT_DESKTOP
- processos:
  Hyprland, waybar, obsidian, codium, browsers, rustdesk

Identificar:
- processos que mais consomem CPU
- processos que mais consomem RAM
- uso real de GPU AMD vs Intel
- gargalos óbvios

============================================================
FASE 2 — OTIMIZAÇÃO SEGURA
============================================================

Aplicar melhorias SEM quebrar o sistema:

1. GPU
Se AMD não estiver sendo usada:
- desativar via NixOS:
  boot.blacklistedKernelModules = [ "radeon" "amdgpu" ];
  services.xserver.videoDrivers = [ "intel" ];

2. ZRAM (obrigatório)
Adicionar:

zramSwap = {
  enable = true;
  memoryPercent = 50;
};

3. CPU Governor
Configurar:

powerManagement.cpuFreqGovernor = "ondemand";

(ou performance se necessário)

4. Hyprland tuning
Reduzir impacto:

- desativar ou reduzir animações
- manter funcionalidade

5. Limpeza leve
- remover apenas diretórios temporários seguros (/tmp relacionados a builds)
- NÃO rodar nix-collect-garbage sem necessidade

============================================================
FASE 3 — VALIDAÇÃO
============================================================

Após mudanças:

- nixos-rebuild test
- validar que sessão gráfica continua funcionando
- verificar:

free -h
ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head
df -h

GPU:
- confirmar que Intel está ativa
- confirmar que AMD não está causando conflito

============================================================
FASE 4 — RESULTADO ESPERADO
============================================================

O sistema deve:

- consumir menos CPU em idle
- ter menor uso de RAM/swap
- estar mais responsivo
- não apresentar erros gráficos
- manter todos os apps funcionando

============================================================
ENTREGA FINAL
============================================================

Retornar:

1. Diagnóstico:
   - principais processos consumindo CPU/RAM
   - status da GPU AMD vs Intel
   - uso de memória e disco

2. Alterações feitas:
   - blocos adicionados no configuration.nix ou flake
   - ajustes no Hyprland

3. Validação:
   - resultados antes/depois
   - confirmação de que nada quebrou

4. Conclusão:
   - ganhos obtidos
   - se ainda há gargalos

DEFINIÇÃO DE PRONTO:

Só considerar concluído se:
- sistema está mais leve
- sessão gráfica intacta
- sem erro de GPU
- sem regressão funcional
# Glacier VRAM Profiles & Resource Policy

Este documento descreve a política de gestão de memória de vídeo (VRAM) no host **Glacier**, equipada com uma NVIDIA RTX 4060 (8 GB).

## 🧊 Visão Geral

O Glacier atua como servidor de IA (Ollama/LightRAG) e ocasionalmente como workstation de gaming. Para evitar erros de Out-of-Memory (OOM) e garantir performance, implementamos perfis de VRAM que ajustam o comportamento dos serviços.

## 📊 Perfis Disponíveis

| Perfil | Foco | Mínimo Livre | Comportamento Ollama |
| :--- | :--- | :--- | :--- |
| `ai` | Performance IA | 4096 MiB | Exige GPU limpa para modelos 7B+ |
| `balanced` | Uso Misto | 2048 MiB | Permite desktop leve + IA |
| `gaming` | Latência/GPU | 512 MiB | Ollama é interrompido para liberar GPU |

## 🛠️ Comandos CLI

### 1. Auditoria
Exibe o estado atual da GPU, processos e sessões.
```bash
kryonix brain vram-audit
```

### 2. Verificação
Valida se a VRAM atual atende ao perfil configurado.
```bash
kryonix brain vram-check
```

### 3. Limpeza Segura
Identifica e encerra sessões gráficas órfãs ou inativas que ocupam VRAM.
```bash
# Apenas lista candidatos (safe)
kryonix brain vram-clear --dry-run

# Executa o encerramento (requer confirmação)
kryonix brain vram-clear --confirm
```

### 4. Troca de Perfil (Runtime)
Altera o comportamento dos serviços imediatamente sem alterar a configuração persistente.
```bash
kryonix brain vram-profile gaming --confirm
```

## ⚙️ Configuração Declarativa (NixOS)

Para alterar o perfil padrão permanentemente, edite `hosts/glacier/default.nix`:

```nix
kryonix.services.brain.vram = {
  profile = "balanced"; # ai | balanced | gaming
  warnOnly = false;
};
```

## ⚠️ Regras de Segurança

1. **Proteção de Sessão**: O comando `vram-clear` nunca encerrará a sessão SSH atual ou sessões locais ativas (seat0).
2. **Proteção de Workload**: Processos conhecidos como Steam, Blender ou OBS impedem o encerramento automático da sessão.
3. **Fé no Erro**: O serviço `ollama-vram-check` abortará o início do Ollama se o perfil `ai` ou `balanced` não for atendido, evitando instabilidade do sistema.

## 🚑 Troubleshooting

- **Ollama não inicia**: Verifique `systemctl status ollama-vram-check`. Se falhou, rode `vram-audit` para ver quem está ocupando a GPU.
- **VRAM presa**: Alguns processos do GNOME/Hyprland podem reter VRAM mesmo após fechar janelas. Use `vram-clear --confirm` para limpar sessões inativas.

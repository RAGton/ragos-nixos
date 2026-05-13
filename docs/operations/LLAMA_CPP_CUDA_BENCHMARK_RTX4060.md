# Guia de Benchmark: llama.cpp CUDA vs Ollama (RTX 4060)

Este documento descreve como configurar e executar o backend experimental `llama.cpp` no host Glacier para comparação de performance com o Ollama.

## 1. O que é o llama.cpp sidecar?
É uma instância do `llama-server` compilada nativamente com suporte CUDA (via Nix), rodando em isolamento na porta `11435`. Ele serve para testar se a performance bruta (tokens/s) e a gestão de VRAM são superiores ao Ollama para modelos específicos em formato GGUF.

## 2. Setup Inicial

### 2.1 Habilitar o Serviço
O serviço vem desabilitado por padrão. No `hosts/glacier/default.nix`, configure:

```nix
kryonix.services.llama-cpp = {
  enable = true;
  modelPath = "/var/lib/kryonix/models/qwen2.5-7b-instruct.Q4_K_M.gguf"; # Exemplo
  gpuLayers = -1; # Todas na GPU
};
```

### 2.2 Baixar um Modelo GGUF
O Kryonix não commita arquivos GGUF. Baixe um modelo compatível manualmente:

```bash
sudo mkdir -p /var/lib/kryonix/models
sudo chown -R root:render /var/lib/kryonix/models
sudo chmod 775 /var/lib/kryonix/models

# Exemplo usando huggingface-cli ou wget
cd /var/lib/kryonix/models
sudo wget https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf
```

## 3. Comandos de Operação

Use a CLI `kryonix` para interagir:

### Ver Status
```bash
kryonix brain llama-cpp status
```

### Smoke Test (API)
```bash
kryonix brain llama-cpp smoke
```

### Executar Benchmark
```bash
kryonix brain llama-cpp bench
```

## 4. Comparação A/B (Exemplo de Tabela)

| Métrica | Ollama (v0.x) | llama.cpp (Sidecar) |
| :--- | :--- | :--- |
| **Tokens/s (Qwen2.5 7B)** | ~45 t/s | ? |
| **VRAM Idle** | ~600 MiB | ? |
| **VRAM Load (8k ctx)** | ~5.2 GiB | ? |
| **Latência Primeiro Token** | ~200ms | ? |

## 5. Por que usar o llama.cpp?
- **Controle Total**: Parâmetros granulares como threads, batch size e kv-cache quantization.
- **Sidecar**: Não interfere no daemon de produção do Ollama.
- **Debugging**: Logs do systemd mais detalhados para OOM na GPU.

---
**IMPORTANTE**: Mantenha o serviço desabilitado quando não estiver em benchmark para economizar VRAM para o Brain API principal.

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

## 4. Resultados do Benchmark Controlado (RTX 4060)

| Backend | Modelo | Quantização | Prompt | Cold/Warm | VRAM Antes | VRAM Depois | Tokens/s | Latência Total |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **llama.cpp** | Qwen2.5 7B | Q4_K_M | Short | Cold | 102 MiB | 4805 MiB | **54.44** | 2480ms |
| **llama.cpp** | Qwen2.5 7B | Q4_K_M | Tech | Warm | 4805 MiB | 4805 MiB | **54.66** | 3659ms |
| **llama.cpp** | Qwen2.5 7B | Q4_K_M | Code | Warm | 4805 MiB | 4805 MiB | **54.57** | 3665ms |
| **Ollama** | Qwen2.5 Coder 7B | Q4_0 (approx) | Short | Cold | 102 MiB | 4937 MiB | 38.48 | 3976ms |
| **Ollama** | Qwen2.5 Coder 7B | Q4_0 (approx) | Tech | Warm | 4937 MiB | 4938 MiB | 40.65 | 4920ms |
| **Ollama** | Qwen2.5 Coder 7B | Q4_0 (approx) | Code | Warm | 4938 MiB | 4937 MiB | 40.45 | 4944ms |

### Análise Técnica
O `llama.cpp` demonstrou uma performance consistentemente superior (~35% mais tokens/s) e uma latência total menor. O Ollama, embora tenha melhorado significativamente em relação ao teste anterior, ainda apresenta um overhead de processamento que impacta o throughput final na RTX 4060.

## 5. Por que usar o llama.cpp?
- **Controle Total**: Parâmetros granulares como threads, batch size e kv-cache quantization.
- **Sidecar**: Não interfere no daemon de produção do Ollama.
- **Debugging**: Logs do systemd mais detalhados para OOM na GPU.

---
**IMPORTANTE**: Mantenha o serviço desabilitado quando não estiver em benchmark para economizar VRAM para o Brain API principal.

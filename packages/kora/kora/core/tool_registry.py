from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional

class ToolKind(str, Enum):
    KORA = "kora"
    KRYONIX = "kryonix"
    SYSTEM_READONLY = "system_readonly"
    SYSTEM_ACTION = "system_action"
    BRAIN = "brain"
    MCP = "mcp"

@dataclass
class ToolSpec:
    name: str
    command: List[str]
    description: str
    kind: ToolKind
    risk: str = "read_only"
    requires_confirmation: bool = False
    examples: List[str] = field(default_factory=list)

# Canonical Registry of Real Kryonix/Kora Commands
KRYONIX_TOOLS = [
    # Kora
    ToolSpec(
        name="kora health",
        command=["kora", "health"],
        description="Verifica se a API da Kora está ativa e saudável.",
        kind=ToolKind.KORA,
        risk="read_only"
    ),
    ToolSpec(
        name="kora latency",
        command=["kora", "latency"],
        description="Executa diagnóstico de latência (TTFT/Total) da Kora.",
        kind=ToolKind.KORA,
        risk="read_only"
    ),
    ToolSpec(
        name="kora login",
        command=["kora", "login"],
        description="Sincroniza a KORA_API_KEY do Glacier via SSH.",
        kind=ToolKind.KORA,
        risk="low"
    ),
    ToolSpec(
        name="kora memory status",
        command=["kora", "memory", "status"],
        description="Verifica o status da fila de memória e do vault.",
        kind=ToolKind.KORA,
        risk="read_only"
    ),
    ToolSpec(
        name="kora memory search",
        command=["kora", "memory", "search", "<query>"],
        description="Busca memórias registradas no Obsidian Vault.",
        kind=ToolKind.KORA,
        risk="read_only"
    ),
    ToolSpec(
        name="kora memory recent",
        command=["kora", "memory", "recent"],
        description="Mostra as memórias mais recentes gravadas no Vault.",
        kind=ToolKind.KORA,
        risk="read_only"
    ),
    ToolSpec(
        name="kora memory flush",
        command=["kora", "memory", "flush"],
        description="Processa manualmente a fila de memória pendente.",
        kind=ToolKind.KORA,
        risk="low"
    ),

    # Kryonix Core
    ToolSpec(
        name="kryonix doctor",
        command=["kryonix", "doctor"],
        description="Executa diagnóstico completo do sistema Kryonix.",
        kind=ToolKind.KRYONIX,
        risk="read_only"
    ),
    ToolSpec(
        name="kryonix git-status",
        command=["kryonix", "git-status"],
        description="Mostra o status do repositório git do projeto.",
        kind=ToolKind.KRYONIX,
        risk="read_only"
    ),

    # Brain
    ToolSpec(
        name="kryonix brain health",
        command=["kryonix", "brain", "health"],
        description="Verifica saúde do LightRAG e Neo4j.",
        kind=ToolKind.BRAIN,
        risk="read_only"
    ),
    ToolSpec(
        name="kryonix brain stats",
        command=["kryonix", "brain", "stats"],
        description="Mostra estatísticas de entidades e relações no grafo.",
        kind=ToolKind.BRAIN,
        risk="read_only"
    ),
    ToolSpec(
        name="kryonix brain search",
        command=["kryonix", "brain", "search", "<query>"],
        description="Busca técnica profunda no conhecimento do projeto.",
        kind=ToolKind.BRAIN,
        risk="read_only"
    ),

    # MCP
    ToolSpec(
        name="kryonix mcp check",
        command=["kryonix", "mcp", "check"],
        description="Valida configurações de clientes MCP.",
        kind=ToolKind.MCP,
        risk="read_only"
    ),
    ToolSpec(
        name="kryonix mcp doctor",
        command=["kryonix", "mcp", "doctor"],
        description="Diagnóstico profundo de servidores e ferramentas MCP.",
        kind=ToolKind.MCP,
        risk="read_only"
    ),

    # System
    ToolSpec(
        name="systemctl status",
        command=["systemctl", "status", "<service>"],
        description="Verifica o status de um serviço do sistema.",
        kind=ToolKind.SYSTEM_READONLY,
        risk="read_only"
    ),
    ToolSpec(
        name="ollama ps",
        command=["ollama", "ps"],
        description="Lista modelos de IA carregados na GPU.",
        kind=ToolKind.SYSTEM_READONLY,
        risk="read_only"
    ),
    ToolSpec(
        name="nvidia-smi",
        command=["nvidia-smi"],
        description="Mostra o uso da GPU NVIDIA.",
        kind=ToolKind.SYSTEM_READONLY,
        risk="read_only"
    ),
]

def find_tool(name_or_cmd: str) -> Optional[ToolSpec]:
    """Find a tool by name or partial command."""
    name_or_cmd = name_or_cmd.lower()
    for tool in KRYONIX_TOOLS:
        if tool.name in name_or_cmd or " ".join(tool.command) in name_or_cmd:
            return tool
    return None

def get_registry_summary() -> str:
    """Return a summary of available tools for LLM context."""
    summary = "Registry de comandos reais do Kryonix:\n"
    for tool in KRYONIX_TOOLS:
        summary += f"- {tool.name}: {tool.description}\n"
    return summary

# MCP Client Configurations

Per-server setup guides for integrating MCP servers with Claude, Cursor, and other AI agents.

## Table of Contents

1. [kryonix-brain (LightRAG)](#kryonix-brain-lightrag)
2. [mcp-nixos](#mcp-nixos)
3. [filesystem (Read-only Vault)](#filesystem-read-only-vault)
4. [GitHub](#github)

---

## kryonix-brain (LightRAG)

### Purpose
Server-side knowledge graph + Obsidian vault search. Provides RAG-based synthesis, entity relationships, and document retrieval from Glacier.

### Prerequisites
- SSH access from the client to `glacier`
- On Glacier: Python 3.11+, `uv`, Ollama, Kryonix Brain storage and vault/index
- On clients such as `inspiron`: only `kryonix-cli` and the MCP client config are required

### Configuration

Add to `.mcp.json`:

```json
{
  "mcpServers": {
    "kryonix-brain": {
      "command": "ssh",
      "args": [
        "glacier",
        "cd /etc/kryonix && uv run --project packages/kryonix-brain-lightrag python -m kryonix_brain_lightrag.server"
      ],
      "description": "Kryonix Brain MCP on Glacier"
    }
  }
}
```

### Key Parameters
- `command`: `ssh`
- first arg: SSH host (`glacier`)
- second arg: command executed on Glacier from `/etc/kryonix`

For CLI HTTP integration without MCP stdio forwarding, set:

```bash
export KRYONIX_BRAIN_API=http://glacier:8000
```

### Environment Variables (Optional)
Set server-side variables on Glacier in the runtime environment. On clients, prefer only `KRYONIX_BRAIN_API`.

```bash
# LLM Provider
LIGHTRAG_LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://127.0.0.1:11434
LIGHTRAG_LLM_MODEL=qwen2.5-coder:7b
LIGHTRAG_EMBED_MODEL=nomic-embed-text:latest

# Paths
LIGHTRAG_VAULT_DIR=/ABSOLUTE/PATH/TO/kryonix-vault
LIGHTRAG_WORKING_DIR=/ABSOLUTE/PATH/TO/kryonix-vault/11-LightRAG/rag_storage

# Profiles
LIGHTRAG_PROFILE_NAME=balanced  # safe, balanced, query, quality

# Language
RESPONSE_LANGUAGE=pt-BR

# Client HTTP integration
KRYONIX_BRAIN_API=http://glacier:8000
```

### Available Tools
- `rag_search` — Hybrid search (graph + vector) with LLM synthesis
- `rag_ask` — Alias for `rag_search` with different UX
- `rag_stats` — Knowledge graph statistics (entities, relations, chunks)
- `rag_health` — Server health check (database status)
- `graph_heal` — Identify orphaned entities and suggest connections
- `obsidian_search` — Search vault by tags, titles, content
- `obsidian_read` — Read note content (read-only)
- `obsidian_write` — Append to note (not yet exposed in MCP, requires `brain.env` key)

### Capabilities
- **Multi-hop graph retrieval:** Follows entity relationships up to 2 levels deep
- **Semantic expansion:** Augments queries with related terms
- **LLM synthesis:** Generates answers grounded in retrieved context
- **Portuguese-first:** System prompts in PT-BR by default
- **Obsidian integration:** Indexes all markdown files in vault

### Validation

```bash
# Quick check
kryonix mcp check

# Detailed diagnostics
kryonix mcp doctor | grep kryonix-brain

# Client-side test; local Ollama/storage is not required
kryonix test client
kryonix brain stats --remote

# Server-side test on Glacier
kryonix test server
kryonix brain doctor --local
kryonix graph stats --local
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `Module not found: kryonix_brain_lightrag` | Run `cd packages/kryonix-brain-lightrag && uv sync` |
| Server hangs on startup | Run server checks on Glacier; check `OLLAMA_BASE_URL` there |
| Vault not indexed | On Glacier, run `kryonix brain index --full` to reindex vault |
| Obsidian not mounted | On Glacier, check `LIGHTRAG_VAULT_DIR` path exists and is readable |
| Ollama missing on Inspiron | Expected client state; configure `KRYONIX_BRAIN_API` or SSH MCP to Glacier |
| Portuguese prompts not working | Verify `RESPONSE_LANGUAGE=pt-BR` in `.env` |

---

## mcp-nixos

### Purpose
Query NixOS packages, options, Home Manager, nix-darwin, and flakes. Enables AI agents to research and recommend NixOS configurations.

### Prerequisites
- Python 3.10+ or system package manager
- `uv` package manager: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- (Optional) `nixpkgs` installed locally for faster queries

### Configuration

Add to `.mcp.json`:

```json
{
  "mcpServers": {
    "mcp-nixos": {
      "command": "uvx",
      "args": ["mcp-nixos"],
      "description": "Query NixOS packages, options, Home Manager, nix-darwin, flakes"
    }
  }
}
```

### Key Parameters
- `command`: `uvx` (runs Python package in isolated venv)
- `args`: `["mcp-nixos"]` (package name)
- No `cwd` or `env` needed for basic usage

### Environment Variables (Optional)

```bash
# Cache nixpkgs locally (speeds up queries 10x)
NIX_PATH=nixpkgs=/home/user/.nixpkgs

# Offline mode (no network calls)
MCP_NIXOS_OFFLINE=1
```

### Available Tools
- `search_packages` — Find packages by name/description
- `get_package_info` — Detailed package info (version, description, maintainers, homepage)
- `search_options` — Find NixOS options by name/description
- `get_option_info` — Detailed option info (type, default, description, example)
- `get_home_manager_options` — Search Home Manager options
- `search_flakes` — Search flake inputs in nixpkgs
- `check_package_availability` — Verify package exists on current nixpkgs version

### Capabilities
- **Offline queries:** Works without network (if cached)
- **Multi-channel support:** stable, unstable, nixos-23.11, nixos-24.05, etc.
- **Home Manager database:** 200+ user-level options
- **Performance:** Cached queries return in <100ms

### Examples

```
User: How do I install VSCode in NixOS?
MCP: Let me search...
> search_packages("VSCode")
Result: nixpkgs.vscode, nixpkgs.vscodium

User: What's the latest qemu version?
MCP: > get_package_info("qemu")
Result: qemu 8.2.1 (description, homepage, etc.)

User: Show me Home Manager options for git configuration
MCP: > get_home_manager_options(search="git")
Result: programs.git, services.git-sync, etc.
```

### Validation

```bash
# Check installation
uvx mcp-nixos --version

# Test query
kryonix mcp doctor | grep mcp-nixos
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `uvx: command not found` | Install uv: `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Very slow first query | Normal; first run downloads/caches nixpkgs. Subsequent queries are fast |
| Queries timeout | Check internet connection; try with `MCP_NIXOS_OFFLINE=1` if cached |
| Package not found | Try `search_packages()` first; exact name may differ from search |

---

## filesystem (Read-only Vault)

### Purpose
Safe read-only access to Obsidian vault. Enables AI agents to explore notes, links, and document structure without modification.

### Prerequisites
- Node.js 18+
- `npx` package runner (included with npm)
- Obsidian vault directory (absolute path)

### Configuration

Add to `.mcp.json`:

```json
{
  "mcpServers": {
    "vault-readonly": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/ABSOLUTE/PATH/TO/kryonix-vault"
      ],
      "description": "Read-only access to Obsidian vault"
    }
  }
}
```

### Key Parameters
- `command`: `npx` (Node package runner)
- `args`: Package name (`@modelcontextprotocol/server-filesystem`) + absolute path to vault
- Path must be absolute (e.g., `/home/user/kryonix-vault`, not `~/vault`)
- **CRITICAL:** This server is read-only; modify config to prevent writes

### Important: Read-Only Enforcement

The filesystem MCP server in `.mcp.json` should be read-only. Ensure `args` only includes the vault path:

```json
"args": [
  "-y",
  "@modelcontextprotocol/server-filesystem",
  "/ABSOLUTE/PATH/TO/kryonix-vault"
]
```

This configuration restricts the server to the vault directory ONLY. Additional path arguments could enable write access or system directory traversal — **DO NOT ADD THEM**.

### Available Tools
- `read_file` — Read file content (any format in vault)
- `list_directory` — List files and folders in vault
- `search_files` — Search file names/content via regex
- `get_file_info` — File metadata (size, modified date, etc.)

**Writes are disabled** in the MCP registration.

### Capabilities
- **Vault exploration:** Browse all notes and attachments
- **Link traversal:** Follow `[[links]]` in notes
- **Tag search:** Find all notes with specific tags
- **Full-text search:** Search note content via regex
- **Metadata:** File size, modification date, permissions

### Examples

```
User: Show me all notes in the 02-Areas directory
MCP: > list_directory("/02-Areas")
Result: 
  ├── IA e Agentes/
  ├── Projetos/
  └── Recursos/

User: Search for notes about "MCP"
MCP: > search_files("MCP")
Result:
  02-Areas/IA e Agentes/MCP Architecture.md
  04-Recursos/MCP Setup Guide.md

User: Read the MCP Architecture note
MCP: > read_file("/02-Areas/IA e Agentes/MCP Architecture.md")
Result: [file content...]
```

### Validation

```bash
# Check installation
npx -y @modelcontextprotocol/server-filesystem --help

# Verify path
ls -la /ABSOLUTE/PATH/TO/kryonix-vault

# Test read access
kryonix mcp doctor | grep vault-readonly
```

### Security Rules

**DO NOT** modify the server registration to add write paths or system directories. Examples of DANGEROUS modifications:

```json
// ❌ DANGEROUS: Adds system directory access
"args": ["-y", "@modelcontextprotocol/server-filesystem", "/"]

// ❌ DANGEROUS: Multiple paths including sensitive dirs
"args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user", "/etc"]

// ❌ DANGEROUS: Relative path (could escape via ../)
"args": ["-y", "@modelcontextprotocol/server-filesystem", "../"]
```

**SAFE configuration:**
```json
// ✅ SAFE: Absolute path, vault only
"args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/kryonix-vault"]
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `npx: command not found` | Install Node.js: `node --version` (or `apt install nodejs npm`) |
| "Permission denied" on vault path | Check vault directory permissions: `ls -la /path/to/vault` |
| Path contains spaces | Quote in JSON: `/home/user/my vault` → `/home/user/my vault` (JSON handles escaping) |
| Vault not found | Verify absolute path: `realpath ~/kryonix-vault` |
| "Path traversal denied" | Good! Server is protecting against `..` attacks. Use absolute paths only |

---

## GitHub

### Purpose
Query issues, pull requests, commits, and file content on GitHub. Enables AI agents to understand project state, review PRs, and provide context-aware suggestions.

### Prerequisites
- Node.js 18+
- `npx` package runner
- GitHub Personal Access Token (PAT)

### Configuration

Add to `.mcp.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      },
      "description": "GitHub issues, PRs, commits, file access"
    }
  }
}
```

### Key Parameters
- `command`: `npx`
- `args`: `@modelcontextprotocol/server-github`
- `env.GITHUB_TOKEN`: Personal Access Token (never in JSON file directly; use `.env` or pass as environment variable)

### Creating a GitHub Token

1. Go to https://github.com/settings/tokens/new
2. Select scopes:
   - `repo` (full control of private repos, or `public_repo` for public only)
   - `read:org` (optional, for org member info)
3. Copy token
4. Add to `.env` or `.envrc`:

```bash
# .env
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

5. Load: `source .env` (or `direnv allow` if using `.envrc`)

### Available Tools
- `search_repositories` — Search public/private repos by name/topic
- `get_issue` — Get issue details (title, body, labels, comments)
- `list_issues` — List issues in a repo (open, closed, by label)
- `get_pull_request` — PR details, diff summary, review comments
- `list_pull_requests` — List PRs (open, closed, by author)
- `get_file_content` — Read file from repo (any branch)
- `search_code` — Search file content across repo
- `get_commit_info` — Commit details (message, author, files changed)
- `list_commits` — List commits in branch

### Capabilities
- **Real-time GitHub data:** Issues, PRs, commits, files
- **PR review context:** See diffs, comments, requested reviewers
- **Code search:** Find functions, classes, imports across repo
- **Org context:** Understand team structure and repo relationships
- **Issue tracking:** Search by label, milestone, assignee

### Examples

```
User: Show open PRs for Kryonix
MCP: > list_pull_requests(repo="kryonix", state="open")
Result:
  PR #42: Add MCP support (by user1, 3 days ago)
  PR #45: Fix NixOS freeze (by user2, 2 hours ago)

User: What changed in PR #42?
MCP: > get_pull_request(repo="kryonix", number=42)
Result: Title, description, files changed, review comments

User: Find all references to "MCP" in the codebase
MCP: > search_code(repo="kryonix", query="MCP")
Result: [list of files with MCP references]

User: Show me the latest 5 commits
MCP: > list_commits(repo="kryonix", limit=5)
Result: [commit hashes, messages, authors]
```

### Validation

```bash
# Check token is set
echo $GITHUB_TOKEN | head -c 10}...

# Test GitHub access
kryonix mcp doctor | grep github
```

### Security Rules

- **Token location:** Never put token in `.mcp.json` (it would be in git history if committed)
- **Token scope:** Use minimal scopes (`public_repo` if possible, `repo` if private access needed)
- **Token rotation:** Regenerate token every 90 days
- **Environment:** Load from `.env` or `.envrc`, ensure `.gitignore` protects it
- **Revocation:** Revoke token immediately if leaked: https://github.com/settings/tokens

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `GITHUB_TOKEN not found` | Set in environment: `export GITHUB_TOKEN=ghp_...` or add to `.env` |
| "Unauthorized" errors | Check token is valid: https://github.com/settings/tokens |
| Rate limits hit | GitHub API allows 5000 requests/hour; agent may hit limits on large repos |
| "Repository not found" | Check repo name is correct; may be private (token needs `repo` scope) |
| Slow queries | Search on large repos can timeout; try narrowing search (e.g., file type, language) |

### Token Refresh

When token expires or is revoked:

```bash
# Generate new token at https://github.com/settings/tokens/new
# Update .env
echo "GITHUB_TOKEN=ghp_new_token_here" >> .env

# Reload environment
source .env

# Verify
echo $GITHUB_TOKEN
```

---

## Validation for All Servers

After configuring servers, run:

```bash
./scripts/check-mcp.sh           # Validates all 4
kryonix mcp check                # Brain-specific
kryonix mcp doctor               # Detailed diagnostics
```

All servers should show ✓ (working) or ⚠ (not configured, but no error).

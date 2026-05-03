# BRAIN_SERVER_ARCHITECTURE

## Overview

Kryonix uses a distributed Brain architecture to separate heavy AI workloads from daily workstation tasks.

### Topology

- **Glacier (Server)**:
  - Role: Central Intelligence Server.
  - OS: Windows 11 (Transitioning to NixOS).
  - Services: 
    - Ollama (LLM/Embeddings).
    - Kryonix Brain API (LightRAG wrapper).
    - LightRAG Storage (Knowledge Graph).
    - Obsidian Vault (Source of truth).
    - MCP (Model Context Protocol) Server.
  - Connectivity: Fixed Tailscale IP `100.108.71.36`.

- **Inspiron (Client)**:
  - Role: Daily Workstation.
  - OS: NixOS.
  - Services:
    - Kryonix CLI (Brain Client).
    - Desktop (Hyprland/Caelestia).
  - Connectivity: Accesses Glacier via Tailscale.

## Service Map

### Brain API
- **Endpoint**: `http://100.108.71.36:8000`
- **Auth**: `X-API-Key` (Environment variable `KRYONIX_BRAIN_KEY`).
- **Endpoints**:
  - `/health`: System health and storage status.
  - `/stats`: Graph metrics (entities, relations, docs).
  - `/search`: RAG query with sources and grounding.

### Ollama
- **Endpoint**: `http://100.108.71.36:11434`
- **Primary Models**:
  - LLM: `qwen2.5-coder:7b` (High quality) / `qwen2.5-coder:3b` (Fast).
  - Embedding: `nomic-embed-text:latest`.

## Storage & Persistence

- **Location**: `/home/rocha/Documents/kryonix-vault/11-LightRAG/rag_storage` (on Glacier).
- **Format**: LightRAG Knowledge Graph (JSON/Parquet/Vectors).
- **Integrity**: Validated via `kryonix brain stats` and `kryonix brain doctor`.

## Security

- **Network**: All cross-host communication MUST go through Tailscale.
- **Secrets**: `KRYONIX_BRAIN_KEY` must never be committed to Git. It is managed via `brain.env` (Inspiron) and Windows Environment Variables (Glacier).

## Operational Workflow

1. **Indexing**: Glacier indexes the repository and Vault.
2. **Persistence**: Storage is backed up locally before major changes.
3. **Consumption**: Inspiron queries the API via CLI or integrated apps (Obsidian).
4. **Validation**: Both nodes run periodic health checks to ensure connectivity and graph consistency.

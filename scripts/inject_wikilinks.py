import os
import re
import json
import networkx as nx
from pathlib import Path
import hashlib

# Paths
BRAIN_HOME = Path("/home/rocha/.local/share/kryonix/kryonix-vault")
VAULT_DIR = BRAIN_HOME / "vault"
STORAGE_DIR = BRAIN_HOME / "storage"
GRAPHML_PATH = STORAGE_DIR / "graph_chunk_entity_relation.graphml"
DOC_STATUS_PATH = STORAGE_DIR / "kv_store_doc_status.json"
ENTITY_CHUNKS_PATH = STORAGE_DIR / "kv_store_entity_chunks.json"

# Regex for [[Wikilinks]]
WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

def inject_wikilink_graph():
    print(f"Reading vault and doc status...")
    
    # 1. Load doc status to map filenames to chunks
    with open(DOC_STATUS_PATH, 'r') as f:
        doc_status = json.load(f)
    
    file_to_chunks = {}
    for doc_id, data in doc_status.items():
        rel_path = data.get("file_path", "")
        chunks = data.get("chunks_list", [])
        if rel_path and chunks:
            # Map by stem (filename without extension)
            stem = Path(rel_path).stem
            file_to_chunks[stem] = chunks

    # 2. Collect all links from markdown
    nodes = {} # name -> {desc, chunks}
    edges = [] # (u, v)
    
    for md_file in VAULT_DIR.rglob("*.md"):
        source_name = md_file.stem
        content = md_file.read_text(errors="ignore")
        
        # Simple description
        first_line = content.split('\n')[0].strip('# ')
        chunks = file_to_chunks.get(source_name, [])
        
        nodes[source_name] = {
            "description": f"Note: {source_name}. {first_line}",
            "chunks": chunks,
            "file_path": str(md_file.relative_to(VAULT_DIR))
        }
        
        links = WIKILINK_RE.findall(content)
        for target in links:
            target = target.strip()
            if target not in nodes:
                nodes[target] = {
                    "description": f"Referenced entity: {target}",
                    "chunks": file_to_chunks.get(target, []),
                    "file_path": ""
                }
            edges.append((source_name, target))

    print(f"Found {len(nodes)} entities and {len(edges)} relations.")

    # 3. Build graph
    G = nx.MultiDiGraph()
    entity_chunks_kv = {}
    
    for name, data in nodes.items():
        source_id = "<SEP>".join(data["chunks"]) if data["chunks"] else "manual_injection"
        G.add_node(name, 
                   entity_type="Concept", 
                   description=data["description"], 
                   source_id=source_id,
                   file_path=data["file_path"])
        
        # Update entity_chunks KV
        if data["chunks"]:
            entity_chunks_kv[name] = data["chunks"]

    for u, v in edges:
        G.add_edge(u, v, 
                   weight=1.0, 
                   description="Semantic link extracted from Obsidian Wikilinks", 
                   source_id="wikilink_injector", 
                   keywords="wikilink,canonical")

    # 4. Save GraphML
    nx.write_graphml(G, GRAPHML_PATH)
    print(f"Graph REPAIRED: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges.")

    # 5. Save entity_chunks KV
    with open(ENTITY_CHUNKS_PATH, 'w') as f:
        json.dump(entity_chunks_kv, f, indent=2)
    print(f"Updated entity_chunks KV with {len(entity_chunks_kv)} entries.")

    # 6. Clear full entities/relations to avoid inconsistency
    with open(STORAGE_DIR / "kv_store_full_entities.json", 'w') as f: json.dump({}, f)
    with open(STORAGE_DIR / "kv_store_full_relations.json", 'w') as f: json.dump({}, f)

if __name__ == "__main__":
    inject_wikilink_graph()

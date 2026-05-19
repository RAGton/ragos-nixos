"""
KnowledgeResearcher — proposes knowledge-graph enrichment from local file search.

Security model (Human-in-the-Loop)
------------------------------------
This agent NEVER writes directly to Neo4j.  Every proposed triple is staged to:
    KORA_DATA_DIR/knowledge_staging/{uuid}.json   (status="pending_review")

The ONLY write path to Neo4j is apply_staged_triple(), which enforces:
  1. staged.status == "approved"  (set by a human reviewer or /kora review CLI)
  2. validate_triple_schema() passes (whitelist + regex)
  3. Parameterised MERGE Cypher — zero string concatenation except the
     relationship type, which is validated against ALLOWED_PREDICATES before use.
"""
from __future__ import annotations

import asyncio
import json
import logging
import re
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from ..core.config import KORA_DATA_DIR

logger = logging.getLogger("kora.agents.researcher")

# ── Paths ─────────────────────────────────────────────────────────────────────

_STAGING_DIR = KORA_DATA_DIR / "knowledge_staging"

# ── Schema constants ──────────────────────────────────────────────────────────

ALLOWED_PREDICATES: frozenset[str] = frozenset({
    "DEPENDS_ON", "RELATES_TO", "PART_OF", "USES",
    "CONFIGURES", "MANAGES", "INTEGRATES_WITH",
    "RUNS_ON", "PRODUCED_BY", "EXTENDS",
})

_ID_RE = re.compile(r"^[a-zA-Z0-9_\-\.]+$")
_MAX_DESC_LEN = 1000

# Parameterised MERGE template.  {predicate} is substituted only after
# validate_triple_schema() confirms it is in ALLOWED_PREDICATES ([A-Z_]+).
_CYPHER_MERGE_TMPL = (
    "MERGE (a {{id: $subject_id}}) "
    "SET a.entity_type = $subject_type "
    "MERGE (b {{id: $object_id}}) "
    "SET b.entity_type = $object_type "
    "MERGE (a)-[r:{predicate}]->(b) "
    "SET r.description = $description, r.source_query = $source_query "
    "RETURN a.id AS subject, b.id AS object"
)


# ── Data classes ──────────────────────────────────────────────────────────────

@dataclass
class GraphTriple:
    """One proposed knowledge-graph relationship."""
    subject_id: str
    subject_type: str
    predicate: str
    object_id: str
    object_type: str
    description: str
    source_query: str = ""
    source_files: list[str] = field(default_factory=list)


@dataclass
class StagedTriple:
    """A GraphTriple persisted to disk awaiting human review."""
    triple_id: str
    triple: GraphTriple
    status: str   # "pending_review" | "approved" | "rejected"
    created_at: str


# ── Schema validation ─────────────────────────────────────────────────────────

class SchemaValidationError(ValueError):
    """Triple violates the allowed schema."""


def validate_triple_schema(triple: GraphTriple) -> None:
    """
    Raise SchemaValidationError if triple violates allowed schema.
    Called before staging AND before every Neo4j write.
    """
    errors: list[str] = []

    if not _ID_RE.match(triple.subject_id):
        errors.append(f"subject_id '{triple.subject_id}' contains invalid characters")
    if not _ID_RE.match(triple.object_id):
        errors.append(f"object_id '{triple.object_id}' contains invalid characters")

    if triple.predicate not in ALLOWED_PREDICATES:
        errors.append(
            f"predicate '{triple.predicate}' not in allowed set "
            f"({', '.join(sorted(ALLOWED_PREDICATES))})"
        )

    if len(triple.description) > _MAX_DESC_LEN:
        errors.append(
            f"description exceeds {_MAX_DESC_LEN} characters ({len(triple.description)})"
        )

    for attr in ("subject_type", "object_type"):
        if not getattr(triple, attr, "").strip():
            errors.append(f"{attr} must not be empty")

    if errors:
        raise SchemaValidationError("; ".join(errors))


# ── HitL-gated Neo4j write ────────────────────────────────────────────────────

async def apply_staged_triple(staged: StagedTriple, driver: Any) -> str:
    """
    ONLY Neo4j write path for researcher-proposed triples.

    Both conditions must hold before any write occurs:
      1. staged.status == "approved"
      2. triple passes validate_triple_schema()

    Returns triple_id on success.
    Raises RuntimeError (status check) or SchemaValidationError (schema check).
    """
    if staged.status != "approved":
        raise RuntimeError(
            f"Triple {staged.triple_id} has status='{staged.status}', not 'approved'. "
            "Human approval is required before writing to Neo4j."
        )

    validate_triple_schema(staged.triple)  # raises SchemaValidationError if invalid

    t = staged.triple
    # Predicate is validated above — safe to embed in query string.
    cypher = _CYPHER_MERGE_TMPL.format(predicate=t.predicate)
    params = {
        "subject_id":   t.subject_id,
        "subject_type": t.subject_type,
        "object_id":    t.object_id,
        "object_type":  t.object_type,
        "description":  t.description,
        "source_query": t.source_query,
    }
    async with driver.session() as session:
        await session.run(cypher, params)

    logger.info(
        "Applied staged triple %s: (%s)-[%s]->(%s)",
        staged.triple_id, t.subject_id, t.predicate, t.object_id,
    )
    return staged.triple_id


# ── KnowledgeResearcher ───────────────────────────────────────────────────────

class KnowledgeResearcher:
    """
    Searches local files for evidence related to a failed query and proposes
    a StagedTriple (status=pending_review) for human review.
    Never writes to Neo4j directly.
    """

    def __init__(self, search_dirs: list[Path] | None = None) -> None:
        default_dirs = [
            KORA_DATA_DIR,
            Path("/etc/kryonix/docs"),
            Path("/etc/kryonix/.agents"),
        ]
        self._search_dirs = search_dirs if search_dirs is not None else [
            d for d in default_dirs if d.exists()
        ]

    async def research_and_stage(
        self,
        failure: Any,  # FailureRecord from auditor — avoid circular import
    ) -> StagedTriple | None:
        """
        Search local files for context about the failed query.
        Returns a StagedTriple (status=pending_review) or None if no evidence found.
        Does NOT write to Neo4j.
        """
        snippets = await asyncio.to_thread(self._search_local, failure.query)
        if not snippets:
            logger.debug("No local evidence found for query: %s", failure.query[:80])
            return None

        triple = self._propose_triple(failure, snippets)
        if triple is None:
            return None

        try:
            validate_triple_schema(triple)
        except SchemaValidationError as exc:
            logger.warning("Proposed triple failed schema validation: %s", exc)
            return None

        return await asyncio.to_thread(self._stage_triple, triple)

    # ── Local file search ────────────────────────────────────────────────────

    def _search_local(self, query: str) -> list[dict[str, str]]:
        """
        Keyword search over .md, .nix, .py, .json, .yaml, .toml files.
        Returns list of {file, snippet} dicts (max 5).
        """
        keywords = [w.lower() for w in query.split() if len(w) > 3]
        if not keywords:
            return []

        results: list[dict[str, str]] = []
        extensions = {".md", ".nix", ".py", ".json", ".yaml", ".toml"}
        probe_keywords = keywords[:3]

        for base_dir in self._search_dirs:
            for path in base_dir.rglob("*"):
                if path.suffix not in extensions or not path.is_file():
                    continue
                try:
                    text = path.read_text(encoding="utf-8", errors="ignore")
                    if not all(kw in text.lower() for kw in probe_keywords):
                        continue
                    for line in text.splitlines():
                        if any(kw in line.lower() for kw in keywords):
                            results.append({
                                "file":    str(path),
                                "snippet": line.strip()[:200],
                            })
                            break
                    if len(results) >= 5:
                        return results
                except Exception:
                    continue

        return results

    def _propose_triple(
        self,
        failure: Any,
        snippets: list[dict[str, str]],
    ) -> GraphTriple | None:
        """
        Heuristically build a GraphTriple from failure context and file evidence.
        Returns None if there is not enough signal.
        """
        words = [w for w in failure.query.split() if len(w) > 3]
        if len(words) < 2:
            return None

        subject_id = re.sub(r"[^a-zA-Z0-9_\-\.]", "_", words[0].lower())
        object_id  = re.sub(r"[^a-zA-Z0-9_\-\.]", "_", words[-1].lower())

        if subject_id == object_id:
            return None

        description = "; ".join(s["snippet"] for s in snippets[:2])[:_MAX_DESC_LEN]
        source_files = [s["file"] for s in snippets[:3]]

        return GraphTriple(
            subject_id=subject_id,
            subject_type="concept",
            predicate="RELATES_TO",
            object_id=object_id,
            object_type="concept",
            description=description,
            source_query=failure.query[:200],
            source_files=source_files,
        )

    # ── Staging ──────────────────────────────────────────────────────────────

    def _stage_triple(self, triple: GraphTriple) -> StagedTriple:
        """Write triple to staging dir with status=pending_review."""
        _STAGING_DIR.mkdir(parents=True, exist_ok=True)
        triple_id = str(uuid.uuid4())
        staged = StagedTriple(
            triple_id=triple_id,
            triple=triple,
            status="pending_review",
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        payload = {
            "triple_id":  staged.triple_id,
            "status":     staged.status,
            "created_at": staged.created_at,
            "triple": {
                "subject_id":   triple.subject_id,
                "subject_type": triple.subject_type,
                "predicate":    triple.predicate,
                "object_id":    triple.object_id,
                "object_type":  triple.object_type,
                "description":  triple.description,
                "source_query": triple.source_query,
                "source_files": triple.source_files,
            },
        }
        path = _STAGING_DIR / f"{triple_id}.json"
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        logger.info(
            "Staged triple %s (pending_review): (%s)-[%s]->(%s)",
            triple_id, triple.subject_id, triple.predicate, triple.object_id,
        )
        return staged

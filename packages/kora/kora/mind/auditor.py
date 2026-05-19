"""
ThoughtAuditor — surfaces persistent reasoning failures for self-healing.

Reads KORA_DATA_DIR/thoughts/*.json (written by MindConstructor._save_thought).
A thought is a failure when plan.confidence < threshold OR critique.approved==False.
get_frequent_failures() returns recurring failures that are candidates for
knowledge-graph enrichment via KnowledgeResearcher.

This module is read-only — it never writes to disk or Neo4j.
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from ..core.config import KORA_DATA_DIR

logger = logging.getLogger("kora.mind.auditor")

_THOUGHTS_DIR = KORA_DATA_DIR / "thoughts"


@dataclass
class FailureRecord:
    query: str
    failure_count: int
    sessions: list[str] = field(default_factory=list)
    avg_confidence: float = 0.0
    missing_points: list[str] = field(default_factory=list)


class ThoughtAuditor:
    """
    Reads persisted thought records and surfaces frequently failing queries.
    Read-only — never writes to disk or Neo4j.
    """

    def __init__(self, thoughts_dir: Path | None = None) -> None:
        self._dir = thoughts_dir or _THOUGHTS_DIR

    def load_thoughts(self) -> list[dict[str, Any]]:
        """Load all thought records from disk. Returns [] on any error."""
        if not self._dir.exists():
            return []
        records: list[dict[str, Any]] = []
        for path in sorted(self._dir.glob("*.json")):
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
                records.append(data)
            except Exception as exc:
                logger.debug("Skipping malformed thought file %s: %s", path.name, exc)
        return records

    def get_frequent_failures(
        self,
        confidence_threshold: float = 0.65,
        min_occurrences: int = 2,
    ) -> list[FailureRecord]:
        """
        Return queries that repeatedly produced low-confidence or rejected plans.

        A thought is a failure when:
          - plan.confidence < confidence_threshold, OR
          - critique.approved == False
        """
        buckets: dict[str, list[dict[str, Any]]] = {}

        for record in self.load_thoughts():
            query = record.get("query", "").strip()
            if not query:
                continue

            plan = record.get("plan", {})
            critique = record.get("critique", {})
            confidence = float(plan.get("confidence", 1.0))
            approved = critique.get("approved", True)

            if confidence >= confidence_threshold and approved:
                continue

            buckets.setdefault(query, []).append(record)

        result: list[FailureRecord] = []
        for query, records in buckets.items():
            if len(records) < min_occurrences:
                continue

            confidences = [float(r.get("plan", {}).get("confidence", 0.5)) for r in records]
            missing: list[str] = []
            for r in records:
                missing.extend(r.get("critique", {}).get("missing_points", []))
            sessions = [r["session_id"] for r in records if r.get("session_id")]

            result.append(FailureRecord(
                query=query,
                failure_count=len(records),
                sessions=sessions,
                avg_confidence=sum(confidences) / len(confidences),
                # Deduplicate missing points, capped at 10
                missing_points=list(dict.fromkeys(missing))[:10],
            ))

        return sorted(result, key=lambda r: r.failure_count, reverse=True)

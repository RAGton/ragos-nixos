import json
import os
import logging
from typing import List, Optional
from pathlib import Path
from .models import MemoryCandidate

logger = logging.getLogger(__name__)

class MemoryQueue:
    def __init__(self, queue_path: Optional[str] = None):
        if queue_path:
            self.queue_path = Path(queue_path)
        else:
            default_path = os.getenv("KORA_MEMORY_QUEUE", "/var/lib/kryonix/kora/memory/queue.jsonl")
            self.queue_path = Path(default_path)
            
        # Ensure directory exists
        self.queue_path.parent.mkdir(parents=True, exist_ok=True)

    def push(self, candidate: MemoryCandidate):
        """Add a candidate to the queue."""
        try:
            with open(self.queue_path, "a") as f:
                # Convert to dict and handle datetime
                data = candidate.model_dump()
                data["created_at"] = data["created_at"].isoformat()
                f.write(json.dumps(data) + "\n")
            logger.info("Memory candidate pushed to queue: %s", candidate.title)
        except Exception as e:
            logger.error("Failed to push memory candidate: %s", e)

    def pop_all(self) -> List[MemoryCandidate]:
        """Get all items and clear the queue."""
        if not self.queue_path.exists():
            return []

        items = []
        try:
            with open(self.queue_path, "r") as f:
                for line in f:
                    if line.strip():
                        data = json.loads(line)
                        items.append(MemoryCandidate(**data))
            
            # Clear queue
            self.queue_path.unlink()
            return items
        except Exception as e:
            logger.error("Failed to pop memory queue: %s", e)
            return []

    def get_status(self) -> dict:
        """Get queue stats."""
        count = 0
        exists = self.queue_path.exists()
        
        if exists:
            try:
                with open(self.queue_path, "r") as f:
                    count = sum(1 for line in f if line.strip())
            except Exception:
                return {
                    "state": "error",
                    "pending_items": 0,
                    "queue_path": str(self.queue_path)
                }

        state = "pending" if count > 0 else ("empty" if exists else "missing")
        
        return {
            "state": state,
            "pending_items": count,
            "queue_path": str(self.queue_path)
        }

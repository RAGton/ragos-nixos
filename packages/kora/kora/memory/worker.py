import time
import logging
from typing import Optional
from .queue import MemoryQueue
from .obsidian import ObsidianWriter

logger = logging.getLogger(__name__)

class MemoryWorker:
    def __init__(self, queue_path: Optional[str] = None, vault_dir: Optional[str] = None):
        self.queue = MemoryQueue(queue_path)
        self.writer = ObsidianWriter(vault_dir)

    def run_once(self):
        """Process all pending items in the queue."""
        candidates = self.queue.pop_all()
        if not candidates:
            return 0
        
        count = 0
        for candidate in candidates:
            try:
                self.writer.write(candidate)
                count += 1
            except Exception as e:
                logger.error("Worker failed to process candidate %s: %s", candidate.title, e)
                # If it failed, we could re-push it to the queue, but for now we just log
        
        return count

    def run_loop(self, interval: int = 60):
        """Run the worker in a loop."""
        logger.info("Memory worker started (interval: %ds)", interval)
        try:
            while True:
                count = self.run_once()
                if count > 0:
                    logger.info("Worker processed %d items", count)
                time.sleep(interval)
        except KeyboardInterrupt:
            logger.info("Memory worker stopped")

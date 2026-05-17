import sys
import logging
logging.basicConfig(level=logging.INFO)
from kora.voice.wakeword import get_wakeword_status, KoraWakeWord

print("Wake-word Status:", get_wakeword_status())
try:
    import openwakeword
    print("openwakeword is loaded successfully.")
except ImportError:
    print("openwakeword is NOT loaded.")


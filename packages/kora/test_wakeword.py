import sys
import logging
logging.basicConfig(level=logging.INFO)
from kora.voice.wakeword import KoraWakeWord, get_wakeword_status

print(get_wakeword_status())
ww = KoraWakeWord()
ww.start()
print("WakeWord active:", ww.active)
print("WakeWord ready:", ww.ready)

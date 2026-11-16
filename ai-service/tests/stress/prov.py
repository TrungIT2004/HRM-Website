import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(r"C:\Users\ad\Desktop\HRM\ai-service")))
from dotenv import load_dotenv

load_dotenv()
from src.chat.chat_service import ChatService

svc = ChatService()
PROMPT = "dummy system"


def one(i):
    t0 = time.time()
    out = svc._llm_complete(
        "Ban viet lai cau hoi.",
        f"Cau hoi {i}: Ai duyet dang ky xe cong tac trong cong ty?",
        tag=f"probe{i}")
    return (time.time() - t0, len(out or ""))


for n in (1, 5):
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=n) as ex:
        res = list(ex.map(one, range(5 if n > 1 else 1)))
    wall = time.time() - t0
    dts = [round(d, 1) for d, _ in res]
    # ponytail: wall ~= max(dts) -> overlap tot (provider song song);
    # wall ~= sum(dts) -> provider xep hang theo key.
    open(r"C:\Users\ad\AppData\Local\Temp\opencode\prov.txt", "a", encoding="utf-8").write(
        f"n={n} wall={wall:.1f}s dts={dts}\n")
print("ok")

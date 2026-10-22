"""Do leak that end-to-end: 30 cau am qua POST /chat/query (moi cau conv moi).

Chay (cwd=ai-service): py -X utf8 tests/eval_neg_leak.py
Dung de gate moi lan doi threshold/embedder: leak = cau am DUOC dap (co the bia).
"""
import json
import sys
import time
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dotenv import load_dotenv  # noqa: E402

load_dotenv()
from fastapi.testclient import TestClient  # noqa: E402

from main import app, INTERNAL_API_SECRET  # noqa: E402
from src.chat.chat_service import _NO_INFO_MARKERS  # noqa: E402

HERE = Path(__file__).resolve().parent
NEGS = json.load(open(HERE / "calib_neg_20new.json", encoding="utf-8"))
USER = "35337165-e0d0-4dd1-9c67-cc48180363af"
client = TestClient(app)
leaked = []
for q in NEGS:
    t0 = time.time()
    r = client.post("/api/v1/chat/query", headers={"X-Internal-Secret": INTERNAL_API_SECRET},
                    json={"question": q, "user_id": USER, "user_jobs": ["ALL"],
                          "department": "ALL", "top_k": 3})
    r.raise_for_status()
    b = r.json()
    ans = b.get("answer", "")
    refused = any(m in ans.lower() for m in _NO_INFO_MARKERS)
    if not refused:
        leaked.append((q, ans[:220], [c.get("document_name", "?")[:40] for c in (b.get("citations") or [])]))
    print(("LEAK " if not refused else "ok   ") + "%.1fs %s" % (time.time() - t0, q[:55]))
print(f"\nLEAK {len(leaked)}/{len(NEGS)}:")
for q, a, c in leaked:
    print("-", q[:60], "\n   ", a.replace("\n", " "), "\n   cite:", c)

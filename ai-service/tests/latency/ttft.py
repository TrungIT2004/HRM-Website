import sys
import time
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(r"C:\Users\ad\Desktop\HRM\ai-service")))
from dotenv import load_dotenv

load_dotenv()
from fastapi.testclient import TestClient
from main import app, INTERNAL_API_SECRET
from src.db.session import get_db_connection

conn = get_db_connection()
cur = conn.cursor()
cur.execute("DELETE FROM semantic_cache;")
cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
            "(SELECT id FROM chat_conversations WHERE user_id='TTFT');")
cur.execute("DELETE FROM chat_conversations WHERE user_id='TTFT';")
conn.commit()
cur.close()
conn.close()

client = TestClient(app)
H = {"X-Internal-Secret": INTERNAL_API_SECRET}
t0 = time.time()
first_at, n_tok, chars = None, 0, 0
with client.stream("POST", "/api/v1/chat/stream", headers=H, json={
        "question": "Ai duyệt đăng ký xe công tác?",
        "user_id": "TTFT", "user_jobs": ["ALL"],
        "department": "ALL", "top_k": 3}) as resp:
    for line in resp.iter_lines():
        s = line.strip() if isinstance(line, str) else line.decode().strip()
        if not s.startswith("data: "):
            continue
        try:
            import json as J
            ev = J.loads(s[6:])
        except Exception:
            continue
        if ev.get("type") == "token":
            n_tok += 1
            chars += len(ev.get("content", ""))
            if first_at is None:
                first_at = time.time() - t0
total = time.time() - t0
decode_s = total - (first_at or total)
open(r"C:\Users\ad\AppData\Local\Temp\opencode\ttft.txt", "w", encoding="utf-8").write(
    f"total={total:.1f}s TTFT~prefill={first_at:.1f}s decode_tokens={n_tok} "
    f"decode_time={decode_s:.1f}s tok_per_s={n_tok/max(decode_s,0.01):.1f} answer_chars={chars}")
print("ok")

conn = get_db_connection()
cur = conn.cursor()
cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
            "(SELECT id FROM chat_conversations WHERE user_id='TTFT');")
cur.execute("DELETE FROM chat_conversations WHERE user_id='TTFT';")
cur.execute("DELETE FROM semantic_cache;")
conn.commit()
cur.close()
conn.close()

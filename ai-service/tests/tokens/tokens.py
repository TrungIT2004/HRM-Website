"""#3: dem token/turn bang monkeypatch _llm_complete (KHONG sua prod code).
Chay 10 cau doc that, ghi chars in/out moi LLM call -> tokens est (VI ~2-4 char/token).
Chay: py TEMP/tokens.py
"""
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
import src.chat.chat_service as cs

CALLS = []
_orig = cs.ChatService._llm_complete


def spy(self, system_content, user_content, tag=""):
    t0 = time.time()
    out = _orig(self, system_content, user_content, tag)
    CALLS.append({"tag": tag, "in_chars": len(system_content or "") + len(user_content or ""),
                  "out_chars": len(out or ""), "dt": round(time.time() - t0, 2)})
    return out


cs.ChatService._llm_complete = spy
client = TestClient(app)
H = {"X-Internal-Secret": INTERNAL_API_SECRET}

QS = [
    "Người lao động được nghỉ lễ, tết hưởng nguyên lương vào những ngày nào?",
    "Tuổi nghỉ hưu của lao động nam trong điều kiện bình thường là bao nhiêu?",
    "Làm thế nào để yêu cầu cấp văn phòng phẩm?",
    "Ai duyệt đăng ký xe công tác?",
    "Phụ cấp ăn trưa của tôi là bao nhiêu?",
    "Tôi còn bao nhiêu ngày phép?",
    "Quy chế MWG áp dụng cho ai?",
    "Mức phạt đi muộn 15 phút là bao nhiêu?",
    "Cổ đông lớn là gì?",
    "Bảng lương lưu ở đâu?",
]

for i, q in enumerate(QS):
    CALLS.clear()
    r = client.post("/api/v1/chat/query", headers=H, json={
            "question": q, "user_id": "35337165-e0d0-4dd1-9c67-cc48180363af", "user_jobs": ["ALL"],
        "department": "ALL", "top_k": 3})
    b = r.json()
    tin = sum(c["in_chars"] for c in CALLS)
    tout = sum(c["out_chars"] for c in CALLS)
    # ponytail: est tho, tieng Viet ~2-4 char/token tuy provider. Tran de tinh tien.
    print(f"q{i+1}: llm_calls={len(CALLS)} in_chars={tin} out_chars={tout} "
          f"tok_est={tin//4 + tout//4}-{tin//2 + tout//2} "
          f"tags={[c['tag'] for c in CALLS]} answer_chars={len(b.get('answer',''))}")

from src.db.session import get_db_connection
conn = get_db_connection()
cur = conn.cursor()
cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
            "(SELECT id FROM chat_conversations WHERE user_id='35337165-e0d0-4dd1-9c67-cc48180363af');")
cur.execute("DELETE FROM chat_conversations WHERE user_id='35337165-e0d0-4dd1-9c67-cc48180363af';")
cur.execute("DELETE FROM semantic_cache;")
conn.commit()
cur.close()
conn.close()
print("cleanup done")

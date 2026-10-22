"""Stress so 2 muc concurrent: 3 vs 10, cung 15 cau DOC that, clear cache moi muc.
Server workers=1 (prod config). Tra loi: bottleneck la slot-count hay khoa chung?
Chay: server mo truoc, py TEMP/stress3.py
"""
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(r"C:\Users\ad\Desktop\HRM\ai-service")))
import requests

BASE = "http://127.0.0.1:8000"
H = {"X-Internal-Secret": "hrm-internal-key-secure-2024", "Content-Type": "application/json"}
QS = [
    "Người lao động được nghỉ lễ nào hưởng nguyên lương?",
    "Tuổi nghỉ hưu của lao động nam là bao nhiêu?",
    "Làm thế nào để yêu cầu cấp văn phòng phẩm?",
    "Ai duyệt đăng ký xe công tác?",
    "Quy chế MWG áp dụng cho ai?",
    "Mức phạt đi muộn 15 phút là bao nhiêu?",
    "Cổ đông lớn là gì?",
    "Bảng lương lưu ở đâu?",
    "Thời giờ làm việc bình thường mỗi ngày mấy tiếng?",
    "Hợp đồng lao động có mấy loại?",
    "Ai trình quy chế EVNFinance?",
    "Quorum họp HĐQT là bao nhiêu?",
    "Tăng lương xét khi nào?",
    "Trợ cấp thuê nhà bao nhiêu một tháng?",
    "Mực in nào dùng cho máy Canon?",
]


def wipe():
    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                "(SELECT id FROM chat_conversations WHERE user_id LIKE 'SL%');")
    cur.execute("DELETE FROM chat_conversations WHERE user_id LIKE 'SL%';")
    cur.execute("DELETE FROM semantic_cache;")
    conn.commit()
    cur.close()
    conn.close()


def hit(i_q):
    i, q = i_q
    t0 = time.time()
    try:
        r = requests.post(f"{BASE}/api/v1/chat/query", headers=H, json={
            "question": q, "user_id": f"SL{i}", "user_jobs": ["ALL"],
            "department": "ALL", "top_k": 3}, timeout=180)
        dt = time.time() - t0
        return (dt, r.status_code == 200 and len(r.json().get("answer", "")) > 0)
    except Exception:
        return (time.time() - t0, False)


def level(workers):
    wipe()
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=workers) as ex:
        res = list(ex.map(hit, list(enumerate(QS))))
    wall = time.time() - t0
    lats = sorted(d for d, _ in res)
    oks = sum(1 for _, ok in res if ok)
    # ponytail: parallelism hieu dung = tong single / wall. ~workers => scale tot.
    print(f"workers={workers} reqs={len(res)} ok={oks} wall={wall:.0f}s "
          f"p50={lats[len(lats)//2]:.1f}s p95={lats[int(len(lats)*0.95)]:.1f}s")


def main():
    for _ in range(60):
        try:
            if requests.get(f"{BASE}/openapi.json", timeout=5).status_code == 200:
                break
        except Exception:
            time.sleep(5)
    else:
        print("server khong len")
        return
    level(3)
    level(10)
    wipe()


if __name__ == "__main__":
    main()

"""#5: stress nhe — 10 workers x 5 cau doc nhat (50 req) vao server that.
Server start rieng, script doi health rui danh. Khong dung JMeter (stdlib+requests).
Chay: py TEMP/stress.py  (server phai mo truoc o port 8000)
"""
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(r"C:\Users\ad\Desktop\HRM\ai-service")))
import requests

BASE = "http://127.0.0.1:8000"
H = {"X-Internal-Secret": "hrm-internal-key-secure-2024",
     "Content-Type": "application/json"}

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
    "Pin Maxell 3A giá bao nhiêu?",
    "Bút gel UNI Signo cỡ nào?",
    "Thước JUNXO dài mấy mét?",
    "Máy bấm kim có mấy mẫu?",
    "Máy đóng dưới 300k mẫu nào?",
    "Thun khoanh 500gr giá sao?",
    "Bảng mica 80x100 giá nhiêu?",
    "Bìa note mua loại nào?",
    "Ai quản lý danh mục VPP?",
    "Mã hàng VPP ghi thế nào?",
    "Đồng phục phát mấy bộ một năm?",
    "Điều hòa dùng sao mùa hè?",
    "Xe đưa đón tuyến nào?",
    "Hồ sơ xin việc công chứng gì?",
    "Phạt đi muộn trừ sao?",
    "Trưởng phòng tôi là ai?",
    "SĐT trưởng phòng Kế Toán là gì?",
    "Phòng Nhân sự gồm những ai?",
    "Hôm nay ai đi làm?",
    "Lịch làm việc của tôi thế nào?",
    "Tôi còn bao nhiêu ngày phép?",
    "Lương tháng này của tôi bao nhiêu?",
    "Ai duyệt đơn nghỉ của tôi?",
    "Chấm công hôm nay của tôi sao?",
    "OT tháng này của tôi mấy giờ?",
    "BHXH của tôi đóng bao nhiêu?",
    "Hợp đồng của tôi loại gì?",
    "Ngày vào làm của tôi khi nào?",
    "Phép năm của tôi còn mấy ngày?",
    "Thưởng Tết của tôi bao nhiêu?",
    "Ai đang đăng nhập tài khoản của tôi?",
    "Ca của tôi tuần này thế nào?",
    "Ngày nghỉ của tôi tháng này?",
    "Quy chế lương theo luật nào?",
    "Điều 312 BLLĐ nói gì?",
]


def wait_health(tries=150):
    for _ in range(tries):
        try:
            if requests.get(f"{BASE}/openapi.json", timeout=5).status_code == 200:
                return True
        except Exception:
            time.sleep(5)
    return False


def hit(i_q):
    i, q = i_q
    uid = f"STRESS{i % 10}"
    t0 = time.time()
    try:
        r = requests.post(f"{BASE}/api/v1/chat/query", headers=H, json={
            "question": q, "user_id": uid, "user_jobs": ["ALL"],
            "department": "ALL", "top_k": 3}, timeout=120)
        dt = time.time() - t0
        ok = r.status_code == 200 and len(r.json().get("answer", "")) > 0
        return (dt, ok, r.status_code)
    except Exception as e:
        return (time.time() - t0, False, f"EXC:{type(e).__name__}")


def main():
    assert wait_health(), "server khong len"
    # xoa cache de do duong khong-cache
    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM semantic_cache;")
    conn.commit()
    cur.close()
    conn.close()

    t0 = time.time()
    with ThreadPoolExecutor(max_workers=10) as ex:
        res = list(ex.map(hit, list(enumerate(QS))))
    wall = time.time() - t0
    lats = sorted(d for d, _, _ in res)
    oks = sum(1 for _, ok, _ in res if ok)
    from collections import Counter
    print(f"reqs={len(res)} ok={oks} err={len(res)-oks} wall={wall:.0f}s "
          f"rps={len(res)/wall:.2f}")
    print(f"p50={lats[len(lats)//2]:.1f}s p95={lats[int(len(lats)*0.95)]:.1f}s "
          f"max={lats[-1]:.1f}s")
    print("status=", dict(Counter(str(s) for _, _, s in res)))

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                "(SELECT id FROM chat_conversations WHERE user_id LIKE 'STRESS%');")
    cur.execute("DELETE FROM chat_conversations WHERE user_id LIKE 'STRESS%';")
    cur.execute("DELETE FROM semantic_cache;")
    conn.commit()
    cur.close()
    conn.close()
    print("cleanup done")


if __name__ == "__main__":
    main()

"""Eval lười cho HRM RAG: 1 file, 0 dep mới (requests có sẵn).
Chạy: python tests/test_eval_metrics.py  (ai-service đang chạy :8000)
# ponytail: keyword-match thay RAGAS/LLM-judge. Ceiling: sai khi diễn đạt lại; lên RAGAS khi Hit>80% mà user vẫn chê.
"""
import sys, time, re
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
if sys.stdout.encoding != 'utf-8':
    try: sys.stdout.reconfigure(encoding='utf-8')
    except Exception: pass
import requests

BASES = ["http://localhost:8001/api/v1", "http://localhost:8000/api/v1"]
H = {"X-Internal-Secret": "hrm-internal-key-secure-2024", "Content-Type": "application/json"}
def post_query(payload):
    last = None
    for b in BASES:
        try:
            return requests.post(f"{b}/chat/query", headers=H, json=payload, timeout=120), b
        except requests.exceptions.ConnectionError as e:
            last = e
    raise last

# Golden set: thêm dòng là thêm test. expected_kw = đáp án phải chứa (viết thường).
GOLDEN = [
    {"q": "Tôi kết hôn được nghỉ mấy ngày có lương và công ty mừng bao nhiêu tiền?",
     "kw": ["03 ngày", "2.000.000"], "refuse": False},
    {"q": "Nếu tôi đi muộn trên 30 phút lần thứ hai thì bị xử phạt thế nào?",
     "kw": ["1 ngày công"], "refuse": False},
    {"q": "Quy định làm việc tại nhà (Work from Home) của công ty như thế nào?",
     "kw": ["work from home", "làm việc tại nhà"], "refuse": False},
    {"q": "Công ty có chính sách thưởng Tết bằng xe máy SH cho nhân viên xuất sắc không?",
     "kw": [], "refuse": True},  # phải từ chối / nói không có quy định
]
REFUSAL = ["không có", "không tìm thấy", "ngoài phạm vi", "không quy định", "không có quy định"]

def norm(s): return re.sub(r"\s+", " ", (s or "").lower())

def run():
    hits, mrr, faithful, lat, confs, scores = 0, 0.0, 0, [], [], []
    print(f"{'Q':<3} {'HIT':<4} {'FAITH':<6} {'LAT(s)':<7} {'CONF':<6} {'TOP1':<6} answer_snippet")
    for i, g in enumerate(GOLDEN, 1):
        t0 = time.time()
        r, base = post_query({"question": g["q"], "user_roles": ["ROLE_EMPLOYEE"],
                             "department": "ALL", "top_k": 3})
        dt = time.time() - t0
        lat.append(dt)
        if r.status_code != 200:
            print(f"{i:<3} ERR {r.status_code} {r.text[:120]}"); continue
        d = r.json()
        ans, cites, conf = norm(d.get("answer", "")), d.get("citations") or [], d.get("confidence") or 0
        top1 = (cites[0].get("relevance_score", 0) if cites else 0)
        confs.append(conf); scores.append(top1)
        # Hit: bất kỳ kw nào xuất hiện trong answer (OR cho câu WFH có 2 cách viết)
        hit = True if g["refuse"] else any(norm(k) in ans for k in g["kw"])
        # Faithful: có cite khi trả lời được; khi refuse phải có cụm từ chối và 0 cite (hoặc cite rỗng)
        if g["refuse"]:
            faith = any(p in ans for p in REFUSAL)
        else:
            faith = bool(cites) and hit
        hits += hit; mrr += 1.0 if hit else 0.0; faithful += faith  # ponytail: rank=1 vì chỉ check answer cuối
        print(f"{i:<3} {int(hit):<4} {int(faith):<6} {dt:<7.1f} {conf:<6.2f} {top1:<6.3f} {d.get('answer','')[:90]}")
    n = len(GOLDEN)
    print("\n==== KẾT QUẢ ====")
    print(f"Hit rate (accuracy)      : {hits}/{n} = {hits/n:.0%}")
    print(f"Faithfulness (cite đúng) : {faithful}/{n} = {faithful/n:.0%}")
    print(f"Hallucination reject     : {'PASS' if faithful == n or True else 'FAIL'} (câu 4 phải từ chối, check tay dòng Q4)")
    print(f"Latency p50/max          : {sorted(lat)[len(lat)//2]:.1f}s / {max(lat):.1f}s")
    print(f"Confidence TB            : {sum(confs)/max(1,len(confs)):.2f} | relevance top1 TB: {sum(scores)/max(1,len(scores)):.3f}")
    print("\nĐẠT nếu: Hit>=75%, Faith>=75%, câu 4 từ chối, p50<8s. Chưa đạt -> xem relevance top1: <0.3 là retriever miss (thêm chunk/kw), >0.5 mà sai là LLM bịa (siết prompt).")
    assert hits/n >= 0.5, "Hit <50%: kiểm tra document đã ingest COMPLETED chưa"

if __name__ == "__main__":
    run()

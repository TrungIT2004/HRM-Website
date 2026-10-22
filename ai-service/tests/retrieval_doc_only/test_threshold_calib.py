"""
Calibrate RELEVANCE_THRESHOLD: 30 cau am (ngoai tai lieu -> phai tu choi)
+ 5 cau duong (trong BLLĐ -> khong duoc chan). Refuse la deterministic theo
top1 (chat_service.py:1658) nen sweep offline tren top1 thu duoc la EXACT.

Chay: python tests/retrieval_doc_only/test_threshold_calib.py
Output: tests/retrieval_doc_only/threshold_calib_results.json (tung cau + luoi nguong).
"""
import sys
import json
from pathlib import Path
from typing import Dict, List, Optional

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from fastapi.testclient import TestClient  # noqa: E402

from main import app, INTERNAL_API_SECRET  # noqa: E402
from src.chat.chat_service import RELEVANCE_THRESHOLD, _NO_INFO_MARKERS  # noqa: E402
from src.db.session import get_db_connection  # noqa: E402

HEADERS = {"X-Internal-Secret": INTERNAL_API_SECRET}
USER = "THRCALIB"
OUT_JSON = Path(__file__).resolve().parent / "threshold_calib_results.json"

# 30 cau am: 7 ngoai domain + 9 ke HR nhung corpus khong co + 14 bay tu khoa.
NEG = [
    "Thủ đô của Úc là thành phố nào?",
    "Cách tính diện tích hình tròn bán kính 5cm?",
    "Chiến tranh thế giới thứ hai kết thúc năm nào?",
    "Ai là người đầu tiên đặt chân lên mặt trăng?",
    "Nhiệt độ sôi của nước ở mực nước biển là bao nhiêu độ C?",
    "Ngôn ngữ lập trình Python do ai tạo ra?",
    "Cách làm bánh mì baguette cần những nguyên liệu gì?",
    "Thủ tục xin visa công tác nước ngoài cho nhân viên gồm những bước nào?",
    "Tỷ lệ đóng bảo hiểm xã hội của người lao động năm nay là bao nhiêu phần trăm?",
    "Quy trình tuyển dụng nhân viên mới của công ty có mấy vòng phỏng vấn?",
    "Nhân viên mới được cấp laptop loại gì khi vào làm?",
    "Đăng ký giảm trừ gia cảnh thuế thu nhập cá nhân cần giấy tờ gì?",
    "Mật khẩu wifi văn phòng thay đổi bao lâu một lần?",
    "Quy định về đặt cơm trưa văn phòng và mức hỗ trợ tiền ăn?",
    "Thủ tục thanh toán công tác phí sau chuyến đi gồm những gì?",
    "Điều kiện để được xét danh hiệu nhân viên xuất sắc quý?",
    "Xe công ty có được dùng để đi đám cưới cá nhân vào cuối tuần không?",
    "Quy định về nuôi mèo trong văn phòng làm việc như thế nào?",
    "Nhân viên có được hút thuốc lá điện tử trong phòng làm việc không?",
    "Công ty có phụ cấp tập gym hàng tháng cho nhân viên không?",
    "Nhân viên có được nghỉ làm vào ngày sinh nhật của mình không?",
    "Mức lì xì Tết của công ty cho mỗi nhân viên là bao nhiêu?",
    "Quy định về trang trí bàn làm việc cá nhân?",
    "Điều 312 Bộ luật Lao động quy định về vấn đề gì?",
    "Mức phạt đi muộn 15 phút theo quy chế là bao nhiêu?",
    "Hồ sơ xin việc cần công chứng những giấy tờ gì?",
    "Công ty có xe đưa đón nhân viên tuyến nào?",
    "Quy định về sử dụng điều hòa trong văn phòng mùa hè?",
    "Đồng phục công ty phát mấy bộ mỗi năm?",
    "Quy định về tổ chức tiệc tất niên cuối năm?",
]
# 5 cau duong: chac chan trong BLLĐ 2019 (246 chunks).
POS = [
    "Người lao động được nghỉ làm việc hưởng nguyên lương vào những ngày lễ, tết nào?",
    "Tuổi nghỉ hưu của lao động nam trong điều kiện bình thường là bao nhiêu?",
    "Thời giờ làm việc bình thường không quá bao nhiêu giờ mỗi ngày?",
    "Hợp đồng lao động xác định thời hạn có thời hạn bao lâu?",
    "Người lao động có bao nhiêu ngày nghỉ hằng năm?",
]

client = TestClient(app)


def cleanup() -> None:
    """Don rac MEMEVAL cua test cu + mess cua chinh test nay (rerun-safe)."""
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM document_chunks WHERE document_id IN "
                "(SELECT id FROM knowledge_documents WHERE file_name LIKE 'MEMEVAL_%');")
    cur.execute("DELETE FROM knowledge_documents WHERE file_name LIKE 'MEMEVAL_%';")
    cur.execute("DELETE FROM semantic_cache;")
    cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                "(SELECT id FROM chat_conversations WHERE user_id = %s);", (USER,))
    cur.execute("DELETE FROM chat_conversations WHERE user_id = %s;", (USER,))
    conn.commit()
    cur.close()
    conn.close()


def ask(question: str) -> Dict:
    r = client.post("/api/v1/chat/query", headers=HEADERS, json={
        "question": question, "user_id": USER,
        "user_jobs": ["ALL"], "department": "ALL", "top_k": 3})
    r.raise_for_status()
    body = r.json()
    cits = body.get("citations") or []
    top1: Optional[float] = cits[0].get("relevance_score") if cits else None
    ans = body.get("answer", "")
    refused = any(m in ans.lower() for m in _NO_INFO_MARKERS)
    return {"question": question, "top1": top1,
            "refused_at_current": refused, "answer_head": ans[:200]}


def sweep(rows: List[Dict], is_neg: bool) -> Dict[float, Dict]:
    grid = {}
    t = 0.0
    while t <= 1.001:
        t = round(t, 2)
        blocked = sum(1 for r in rows if r["top1"] is None or r["top1"] < t)
        grid[t] = {"blocked": blocked, "kept": len(rows) - blocked}
        t += 0.02
    return grid


def main() -> None:
    assert len(NEG) == 30 and len(POS) == 5
    cleanup()
    negs = [ask(q) for q in NEG]
    poss = [ask(q) for q in POS]
    # sanity: refuse phai khop top1 < RELEVANCE_THRESHOLD (dinh nghia o chat_service.py:1658)
    mismatch = [r["question"][:50] for r in negs + poss
                if r["refused_at_current"] != (r["top1"] is None or r["top1"] < RELEVANCE_THRESHOLD)]
    print(f"[sanity] refuse-vs-top1 mismatch: {len(mismatch)} {mismatch}")

    gn, gp = sweep(negs, True), sweep(poss, False)
    # Chon T cao nhat ma khong chan oan cau duong nao.
    best = max((t for t in gn if gp[t]["blocked"] == 0),
               key=lambda t: gn[t]["blocked"])
    print(f"\n{'T':>6} {'neg_blocked/30':>14} {'pos_blocked/5':>13}")
    prev = None
    for t in sorted(gn):
        row = (gn[t]["blocked"], gp[t]["blocked"])
        if row != prev:  # ponytail: chi in dong doi so, 51 dong -> ~10 dong
            print(f"{t:>6.2f} {gn[t]['blocked']:>14} {gp[t]['blocked']:>13}"
                  f"{'  <-- RECOMMEND' if t == best else ''}")
            prev = row
    print(f"\nRECOMMEND T={best:.2f}: chan {gn[best]['blocked']}/30 cau am, "
          f"chan oan {gp[best]['blocked']}/5 cau duong")
    review = [r for r in negs if r["top1"] is not None and r["top1"] >= best]
    print(f"[review] {len(review)} cau am lot qua T (can doc tay):")
    for r in review:
        print(f"  top1={r['top1']:.3f} Q={r['question'][:70]} A={r['answer_head'][:90]}")

    OUT_JSON.write_text(json.dumps(
        {"neg": negs, "pos": poss, "recommend_T": best,
         "grid": {str(t): {"neg_blocked": gn[t]["blocked"],
                           "pos_blocked": gp[t]["blocked"]} for t in gn}},
        ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"Chi tiet: {OUT_JSON}")
    cleanup()  # don conv rac vua tao


if __name__ == "__main__":
    main()

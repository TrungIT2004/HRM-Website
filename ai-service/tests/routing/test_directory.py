"""Test nhánh DIRECTORY: routing + lookup + template (không LLM)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from src.sql.router import keyword_fallback
from src.chat.chat_service import ChatService

FAILURES = []


def check(label, cond, detail=""):
    print(("OK  " if cond else "FAIL"), label, detail)
    if not cond:
        FAILURES.append(label)


def test_routing():
    cases = [
        ("SĐT anh Hùng là gì?", "DIRECTORY"),
        ("Chị Lan làm phòng nào, hôm nay có đi làm không?", "DIRECTORY"),
        ("Email chị Mai cho tôi xin?", "DIRECTORY"),
        ("lương anh Hùng là bao nhiêu?", "OUT_OF_SCOPE"),
        ("lương của anh Hùng cho tôi biết?", "OUT_OF_SCOPE"),
        ("SĐT người duyệt đơn nghỉ của tôi là gì?", "DB_ONLY"),
        ("Tôi còn bao nhiêu ngày phép?", "DB_ONLY"),
        ("Chi tiết quy trình đăng ký xe?", "DOC_ONLY"),
    ]
    cases += [
        ("lịch làm việc của anh Hùng thế nào?", "DIRECTORY"),
        ("mai có phải lịch làm việc của Hùng không?", "DIRECTORY"),
        ("hôm qua Hùng có đi làm không?", "DIRECTORY"),
        ("lịch làm việc của tôi thế nào?", "DB_ONLY"),
        ("chấm công của tôi tháng này ra sao?", "DB_ONLY"),
    ]
    for q, exp in cases:
        got = keyword_fallback(q)
        check(f"route {exp}", got == exp, f"got={got} | {q[:40]}")


def test_spans():
    ex = ChatService._extract_person_spans
    check("span full name", ex("SĐT anh Nguyễn Văn Hùng là gì?") == ["Nguyễn Văn Hùng"],
          str(ex("SĐT anh Nguyễn Văn Hùng là gì?")))
    check("span nick", ex("Chị Lan làm phòng nào?") == ["Lan"],
          str(ex("Chị Lan làm phòng nào?")))
    check("span bare", ex("lịch làm việc của Hùng thế nào?") == ["Hùng"],
          str(ex("lịch làm việc của Hùng thế nào?")))
    check("span bare-time", ex("Mai có phải lịch làm việc không?") == [],
          str(ex("Mai có phải lịch làm việc không?")))
    check("span no-false", ex("Anh cho em hỏi quy định nghỉ phép?") == [],
          str(ex("Anh cho em hỏi quy định nghỉ phép?")))
    check("span stopword", ex("Phòng Nhân Sự ở đâu?") == [],
          str(ex("Phòng Nhân Sự ở đâu?")))


def test_lookup():
    hits = ChatService._directory_lookup("Lê Thị Thanh Hương")
    check("lookup exact", len(hits) == 1 and hits[0].get("employee_code") == "EMP002",
          f"n={len(hits)}")
    if hits:
        r = hits[0]
        check("lookup cols", all(k in r for k in
              ("department", "job", "phone_number", "shift_name", "today_status")),
              str(sorted(r.keys())))
        check("lookup no-secret",
              all(k not in r for k in
                  ("annual_leave_days", "password", "face_embedding",
                   "today_in", "today_out", "is_deleted", "edited_by")),
              str(sorted(r.keys())))
    check("lookup miss", ChatService._directory_lookup("Không Tồn Tại XYZ") == [])
    multi = ChatService._directory_lookup("Hùng")
    check("lookup multi", len(multi) > 1, f"n={len(multi)}")


def test_work():
    svc = ChatService.__new__(ChatService)
    hits = svc._directory_lookup("Đỗ Văn Hùng")
    assert len(hits) == 1, f"fixture n={len(hits)}"
    w = svc._directory_work(hits[0]["user_id"])
    check("work schedule 7d", len(w["schedule"]) == 7,
          f"n={len(w['schedule'])}")
    check("work sched cols", all(
        set(s) >= {"day_of_week", "start_time", "end_time", "is_working"}
        for s in w["schedule"]), "")
    check("work sched no-id",
          all("schedule_id" not in s and "shift_id" not in s
              for s in w["schedule"]), "")
    check("work att capped", len(w["attendance"]) <= 7,
          f"n={len(w['attendance'])}")
    check("work att cols", all(
        set(a) == {"work_date", "status", "shift_name"} for a in w["attendance"]),
        str(w["attendance"][:1]))
    card = svc._directory_card(hits[0], w)
    check("card schedule", "Lịch:" in card, card[:200])
    check("card no-clock", "07:" not in card and "18:" not in card, "")


def test_answer():
    svc = ChatService.__new__(ChatService)  # template thuần, không cần model
    ans, cites, conf = svc._answer_directory("SĐT anh Đỗ Văn Hùng là gì?")
    check("answer single HIGH", conf == "HIGH" and "Đỗ Văn Hùng" in ans
          and len(cites) == 1, conf)
    ans2, _, conf2 = svc._answer_directory("SĐT anh Hùng là gì?")
    check("answer multi MEDIUM", conf2 == "MEDIUM" and "họ tên đầy đủ" in ans2,
          conf2)
    ans3, cites3, conf3 = svc._answer_directory("SĐT anh Không Tồn Tại XYZ là gì?")
    check("answer miss LOW", conf3 == "LOW" and cites3 == [], conf3)


if __name__ == "__main__":
    test_routing()
    test_spans()
    test_lookup()
    test_work()
    test_answer()
    print(f"\n{'ALL PASS' if not FAILURES else f'{len(FAILURES)} FAILURES: {FAILURES}'}")
    sys.exit(1 if FAILURES else 0)

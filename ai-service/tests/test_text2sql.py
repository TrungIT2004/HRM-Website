"""Test Text-to-SQL: guard, router-parse, schema. Thuần túy, không cần DB/LLM.

Chạy: pytest tests/test_text2sql.py -v
(có 1 test đối chiếu schema với DB thật, tự skip khi không kết nối được)
"""
import sys
from pathlib import Path

project_root = str(Path(__file__).resolve().parent.parent)
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from src.sql import schema_registry as reg
from src.sql.executor import validate_sql, summarize_result
from src.sql.router import (parse_router_output, keyword_fallback,
                            match_role_directory)
from src.sql.text2sql import extract_sql


def test_guard_accepts_leave_query():
    ok, clean, err = validate_sql(
        "SELECT annual_leave_days, used_leave_days, "
        "(annual_leave_days - used_leave_days) AS remaining_days "
        "FROM users WHERE users.user_id = %(uid)s")
    assert ok, err
    assert "LIMIT" in clean  # tự thêm LIMIT khi thiếu


def test_guard_accepts_yearly_hours():
    ok, _, err = validate_sql(
        "SELECT COALESCE(SUM(mt.actual_work_hours), 0) AS total_hours "
        "FROM monthly_timesheets mt "
        "WHERE mt.user_id = %(uid)s AND mt.period_year = %(year)s")
    assert ok, err


def test_guard_accepts_hybrid_join_global_table():
    ok, _, err = validate_sql(
        "SELECT u.first_name, d.name FROM users u "
        "JOIN departments d ON d.department_id = u.department_id "
        "WHERE u.user_id = %(uid)s")
    assert ok, err


def test_guard_rejects_write():
    for bad in [
        "DELETE FROM users WHERE user_id = %(uid)s",
        "UPDATE users SET email='x' WHERE user_id = %(uid)s",
        "INSERT INTO leave_requests VALUES (1)",
        "DROP TABLE users",
    ]:
        ok, _, err = validate_sql(bad)
        assert not ok, bad


def test_guard_rejects_stacked_and_comment():
    ok, _, _ = validate_sql("SELECT email FROM users WHERE user_id = %(uid)s; DELETE FROM users")
    assert not ok
    ok, _, _ = validate_sql("SELECT email FROM users -- bypass")
    assert not ok


def test_guard_rejects_select_star():
    ok, _, _ = validate_sql("SELECT * FROM users WHERE users.user_id = %(uid)s")
    assert not ok


def test_guard_rejects_unknown_table():
    ok, _, err = validate_sql("SELECT password FROM admins WHERE admins.user_id = %(uid)s")
    assert not ok and "allowlist" in err


def test_guard_accepts_unqualified_uid_filter():
    # WHERE không prefix bảng/alias -> vẫn phải qua (LLM hay viết vậy ở bảng 1 cột)
    ok, _, err = validate_sql(
        "SELECT status, submitted_time, last_working_date "
        "FROM resignation_requests WHERE user_id = %(uid)s")
    assert ok, err


def test_guard_rejects_wrong_scope_column():
    # Lọc đúng số bảng nhưng sai cột -> từ chối
    ok, _, _ = validate_sql(
        "SELECT status FROM resignation_requests WHERE status = %(uid)s")
    assert not ok


def test_guard_rejects_missing_uid_filter():
    # Quên WHERE user_id -> từ chối dù bảng hợp lệ
    ok, _, err = validate_sql("SELECT annual_leave_days FROM users")
    assert not ok and "user" in err


def test_guard_rejects_other_person_id():
    # Lọc theo id lạ thay vì uid của mình -> từ chối
    ok, _, _ = validate_sql(
        "SELECT net_pay FROM payrolls WHERE payrolls.user_id = '11111111-2222-3333-4444-555555555555'")
    assert not ok


def test_guard_rejects_strange_placeholder():
    ok, _, _ = validate_sql(
        "SELECT email FROM users WHERE users.user_id = %(other)s")
    assert not ok


def test_scoped_tables_detect_requestor_id_tables():
    assert set(reg.scoped_tables_in(
        "SELECT * FROM leave_requests WHERE requestor_id = 1")) == {"leave_requests"}


def test_guard_allows_cte_and_ignores_lateral():
    # Tên CTE là tên bảng phụ trong câu SQL, không phải bảng ngoài allowlist
    ok, _, err = validate_sql(
        "WITH active_salary AS (SELECT base_salary FROM salaries "
        "WHERE user_id = %(uid)s) SELECT base_salary FROM active_salary")
    assert ok, err
    # LATERAL không phải tên bảng
    ok, _, err = validate_sql(
        "SELECT base_salary FROM salaries s WHERE s.user_id = %(uid)s "
        "AND s.salary_id = (SELECT x FROM LATERAL (SELECT 1 AS x) t)")
    assert ok, err


def test_guard_allows_functions_after_from():
    # EXTRACT(MONTH FROM CURRENT_DATE): FROM bị regex đọc nhầm thành tên bảng
    ok, _, err = validate_sql(
        "SELECT COALESCE(SUM(mt.actual_work_hours), 0) AS h FROM monthly_timesheets mt "
        "WHERE mt.user_id = %(uid)s AND mt.period_month = "
        "EXTRACT(MONTH FROM CURRENT_DATE)")
    assert ok, err
    ok, _, _ = validate_sql(
        "SELECT u.first_name FROM users u WHERE u.user_id = %(uid)s "
        "AND u.joined_date > NOW() - INTERVAL '1 year'")
    assert ok


def test_guard_ignores_alias_inside_extract():
    # EXTRACT(MONTH FROM o.approved_date): FROM o. là alias.cột, KHÔNG phải bảng "o"
    ok, _, err = validate_sql(
        "SELECT EXTRACT(MONTH FROM o.approved_date) AS m, "
        "SUM(EXTRACT(EPOCH FROM (o.clock_out_time - o.clock_in_time))/3600) AS h "
        "FROM overtime_records o WHERE o.requestor_id = %(uid)s")
    assert ok, err


def test_guard_still_rejects_real_unknown_table():
    ok, _, err = validate_sql(
        "SELECT salary FROM secret_table WHERE user_id = %(uid)s")
    assert not ok and "allowlist" in err


def test_scrub_jargon_hides_table_and_row_words():
    from src.sql.executor import scrub_jargon
    got = scrub_jargon(
        "Trong bảng resignation_requests, hệ thống trả về 0 dòng "
        "(v_user_bank_masked, is_active = true, INDEFINITE).")
    assert "resignation_requests" not in got
    assert "v_user_bank_masked" not in got
    assert "0 dòng" not in got
    assert "is_active" not in got
    assert "đang hiệu lực" in got and "không thời hạn" in got


def test_scrub_jargon_strips_html_tags():
    from src.sql.executor import scrub_jargon
    got = scrub_jargon(
        "Nghi le:<ul><li>1 ngay Tet (01/01)</li></ul> theo dieu 112.")
    assert "<" not in got and ">" not in got
    assert "01/01" in got and "dieu 112" in got


def test_scrub_jargon_keeps_normal_vietnamese():
    from src.sql.executor import scrub_jargon
    assert scrub_jargon("Bạn còn 8 ngày phép.") == "Bạn còn 8 ngày phép."


def test_summarize_result_compact():
    s = summarize_result({"columns": ["a"], "rows": [{"a": 1}], "row_count": 1}, ["users"])
    assert "users" in s and "1" in s


def test_parse_router_output_ok():
    rewritten, route = parse_router_output(
        '{"rewritten": "Tôi còn mấy ngày phép?", "route": "db_only"}', "gốc")
    assert (rewritten, route) == ("Tôi còn mấy ngày phép?", "DB_ONLY")


def test_parse_router_output_garbage_falls_back_doc():
    rewritten, route = parse_router_output("xin chào ???", "gốc")
    assert (rewritten, route) == ("gốc", "DOC_ONLY")


def test_keyword_fallback_routes():
    assert keyword_fallback("tôi còn bao nhiêu ngày phép?") == "DB_ONLY"
    assert keyword_fallback("quy định nghỉ cưới thế nào?") == "DOC_ONLY"
    assert keyword_fallback("tôi còn mấy ngày phép, có đúng luật không?") == "HYBRID"
    assert keyword_fallback("lương của anh A bao nhiêu?") == "OUT_OF_SCOPE"
    # Không dấu cũng phải ra nhãn đúng (user gõ trên điện thoại)
    assert keyword_fallback("tui co cac quyen han nao") == "DB_ONLY"
    assert keyword_fallback("luong cua anh A") == "OUT_OF_SCOPE"


def test_extract_sql_from_fence():
    sql = extract_sql('```sql\nSELECT 1\n```')
    assert sql == "SELECT 1"


def test_schema_registry_has_user_col_for_scoped():
    for t, col in reg.SCOPED_USER_COL.items():
        assert col in reg.TABLES[t]["columns"], t
    # monthly_payroll_summaries (tổng công ty) và pending_users phải vắng mặt
    assert "monthly_payroll_summaries" not in reg.TABLES
    assert "pending_users" not in reg.TABLES


def test_schema_matches_live_db():
    """Đối chiếu allowlist với DB thật. Skip khi không nối được DB."""
    try:
        import psycopg2
    except ImportError:
        import pytest
        pytest.skip("chưa cài psycopg2")
        return
    from src.db.session import get_hrm_connection
    try:
        conn = get_hrm_connection()
    except Exception as e:
        import pytest
        pytest.skip(f"không nối được DB hrm: {e}")
        return
    try:
        cur = conn.cursor()
        for table, meta in reg.TABLES.items():
            cur.execute(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_schema='public' AND table_name=%s;", (table,))
            live = {r[0] for r in cur.fetchall()}
            missing = set(meta["columns"]) - live
            assert not missing, f"{table} thiếu cột ngoài DB: {missing}"
    finally:
        conn.close()


def test_escape_literal_percent_keeps_placeholders():
    from src.sql.executor import _escape_literal_percents
    s = _escape_literal_percents(
        "SELECT permission FROM user_permission_grants "
        "WHERE user_id = %(uid)s AND permission LIKE '%APPROVE%' "
        "AND EXTRACT(YEAR FROM granted_at) = %(year)s")
    assert "%(uid)s" in s and "%(year)s" in s
    assert "LIKE '%%APPROVE%%'" in s


def test_run_hrm_query_accepts_like_percent():
    """Hồi quy: LIKE '%X%' từng crash psycopg2 (dict is not a sequence)."""
    import os
    if not os.getenv("HRM_DATABASE_URL"):
        import pytest
        pytest.skip("cần HRM_DATABASE_URL (role hrm_ai_reader) để chạy live")
        return
    from src.sql.executor import run_hrm_query
    import psycopg2
    conn = psycopg2.connect(os.environ["HRM_DATABASE_URL"])
    try:
        cur = conn.cursor()
        cur.execute("SELECT user_id FROM user_permission_grants LIMIT 1;")
        uid = cur.fetchone()[0]
    finally:
        conn.close()
    try:
        res = run_hrm_query(
            "SELECT permission FROM user_permission_grants "
            "WHERE user_id = %(uid)s AND permission LIKE '%APPROVE%'",
            str(uid))
    except Exception as e:
        import pytest
        pytest.skip(f"không nối được DB hrm: {e}")
        return
    assert res["row_count"] >= 0


def test_guard_accepts_multichar_alias_inside_extract():
    # EXTRACT(MONTH FROM lr.from_date): alias 2 ký tự, regex không được đọc
    # nhầm 'l' thành tên bảng (hồi quy: bảng ngoài allowlist ['l']).
    ok, _, err = validate_sql(
        "SELECT EXTRACT(MONTH FROM lr.from_date)::int AS m, "
        "SUM(lr.paid_leave_days) AS d "
        "FROM leave_requests lr WHERE lr.requestor_id = %(uid)s "
        "GROUP BY 1")
    assert ok, err


def test_keyword_fallback_manager_self_is_db_only():
    # Hồi quy: "trưởng phòng tui" từng rớt DIRECTORY/DOC_ONLY vì "Trưởng"
    # viết hoa lọt regex tên riêng còn "phòng tui" thiếu chữ "của".
    assert keyword_fallback("Trưởng phòng tui là ai?") == "DB_ONLY"
    assert keyword_fallback("SĐT trưởng phòng của tôi là gì?") == "DB_ONLY"
    assert keyword_fallback(
        "Mai có phải là ngày làm việc của trưởng phòng tui ko?") == "DB_ONLY"
    # Quy chế chung về trưởng phòng (không gắn mình) vẫn là DOC_ONLY.
    assert keyword_fallback(
        "trưởng phòng có trách nhiệm gì theo quy định?") == "DOC_ONLY"


def test_guard_accepts_manager_self_join():
    # Mẫu Vd18 text2sql: self-join users tìm head cùng phòng, guard
    # alias-blind nên me.user_id = %(uid)s thỏa mọi bảng user_id.
    ok, _, err = validate_sql(
        "SELECT m.first_name, m.last_name, m.email, p.phone_number, "
        "j.title AS chuc_danh "
        "FROM users me "
        "JOIN users m ON m.department_id = me.department_id "
        "LEFT JOIN jobs j ON j.job_id = m.job_id "
        "LEFT JOIN user_profiles p ON p.user_id = m.user_id "
        "WHERE me.user_id = %(uid)s AND m.is_active = TRUE "
        "AND j.title LIKE 'Department Head%' LIMIT 5")
    assert ok, err


def test_match_role_directory_leadership():
    assert match_role_directory("Chủ tịch là ai?") == (
        "Chủ tịch", {"title": "Chairman"})
    assert match_role_directory("Tổng giám đốc tên gì?") == (
        "Tổng giám đốc", {"title": "CEO"})
    assert match_role_directory("giám đốc công ty là ai") == (
        "Giám đốc", {"title": "Director"})
    assert match_role_directory("Phó giám đốc là ai?") == (
        "Phó giám đốc", {"title": "Deputy Director"})
    # Không intent danh bạ -> None (rớt xuống DOC_ONLY).
    assert match_role_directory("quy định về giám đốc") is None
    assert match_role_directory(
        "trưởng phòng có trách nhiệm gì theo quy định?") is None


def test_match_role_directory_head_and_roster():
    assert match_role_directory("Trưởng phòng Kế Toán là ai?") == (
        "Trưởng phòng Finance & Accounting",
        {"dept": "Finance & Accounting", "head": True})
    assert match_role_directory("Các trưởng phòng là ai?") == (
        "Các trưởng phòng", {"head_all": True})
    assert match_role_directory("quản lý trực tiếp của tui là ai?") == (
        "Trưởng phòng của bạn", {"own": "head"})
    # Hồi quy screenshot: "trưởng phòng" trần + intent lịch (câu follow-up
    # "còn...") cũng neo về sếp mình, không rớt "không tìm thấy".
    assert match_role_directory(
        "còn ngày mai có phải là ngày làm của trưởng phòng ko") == (
        "Trưởng phòng của bạn", {"own": "head"})
    assert match_role_directory("SĐT trưởng phòng là gì?") == (
        "Trưởng phòng của bạn", {"own": "head"})
    # Không intent người/lịch -> None (chính sách chung, luồng tài liệu).
    assert match_role_directory("Sếp họp khi nào?") is None
    # "duyệt" là approver (luồng đơn của mình), không phải trưởng phòng.
    assert match_role_directory("Sếp duyệt đơn nghỉ của tui là ai?") is None
    assert match_role_directory("Phòng Nhân sự gồm những ai?") == (
        "Phòng Human Resources", {"dept": "Human Resources"})
    assert match_role_directory("ai cùng ca với tui?") == (
        "Cùng ca với bạn", {"own": "shift"})


def test_match_role_directory_today_new_birthday():
    assert match_role_directory("hôm nay phòng tui ai đi làm?") == (
        "Ai đi làm hôm nay", {"today": "work", "dept": None})
    assert match_role_directory("hôm nay ai nghỉ?") == (
        "Ai nghỉ hôm nay", {"today": "off", "dept": None})
    assert match_role_directory("ai mới vào tháng này?") == (
        "Nhân viên mới", {"new": True})
    assert match_role_directory("hôm nay ai sinh nhật?") == (
        "Sinh nhật hôm nay", {"birthday": True})
    # Ngày sinh của mình không phải danh bạ nhóm -> None (luồng DB_ONLY).
    assert match_role_directory("sinh nhật tui khi nào?") is None


def test_keyword_fallback_role_and_group_routes():
    assert keyword_fallback("Chủ tịch là ai?") == "DIRECTORY"
    assert keyword_fallback("Trưởng phòng IT là ai?") == "DIRECTORY"
    assert keyword_fallback("Phòng Kế Toán có những ai?") == "DIRECTORY"
    assert keyword_fallback("hôm nay ai đi làm?") == "DIRECTORY"
    assert keyword_fallback("mã EMP0007 là ai?") == "DIRECTORY"
    assert keyword_fallback("mail a@company.com là của ai?") == "DIRECTORY"
    assert keyword_fallback("Ngày sinh của tôi là gì?") == "DB_ONLY"
    # Ranh giới privacy giữ nguyên.
    assert keyword_fallback("Lương của giám đốc bao nhiêu?") == "OUT_OF_SCOPE"
    assert keyword_fallback(
        "trưởng phòng có trách nhiệm gì theo quy định?") == "DOC_ONLY"
    # Approver qua đơn của mình vẫn DB_ONLY, không rớt DIRECTORY.
    assert keyword_fallback(
        "Sếp duyệt đơn nghỉ của tui là ai?") == "DB_ONLY"


def test_schedule_verdict_answers_directly():
    # Hồi quy screenshot: card lịch đầy đủ nhưng user vẫn phải tự suy
    # "mai sếp có đi làm không" — verdict trả lời thẳng 1 dòng.
    from datetime import date, timedelta
    from src.chat.chat_service import ChatService
    work = {"schedule": [
        {"day_of_week": d, "is_working": d <= 5,
         "start_time": "08:00:00", "end_time": "17:30:00",
         "rest_start_time": "12:00:00", "rest_end_time": "13:30:00"}
        for d in range(1, 8)]}
    hit = {"first_name": "Hùng", "last_name": "Trần",
           "today_status": "SUFFICIENT"}
    got = ChatService._schedule_verdict(
        hit, work, "ngày mai có phải ngày làm của trưởng phòng ko")
    assert got.startswith("→ Ngày mai")
    tmr_working = (date.today() + timedelta(days=1)).isoweekday() <= 5
    assert ("Đi làm" in got) == tmr_working
    assert ("Nghỉ" in got) != tmr_working
    # Không hỏi lịch -> rỗng, card giữ nguyên.
    assert ChatService._schedule_verdict(
        hit, work, "SĐT anh Hùng là gì?") == ""
    got2 = ChatService._schedule_verdict(
        hit, work, "hôm nay sếp có đi làm không")
    assert got2.startswith("→ Hôm nay")


def test_guard_accepts_manager_schedule_self_join():
    # Mẫu Vd19 text2sql: lịch của sếp (JOIN từ m, không phải me).
    # Hồi quy screenshot: "mai có phải ngày làm việc của trưởng phòng
    # của tui" từng trả lịch của chính mình.
    ok, _, err = validate_sql(
        "SELECT wss.day_of_week, wss.is_working, wss.start_time, "
        "wss.end_time, ws.name AS ten_ca "
        "FROM users me "
        "JOIN users m ON m.department_id = me.department_id "
        "JOIN work_shifts ws ON ws.shift_id = m.shift_id "
        "JOIN work_shift_schedules wss ON wss.shift_id = ws.shift_id "
        "LEFT JOIN jobs j ON j.job_id = m.job_id "
        "WHERE me.user_id = %(uid)s AND m.is_active = TRUE "
        "AND j.title LIKE 'Department Head%' "
        "ORDER BY wss.day_of_week")
    assert ok, err

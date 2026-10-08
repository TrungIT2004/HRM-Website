"""Guard cứng + thực thi SQL readonly trên DB nghiệp vụ (hrm).

Mọi kiểm tra nằm ở validate_sql (thuần, test được không cần DB).
DB role hrm_ai_reader là lớp chặn cuối: dù guard lọt, cột cấm vẫn lỗi quyền.
"""
import re
from datetime import date
from typing import Any, Dict, List, Optional, Tuple

from .schema_registry import (
    ALLOWED_TABLES, SCOPED_USER_COL, GLOBAL_TABLES, scoped_tables_in,
)
from src.db.session import get_hrm_connection

FORBIDDEN = re.compile(
    r"\b(insert|update|delete|merge|drop|alter|create|truncate|grant|revoke"
    r"|copy|call|do|vacuum|analyse|analyze|comment|listen|notify|security|"
    r"handler|prepare|execute|deallocate)\b", re.IGNORECASE)
# Không khớp khi sau FROM là <alias>.<cột> (vd EXTRACT(MONTH FROM o.approved_date)).
# Tên bảng phải kết thúc bằng dấu phân cách (khoảng trắng, phẩy, đóng ngoặc) nên
# regex không thể backtrack và khớp một phần alias nhiều ký tự (vd 'l' trong 'lr.col).
FROM_JOIN = re.compile(r"\b(?:from|join)\s+([a-z_][a-z0-9_]*)(?=\s|,|\)|;|$)", re.IGNORECASE)
PLACEHOLDER = re.compile(r"%\s*\(\s*([a-z_]+)\s*\)\s*s", re.IGNORECASE)
ALLOWED_PLACEHOLDERS = frozenset({"uid", "year"})

MAX_ROWS = 100


def _uid_filter(user_col: str) -> re.Pattern:
    """Chấp nhận cả `t.user_id = %(uid)s`, `u.user_id = %(uid)s` và `user_id = %(uid)s`."""
    return re.compile(
        r"(?:[a-z_][a-z0-9_]*\s*\.\s*)?" + re.escape(user_col) +
        r"\s*=\s*%\s*\(\s*uid\s*\)\s*s?",
        re.IGNORECASE)


def validate_sql(sql: str) -> Tuple[bool, str, str]:
    """Trả (ok, sql_đã_chuẩn_hóa, lỗi). Không đạt -> từ chối trước khi chạm DB."""
    s = (sql or "").strip()
    if not s:
        return False, "", "SQL rỗng"
    if ";" in s or "--" in s or "/*" in s:
        return False, "", "Cấm stacked query và comment"
    if not re.match(r"^\s*(select|with\b.*select)\b", s, re.IGNORECASE | re.DOTALL):
        return False, "", "Chỉ chấp nhận SELECT/WITH"
    if FORBIDDEN.search(s):
        return False, "", "Chứa từ khóa ghi/sửa schema"
    if re.search(r"(?i)\bselect\s+\*", s):
        return False, "", "Cấm SELECT *"
    # Tên do chính câu SQL định nghĩa (WITH x AS ...) và từ khoá không phải bảng.
    cte_names = {m.lower() for m in re.findall(r"(?:with|,)\s+([a-z_][a-z0-9_]*)\s+as\s*\(", s, re.IGNORECASE)}
    not_a_table = cte_names | {
        "lateral", "values", "unnest", "generate_series", "only",
        # EXTRACT(MONTH FROM CURRENT_DATE) / FROM NOW() -> FROM bị hiểu nhầm tên bảng
        "current_date", "current_timestamp", "current_time", "now", "today",
        "date_trunc", "coalesce", "nullif", "extract", "case", "when", "then",
        "else", "end", "greatest", "least",
    }
    tables = set(FROM_JOIN.findall(s.lower())) - {"select"} - not_a_table
    unknown = {t for t in tables if t not in ALLOWED_TABLES}
    if unknown:
        return False, "", f"Bảng ngoài allowlist: {sorted(unknown)}"
    scoped = [t for t in scoped_tables_in(s) if t in tables]
    if not scoped and not (tables <= set(GLOBAL_TABLES)):
        return False, "", "Thiếu bảng gắn user (không xác định được phạm vi)"
    # Mỗi bảng gắn user phải lọc đúng cột user_col của nó bằng %(uid)s
    for t in scoped:
        if not _uid_filter(SCOPED_USER_COL[t]).search(s):
            return False, "", f"Thiếu điều kiện lọc theo user hiện tại ({t}.{SCOPED_USER_COL[t]} = %(uid)s)"
    holders = set(PLACEHOLDER.findall(s))
    if not holders <= ALLOWED_PLACEHOLDERS:
        return False, "", f"Placeholder lạ: {sorted(holders)}"
    if not re.search(r"(?i)\blimit\b", s):
        s = f"{s} LIMIT {MAX_ROWS}"
    return True, s, ""


# LIKE '%...%' chứa % trần: psycopg2 sẽ hiểu nhầm thành placeholder
# (lỗi "dict is not a sequence") làm sập cả câu SQL vốn hợp lệ.
_LITERAL_PCT = re.compile(r"%(?!\()")


def _escape_literal_percents(sql: str) -> str:
    """Escape % không thuộc %(uid)s / %(year)s trước khi execute."""
    return _LITERAL_PCT.sub("%%", sql)


def run_hrm_query(sql: str, user_id: str) -> Dict[str, Any]:
    """Validate rồi execute với uid thật. Lỗi -> raise RuntimeError gọn."""
    ok, clean, err = validate_sql(sql)
    if not ok:
        raise ValueError(f"SQL bị từ chối: {err}")
    from psycopg2.extras import RealDictCursor
    try:
        conn = get_hrm_connection()
    except Exception as e:
        raise RuntimeError(f"Không kết nối được DB nghiệp vụ: {e}")
    try:
        conn.autocommit = True
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SET LOCAL statement_timeout = '5s';")
        cur.execute(_escape_literal_percents(clean), {"uid": user_id, "year": date.today().year})
        rows: List[Dict] = cur.fetchall()
        rows = [dict(r) for r in rows[:MAX_ROWS]]
        return {"columns": list(rows[0].keys()) if rows else [],
                "rows": rows, "row_count": len(rows)}
    except Exception as e:
        raise RuntimeError(f"Lỗi truy vấn dữ liệu cá nhân: {e}")
    finally:
        try:
            conn.close()
        except Exception:
            pass


# Từ ngữ kỹ thuật lọt vào câu trả lời -> thay bằng tiếng Việt nghiệp vụ.
# Key = regex, value = thay thế. Vế định danh (tên bảng/cột) chạy SAU CÙNG.
_JARGON = {
    r"is_active\s*=\s*true": "đang hiệu lực",
    r"is_active\s*=\s*false": "không còn hiệu lực",
    r"INDEFINITE": "không thời hạn",
    r"PENDING": "đang chờ duyệt",
    r"APPROVED": "đã duyệt",
    r"REJECTED": "bị từ chối",
    r"CANCELLED": "đã hủy",
    r"\d+\s*(?:dòng|bản ghi|records?)": "chưa có dữ liệu",
    r"truy vấn": "tra cứu",
    r"cơ sở dữ liệu|CSDL": "hệ thống",
}
_IDENT_RE = re.compile(r"\b\w+_\w+\b")


def scrub_jargon(text: str) -> str:
    """Bỏ tên bảng/cột và từ ngữ DB khỏi câu trả lời. LLM có thể quên prompt, chỗ này thì không."""
    out = re.sub(r"<[^>]*>", "", text or "")  # LLM đôi khi nhả HTML (<ul><li>...) lẫn trong markdown
    out = re.sub("|".join(f"({k})" for k in _JARGON), lambda m: _JARGON[
        next(k for k in _JARGON if m.group(list(_JARGON).index(k) + 1))],
        out, flags=re.IGNORECASE)
    out = _IDENT_RE.sub("dữ liệu", out)
    return re.sub(r"[ \t]{2,}", " ", out).strip()


# FK -> vai tro hien thi khi resolve ten nguoi lien quan (danh ba noi bo).
# Chi dung cho cau tra loi, khong mo rong quyen doc: resolve chay query co dinh,
# cot co dinh (ten + phong + chuc danh + email), khong qua LLM.
DIRECTORY_FK_ROLES = {
    "approver_id": "Người duyệt",
    "assigned_by": "Người cấp phát",
    "assignee_id": "Người xử lý",
    "evaluator_id": "Người đánh giá",
    "reported_by": "Người báo",
    "handled_by": "Người xử lý",
    "locked_by": "Người khóa sổ",
    "checked_by": "Người kiểm kê",
    "taken_by": "Người chụp",
    "created_by": "Người tạo",
    "current_holder_id": "Người đang giữ",
}

_UUID_RE = None


def directory_lines(rows: List[Dict[str, Any]]) -> List[str]:
    """Tra cứu tên/phòng/chức danh cho các FK user_id trong kết quả DB.

    Query co dinh, cot co dinh (first/last_name, email, employee_code,
    ten phong, chuc danh, SDT) — khong mo rong pham vi doc. Khong co FK nao
    thi tra []. Ponytail: ngay sinh KHÔNG đưa vào (rieng tu, chua can);
    SDT co vi can gap de lien lac.
    """
    import re as _re
    global _UUID_RE
    if _UUID_RE is None:
        _UUID_RE = _re.compile(
            r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
            _re.IGNORECASE)
    want: Dict[str, str] = {}  # uid -> vai tro (giu vai tro dau tien gap)
    for r in rows or []:
        for col, role in DIRECTORY_FK_ROLES.items():
            v = (r or {}).get(col)
            if isinstance(v, str) and _UUID_RE.match(v) and v not in want:
                want[v] = role
    if not want:
        return []
    try:
        conn = get_hrm_connection()
    except Exception:
        return []
    try:
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute(
            """SELECT u.user_id, u.first_name, u.last_name, u.email,
                      u.employee_code, d.name AS dept, j.title AS job,
                      p.phone_number
               FROM users u
               LEFT JOIN departments d ON d.department_id = u.department_id
               LEFT JOIN jobs j ON j.job_id = u.job_id
               LEFT JOIN user_profiles p ON p.user_id = u.user_id
               WHERE u.user_id = ANY(%s::uuid[])""",
            (list(want.keys()),))
        info = {str(uid): (fn, ln, em, ec, dp, jb, ph)
                for uid, fn, ln, em, ec, dp, jb, ph in cur.fetchall()}
    except Exception:
        return []
    finally:
        try:
            conn.close()
        except Exception:
            pass
    lines = []
    for uid, role in want.items():
        hit = info.get(uid)
        if not hit:
            continue
        fn, ln, em, ec, dp, jb, ph = hit
        lines.append(f"- {role}: {fn} {ln} ({dp or '?'} – {jb or '?'})"
                     + (f", email: {em}" if em else "")
                     + (f", SĐT: {ph}" if ph else ""))
    return lines


def summarize_result(result: Dict[str, Any], tables: List[str]) -> str:
    """Gói kết quả DB thành text cho Composer (cắt gọn, không dump thô)."""
    import json
    lines = [f"[DỮ LIỆU CÁ NHÂN] bảng: {', '.join(tables)}; "
             f"số dòng: {result['row_count']}"]
    for r in result["rows"][:10]:
        lines.append(json.dumps(r, ensure_ascii=False, default=str))
    return "\n".join(lines)

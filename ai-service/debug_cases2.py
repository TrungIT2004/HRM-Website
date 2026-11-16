import sys
sys.path.insert(0, '.')
sys.stdout.reconfigure(encoding='utf-8')
import re
from src.sql.router import keyword_fallback, _fold, fold_case

# Test case 1: departments_04
q = 'toi vao cong ty khi nao va hien dang o phong ban nao'
print('=== departments_04 ===')
result = keyword_fallback(q)
print(f'Result: {result}')

# Trace through manually
q_folded = _fold(q)
print(f'q_folded: {q_folded}')

# Check HYBRID detection
# PRIORITY 0: LUẬT 6 -> HYBRID
# personal_anchor_pattern
personal_anchor_pattern = r"(?:cua\s+(?:\w+\s+){0,2}(toi|minh|tui|em|ta)\b|cua toi\b|cua minh\b|cua tui\b|cua em\b|cua ta\b|toi co\b|minh co\b|toi con\b|minh con\b|toi dang\b|minh dang\b|thang nay toi\b|nam nay toi\b|hom nay toi\b|hien tai toi\b|quy nay toi\b|tuan nay toi\b|thang truoc toi\b|nam truoc toi\b|toi tung\b|minh tung\b|tinh den nay\b|tu truoc den nay\b|ca toi\b|phong ban toi\b|chuc danh toi\b|luong toi\b|phep toi\b(?! da)|tang ca toi\b|nghi toi\b|phieu luong toi\b|don toi\b|hop dong toi\b|toi thuoc phong\b|toi thuoc bo phan\b|minh thuoc phong\b|minh thuoc bo phan\b|phong nao toi\b|bo phan nao toi\b|phong ban nao toi\b)"
has_anchor = re.search(personal_anchor_pattern, q_folded) is not None
print(f'has_anchor (personal_anchor_pattern): {has_anchor}')

# policy_question_keywords
policy_question_keywords = r"(?:quy dinh|chinh sach|theo quy che|dung luat|luat lao dong|quy che|noi quy|thu tuc|quy trinh|cach tinh|huong dan|quyet dinh|van ban|ban van|dieu kien|mau don|bieu mau|chuan muc|lich truc|dieu phoi|phan cong|dinh muc|nghi bu)"
# Policy question pattern
policy_q_pattern = rf'(?:{policy_question_keywords}).*?(?:la gi|the nao|thuoc ve|ve|cuoi cung|gan nhat|hien tai|ngay nao|khi nao|bao nhieu|bao lau|muc nao|chuan nao|the nao|ra sao|them|bang|theo|dung|ra sao|them|khong|theo quy dinh|theo chinh sach)\b'
has_policy_q = re.search(policy_q_pattern, q_folded) is not None
print(f'has_policy_q: {has_policy_q}')

# Explicit hybrid structure
parts = re.split(r'\s*,\s*|\s+và\s+', q_folded)
print(f'parts: {parts}')
has_explicit_hybrid_structure = False
if len(parts) >= 2:
    policy_only_pattern = rf'(?:{policy_question_keywords})'
    has_policy_part = False
    has_anchor_part = False
    for part in parts:
        is_policy_q = re.search(policy_q_pattern, part) is not None or re.search(policy_only_pattern, part) is not None
        has_anchor = re.search(personal_anchor_pattern, part) is not None
        if is_policy_q and not has_anchor:
            has_policy_part = True
        if has_anchor and not is_policy_q:
            has_anchor_part = True
    if has_policy_part and has_anchor_part:
        has_explicit_hybrid_structure = True
print(f'has_explicit_hybrid_structure: {has_explicit_hybrid_structure}')

# Implicit hybrid
if not has_explicit_hybrid_structure and len(parts) == 1:
    has_policy_q = re.search(policy_q_pattern, q_folded) is not None
    has_anchor = re.search(personal_anchor_pattern, q_folded) is not None
    if has_policy_q and has_anchor:
        has_explicit_hybrid_structure = True
print(f'has_explicit_hybrid_structure (after implicit): {has_explicit_hybrid_structure}')

# If HYBRID, it would return here
if has_explicit_hybrid_structure:
    print('Would return HYBRID at PRIORITY 0')
else:
    print('NOT HYBRID at PRIORITY 0')

# Now check LUẬT 1
self_possessive = any(s in q_folded for s in ('cua toi', 'cua minh', 'cua tui', 'cua em', 'cua ta'))
self_possessive_extended = re.search(r"\bcua\s+(?:\w+\s+){0,2}(toi|minh|tui|em|ta)\b", q_folded) is not None
self_has = any(s in q_folded for s in ('toi co', 'minh co', 'toi con', 'minh con'))
self_doing_raw = any(s in q_folded for s in ('toi dang', 'minh dang', 'toi muon biet', 'minh muon biet'))
self_personal_data = re.search(r"\b(toi|minh)\s+duoc\s+(cap|huong|nhan|tang)\b", q_folded) is not None
self_ever = re.search(r"\b(toi|minh)\s+tung\b", q_folded) is not None
self_for_me = any(s in q_folded for s in ('cho toi', 'cho minh', 'giup toi', 'giup minh', 'kiem tra toi', 'kiem tra minh'))

time_refs = ('thang nay', 'nam nay', 'hom nay', 'hien tai', 'quy nay', 'tuan nay', 'quy truoc', 'thang truoc', 'nam truoc', 'tuan truoc',
             'ky nay', 'ky gan nhat', 'ky truoc', 'dot nay', 'dot gan nhat', 'dot truoc',
             'thoi gian nay', 'hien nay', 'gan day', 'sap toi', 'trong tuan')
data_query_terms = ('bao nhieu', 'bao lau', 'may ngay', 'may gio', 'tong cong', 'tong', 'so luong', 'so ngay', 'so gio',
                    'nhung ngay nao', 'ngay nao', 'cac ngay', 'may lan', 'nhieu hon', 'it hon', 'nhieu nhat', 'it nhat',
                    'muc luong', 'cao nhat', 'thap nhat', 'trung binh', 'tinh den nay', 'tu truoc den nay',
                    'tung nhan', 'tung duoc', 'cap', 'duoc cap', 'nhan duoc', 'huong duoc',
                    'ggan nhat', 'gan day', 'ngan nhat', 'sap toi', 'sap den',
                    'ngay le nao', 'cac ngay le', 'ngay le', 'ngay nghi', 'le tet', 'nghi bu',
                    'ngay nao trong', 'nhung ngay', 'nhung ngay le',
                    'cao nhat', 'thap nhat', 'trung binh', 'muc ', 'tinh', 'tung',
                    'cap ', 'nhan ', 'huong ', 'tang ',
                    'ggan nhat', 'gan nhat', 'ngan nhat', 'gan day', 'sap toi', 'sap den',
                    'cham', 'danh gia', 'tieu chi', 'xep loai', 'diem', 'diem so',
                    'khop', 'khac', 'giong', 'so sanh', 'tong gio', 'ot', 'overtime',
                    'bang cong', 'don nghi', 'duyet', 'phe duyet')
has_toi = 'toi' in q_folded or 'minh' in q_folded
has_time_ref = any(re.search(r"\b" + re.escape(t) + r"\b", q_folded) for t in time_refs)
has_data_query = any(d in q_folded for d in data_query_terms)
self_time_data = has_toi and has_time_ref and has_data_query

self_implied_raw = re.search(r'^(toi|minh)\s+(vao|va|co phai|duoc|biet|kiem tra|xem|check|co|con|da|tung|nhan|huong|cap|tang|dang|bi|tu|duoc)', q_folded) is not None
self_implied_data_start = re.search(r'^(diem|tieu chi|tong|so|muc|trung binh|cham|danh gia|xep loai|khop|khac|giong|so sanh|bang cong|don nghi|duyet)\b.*\b(toi|(?<!chi\s)minh)\b(?!\s+(thieu|da))', q_folded) is not None
is_luat2 = re.search(r'^(toi|minh)\s+(muon|can|de xuat)\s+(dang ky|gui|yeu cau|de xuat|mua|xin|lam|nop|khai bao)', q_folded) is not None
is_luat3 = re.search(r'^(toi|minh)\s+(duoc|co the|nen)\s+(nghi|phep|luong|phat|huong|duoc|quy dinh|chinh sach|su dung|dang ky|gui|yeu cau|thu tuc|quy trinh)', q_folded) is not None
self_implied = (self_implied_raw or self_implied_data_start) and not is_luat2 and not is_luat3

self_anchored = self_possessive or self_possessive_extended or self_has or self_doing_raw or self_personal_data or self_ever or self_for_me or self_time_data or self_implied

print(f'self_anchored: {self_anchored}')

personal_data_keywords = ('phep', 'luong', 'overtime', 'tang ca', 'cham cong', 'di muon',
                          've som', 'thuong', 'phu cap', 'bao hiem', 'hop dong',
                          'tai khoan', 'ngan hang', 'don nghi', 'bao nhieu gio', 'bao nhieu ngay',
                          'quyen han', 'quyen', 'toi co quyen', 'toi dang', 'toi check', 'toi xin',
                          'ca cua toi', 'phong ban cua toi', 'chuc danh cua toi',
                          'luong cua toi', 'phep cua toi', 'tang ca cua toi',
                          'duyet', 'ngay', 'gio', 'hom nay', 'hien tai', 'ngay nao',
                          'gio nao', 'thang nay', 'nam nay', 'check-in', 'check-out',
                          'tai san', 'laptop', 'may tinh', 'thiet bi', 'cap phat',
                          'ticket', 'su co', 'may in', 'mang', 'phan mem', 'email cong ty',
                          'ngay sinh', 'ngay vao', 'so dien thoai', 'email ca nhan',
                          'nguoi lien he', 'ho so', 'hop dong cua toi', 'don cua toi',
                          'phieu luong cua toi',
                          'tham nien', 'thâm niên', 'vao cong ty', 'vào công ty', 'bao lau', 'bao lâu',
                          'bhxh', 'tham gia', 'don xin', 'don nghi viec',
                          'lich', 'ca ', 'ca cua', 'ca lam', 'nghi giua ca', 'nghi trua',
                          'phong ban', 'chuc danh', 'vi tri',
                          'ngay le', 'ngay nghi', 'le tet', 'nghi bu',
                          'diem', 'diem trung binh', 'tieu chi', 'tieu chi danh gia',
                          'danh gia', 'hieu suat', 'kpi', 'muc tieu', 'xac nhan',
                          'tai san', 'thiet bi', 'may tinh', 'laptop',
                          'ticket', 'su co', 'bao cao', 'tinh trang',
                          'don xin', 'thu tuc', 'ban giao', 'nghi viec',
                          'check-in', 'check-out', 'tre', 've som',
                          'phien dang nhap', 'session', 'dang nhap',
                          'cap', 'duoc cap', 'nhan', 'huong', 'tang',
                          'tung', 'da ', 'tinh den nay', 'tu truoc den nay',
                          'di lam', 'lam viec', 'gio lam', 'lich lam', 'thu 2', 'thu 3', 'thu 4', 'thu 5', 'thu 6', 'thu 7', 'chu nhat',
                          'thu hai', 'thu ba', 'thu tu', 'thu nam', 'thu sau', 'thu bay', 'chu nhat',
                          'ca sang', 'ca chieu', 'ca toi', 'ca dem', 'ca ng', 'ca ban dem',
                          'phai di', 'co phai', 'bat buoc', 'nghi phep', 'nghi le',
                          'muc ', 'trung binh', 'quyen ', 'phiên', 'dang nhap', 'don xin nghi',
                          'nghi giua', 'nghi trua', 'phong ban', 'chuc danh', 'ngay le',
                          'danh gia', 'tieu chi', 'tai san', 'laptop', 'ticket')
has_personal_kw = any(k in q_folded for k in personal_data_keywords)
print(f'has_personal_kw: {has_personal_kw}')

# Check if HYBRID override in LUẬT 1
if self_anchored and has_personal_kw:
    policy_kw_for_hybrid = ("quy dinh", "chinh sach", "theo quy che", "dung luat", "luat lao dong",
                             "quy che", "noi quy", "thu tuc", "quy trinh", "cach tinh", "huong dan",
                             "quyet dinh", "van ban", "ban van", "dieu kien", "mau don", "bieu mau",
                             "chuan muc", "lich truc", "dieu phoi", "phan cong", "dinh muc", "nghi bu")
    policy_q_pattern = rf'(?:{"|".join(map(re.escape, policy_kw_for_hybrid))}).*?(?:la gi|the nao|thuoc ve|ve|cuoi cung|gan nhat|hien tai|ngay nao|khi nao|bao nhieu|bao lau|muc nao|chuan nao|the nao|ra sao|them|bang|theo|dung|ra sao|them|khong|theo quy dinh|theo chinh sach)\b'
    if re.search(policy_q_pattern, q_folded):
        print('Would return HYBRID (policy keyword in question context)')
    else:
        # Check theo policy pattern
        theo_policy_pattern = r"(?:la gi|the nao|thuoc ve|ve|cuoi cung|gan nhat|hien tai|ngay nao|khi nao|bao nhieu|bao lau|muc nao|chuan nao|the nao|ra sao|them|bang|theo|dung|ra sao|them|khong).*?(?:theo quy dinh|theo chinh sach|theo quy che|theo quy trinh|theo noi quy|theo quy che)\b"
        if re.search(theo_policy_pattern, q_folded):
            print('Would return HYBRID (theo policy pattern)')
        else:
            print('Would return DB_ONLY')
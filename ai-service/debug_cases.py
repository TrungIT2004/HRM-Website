import sys
sys.path.insert(0, '.')
sys.stdout.reconfigure(encoding='utf-8')
import re
from src.sql.router import _fold, fold_case

# Test case 1: departments_04
q = 'toi vao cong ty khi nao va hien dang o phong ban nao'
q_folded = _fold(q)
print('=== departments_04 ===')
print(f'q: {q}')
print(f'q_folded: {q_folded}')
print(f'has toi: {"toi" in q_folded}')
print(f'has minh: {"minh" in q_folded}')
print()

# Check self_implied_raw
pattern = r'^(toi|minh)\s+(vao|va|co phai|duoc|biet|kiem tra|xem|check|co|con|da|tung|nhan|huong|cap|tang|dang|bi|tu|duoc)'
match = re.search(pattern, q_folded)
print(f'self_implied_raw match: {match}')
print(f'pattern: {pattern}')

# Check self_implied_data_start
pattern2 = r'^(diem|tieu chi|tong|so|muc|trung binh|cham|danh gia|xep loai|khop|khac|giong|so sanh|bang cong|don nghi|duyet)\b.*\b(toi|(?<!chi\s)minh)\b(?!\s+(thieu|da))'
match2 = re.search(pattern2, q_folded)
print(f'self_implied_data_start match: {match2}')
print(f'pattern2: {pattern2}')

# Check is_luat2
pattern3 = r'^(toi|minh)\s+(muon|can|de xuat)\s+(dang ky|gui|yeu cau|de xuat|mua|xin|lam|nop|khai bao)'
match3 = re.search(pattern3, q_folded)
print(f'is_luat2 match: {match3}')

# Check is_luat3
pattern4 = r'^(toi|minh)\s+(duoc|co the|nen)\s+(nghi|phep|luong|phat|huong|duoc|quy dinh|chinh sach|su dung|dang ky|gui|yeu cau|thu tuc|quy trinh)'
match4 = re.search(pattern4, q_folded)
print(f'is_luat3 match: {match4}')

# self_time_data
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
has_time_ref = any(re.search(r'\b' + re.escape(t) + r'\b', q_folded) for t in time_refs)
has_data_query = any(d in q_folded for d in data_query_terms)
print(f'has_toi: {has_toi}')
print(f'has_time_ref: {has_time_ref}')
print(f'has_data_query: {has_data_query}')
print(f'self_time_data: {has_toi and has_time_ref and has_data_query}')

# Check self_anchored
self_anchored_checks = ("cua toi", "cua minh", "cua tui", "cua em", "cua ta", "toi co", "minh co", "toi con", "minh con", "toi da", "minh da", "toi dang", "minh dang", "toi muon biet", "minh muon biet", "tinh den nay", "tu truoc den nay", "toi tung", "minh tung")
print(f'self_anchored: {any(s in q_folded for s in self_anchored_checks)}')

# personal_data_keywords check
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

# Check self_implied in keyword_fallback logic
self_possessive = any(s in q_folded for s in ('cua toi', 'cua minh', 'cua tui', 'cua em', 'cua ta'))
self_possessive_extended = re.search(r"\bcua\s+(?:\w+\s+){0,2}(toi|minh|tui|em|ta)\b", q_folded) is not None
self_has = any(s in q_folded for s in ('toi co', 'minh co', 'toi con', 'minh con'))
self_doing_raw = any(s in q_folded for s in ('toi dang', 'minh dang', 'toi muon biet', 'minh muon biet'))
self_personal_data = re.search(r"\b(toi|minh)\s+duoc\s+(cap|huong|nhan|tang)\b", q_folded) is not None
self_ever = re.search(r"\b(toi|minh)\s+tung\b", q_folded) is not None
self_for_me = any(s in q_folded for s in ('cho toi', 'cho minh', 'giup toi', 'giup minh', 'kiem tra toi', 'kiem tra minh'))

self_implied_raw = re.search(r'^(toi|minh)\s+(vao|va|co phai|duoc|biet|kiem tra|xem|check|co|con|da|tung|nhan|huong|cap|tang|dang|bi|tu|duoc)', q_folded) is not None
self_implied_data_start = re.search(r'^(diem|tieu chi|tong|so|muc|trung binh|cham|danh gia|xep loai|khop|khac|giong|so sanh|bang cong|don nghi|duyet)\b.*\b(toi|(?<!chi\s)minh)\b(?!\s+(thieu|da))', q_folded) is not None
is_luat2 = re.search(r'^(toi|minh)\s+(muon|can|de xuat)\s+(dang ky|gui|yeu cau|de xuat|mua|xin|lam|nop|khai bao)', q_folded) is not None
is_luat3 = re.search(r'^(toi|minh)\s+(duoc|co the|nen)\s+(nghi|phep|luong|phat|huong|duoc|quy dinh|chinh sach|su dung|dang ky|gui|yeu cau|thu tuc|quy trinh)', q_folded) is not None
self_implied = (self_implied_raw or self_implied_data_start) and not is_luat2 and not is_luat3

print(f'self_possessive: {self_possessive}')
print(f'self_possessive_extended: {self_possessive_extended}')
print(f'self_has: {self_has}')
print(f'self_doing_raw: {self_doing_raw}')
print(f'self_personal_data: {self_personal_data}')
print(f'self_ever: {self_ever}')
print(f'self_for_me: {self_for_me}')
print(f'self_time_data: {has_toi and has_time_ref and has_data_query}')
print(f'self_implied: {self_implied}')
print(f'self_anchored: {self_possessive or self_possessive_extended or self_has or self_doing_raw or self_personal_data or self_ever or self_for_me or (has_toi and has_time_ref and has_data_query) or self_implied}')
import sys
sys.path.insert(0, 'src')
import re

q = 'toi dang thuoc phong ban nao va giu chuc danh gi?'
q_fold = q.lower()

self_possessive = bool(re.search(r'\b(cua toi|cua minh|toi co|minh co|toi dang|minh dang|ca cua toi|phong ban cua toi|chuc danh cua toi|luong cua toi|phep cua toi|tang ca cua toi)\b', q_fold))
self_possessive_extended = any(k in q_fold for k in ('cua toi ', 'cua minh ', 'toi ', 'minh ', 'ta '))
self_has = any(k in q_fold for k in ('toi co ', 'minh co ', 'toi dang ', 'minh dang ', 'ta co ', 'ta dang '))
self_doing = bool(re.search(r'\b(toi (di|lam|nghi|check|xin|biet|muon|can|de|nghi|phep|duoc|co|nen)|minh (di|lam|nghi|check|xin|biet|muon|can|de|nghi|phep|duoc|co|nen))\b', q_fold))
self_personal_data = any(k in q_fold for k in ('phep cua toi', 'luong cua toi', 'tang ca cua toi', 'cham cong cua toi', 'ngay phep cua toi', 'gio tang ca cua toi', 'so ngay phep cua toi', 'ngay nghi cua toi', 'so tien luong cua toi', 'tien luong cua toi', 'thuong cua toi', 'phu cap cua toi', 'bao hiem cua toi', 'hop dong cua toi'))
self_ever = any(k in q_fold for k in ('toi tung', 'minh tung', 'toi da ', 'minh da ', 'toi chua', 'minh chua', 'tu truoc', 'tinh den nay', 'tu dau den', 'den hien tai', 'trong qua kh'))
self_for_me = any(k in q_fold for k in ('cho toi', 'cho minh', 'duoc cap', 'duoc huong', 'duoc nhan', 'duoc tang', 'duoc phep', 'duoc nghi', 'duoc luong'))
self_time_data = any(k in q_fold for k in ('hom nay', 'hien tai', 'ngay nao', 'gio nao', 'thang nay', 'nam nay', 'ngay mai', 'ngay kia', 'tuan nay', 'thang truoc', 'nam truoc', 'hien dang', 'dang lam', 'dang nghi', 'check-in', 'check-out', 'phiên dang nhap', 'session dang nhap', 'dang nhap hom nay'))
self_implied_raw = bool(re.search(r'^(toi|minh)\s+(nghi|phep|luong|thuong|phu cap|tang ca|cham cong|nghi phep|nghi le|bao hiem|hop dong|tai khoan|ngan hang|don nghi|don xin|phieu luong|tai san|thiet bi|may tinh|laptop|ticket|su co|may in|mang|phan mem|email|ngay sinh|ngay vao|so dien thoai|email ca nhan|nguoi lien he|ho so|nguoi lien he|tham nien|tham nien|vao cong ty|bao lau|bao lau)', q_fold))
self_implied_data_start = bool(re.search(r'^(toi|minh)\s+(duoc|co the|nen)\s+(nghi|phep|luong|phat|huong|duoc|quy dinh|chinh sach|su dung|dang ky|gui|yeu cau|thu tuc|quy trinh)', q_fold))
is_luat2 = re.search(r'^(toi|minh)\s+(muon|can|de xuat)\s+(dang ky|gui|yeu cau|de xuat|mua|xin|lam|nop|khai bao)', q_fold) is not None
is_luat3 = re.search(r'^(toi|minh)\s+(duoc|co the|nen)\s+(nghi|phep|luong|phat|huong|duoc|quy dinh|chinh sach|su dung|dang ky|gui|yeu cau|thu tuc|quy trinh)', q_fold) is not None
self_implied = (self_implied_raw or self_implied_data_start) and not is_luat2 and not is_luat3
self_anchored = self_possessive or self_possessive_extended or self_has or self_doing or self_personal_data or self_ever or self_for_me or self_time_data or self_implied

print('self_anchored:', self_anchored)

if self_anchored:
    is_policy_quantity = ('bao nhieu' in q_fold or 'bao nhieu ngay' in q_fold or 'bao nhieu gio' in q_fold) and any(p in q_fold for p in ('khi ', 'theo ', 'quy dinh', 'chinh sach', 'luat', 'to da', 'muc ', 'don gia'))
    is_role_policy = any(k in q_fold for k in ('hoi dong', 'ban kiem soat', 'ban dieu hanh', 'nguoi dieu hanh',
                                               'chuc danh', 'vi tri', 'nhom', 'to chuc', 'bo phan',
                                               'quyen han', 'quyen ', 'nghia vu', 'trach nhiem')) and \
                         any(k in q_fold for k in ('la gi', 'la j', 'gi la', 'j la', 'cay la', 'cai la',
                                               'the nao', 'thế nào', 'bao gom', 'co nhung', 'gom nhung',
                                               'dinh nghia', 'tieu chuan', 'bang cap', 'tieu chi',
                                               'gi ', 'gi?', 'cach nao', 'nhu the nao', 'lam sao',
                                               'co gi', 'nhung gi', 'nhung quyen', 'quyen gi',
                                               'nghia vu gi', 'trach nhiem gi'))
    print('is_policy_quantity:', is_policy_quantity)
    print('is_role_policy:', is_role_policy)
    if not is_policy_quantity and not is_role_policy:
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
        if any(k in q_fold for k in personal_data_keywords):
            print('-> Would return DB_ONLY')
        else:
            print('-> No personal data keyword match')
    else:
        print('-> Skipped due to policy')
else:
    print('-> Not self_anchored')
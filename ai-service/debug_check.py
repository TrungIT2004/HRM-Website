import sys
sys.path.insert(0, 'src')

q = 'Toi la nhan vien chinh thuc ky hop dong tu 6 thang tro len t...'
q_fold = q.lower()

# Check personal_data_keywords
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

# Check what matches
matches = [k for k in personal_data_keywords if k in q_fold]
print(f'Personal data keyword matches: {matches}')

# Check is_policy_quantity
is_policy_quantity = ('bao nhieu' in q_fold or 'bao nhieu ngay' in q_fold or 'bao nhieu gio' in q_fold) and any(p in q_fold for p in ('khi ', 'theo ', 'quy dinh', 'chinh sach', 'luat', 'to da', 'muc ', 'don gia'))
print(f'is_policy_quantity: {is_policy_quantity}')

# Check is_role_policy
is_role_policy = False
if not any(s in q_fold for s in ('cua toi', 'cua minh', 'cua tui', 'cua em', 'cua ta',
                             'toi co', 'minh co', 'toi con', 'minh con',
                             'toi dang', 'minh dang', 'toi la', 'minh la')):
    is_role_policy = any(k in q_fold for k in ('hoi dong', 'ban kiem soat', 'ban dieu hanh', 'nguoi dieu hanh',
                                                   'chuc danh', 'vi tri', 'nhom', 'to chuc', 'bo phan',
                                                   'quyen han', 'quyen ', 'nghia vu', 'trach nhiem')) and \
                             any(k in q_fold for k in ('la gi', 'la j', 'gi la', 'j la', 'cay la', 'cai la',
                                                   'the nao', 'thế nào', 'bao gom', 'co nhung', 'gom nhung',
                                                   'dinh nghia', 'tieu chuan', 'bang cap', 'tieu chi',
                                                   'cach nao', 'nhu the nao', 'lam sao',
                                                   'co gi', 'nhung gi', 'nhung quyen', 'quyen gi',
                                                   'nghia vu gi', 'trach nhiem gi'))
print(f'is_role_policy: {is_role_policy}')

# Check LUẬT 4 (DOC_ONLY) - priority 6
is_definition_q = any(k in q_fold for k in ('tieu chuan', 'bang cap', 'tieu chi', 'bao gom', 'chuc danh', 'dinh nghia',
                                            'la gi', 'la j', 'la cay', 'la cai', 'gi la', 'j la', 'cay la', 'cai la',
                                            'the nao', 'thế nào', 'la mot', 'là một', 'la 1', 'la 2', 'la 3',
                                            'truong phong', 'giam doc', 'pho giam doc', 'tong giam doc', 'ceo', 'chu tich',
                                            'truong ban', 'chu tich ban', 'thanh vien', 'thanh vien ban', 'nguoi dieu hanh',
                                            'ban kiem soat', 'ban dieu hanh', 'hoi dong quan tri', 'hoi dong',
                                            'phong ban', 'bo phan', 'to chuc', 'co quan', 'don vi', 'cong ty', 'cong ty co phan',
                                            'nguoi lao dong', 'nld', 'nhan vien', 'can bo', 'khu vuc', 'mien', 'tinh', 'huyen', 'xa'))
print(f'is_definition_q: {is_definition_q}')
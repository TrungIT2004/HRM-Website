import sys
sys.path.insert(0, '.')
sys.stdout.reconfigure(encoding='utf-8')
import re
import importlib
import src.sql.router
importlib.reload(src.sql.router)
from src.sql.router import keyword_fallback, _fold, fold_case

# Test case 1: departments_04
q = 'toi vao cong ty khi nao va hien dang o phong ban nao'
print('=== departments_04 ===')
result = keyword_fallback(q)
print(f'Result: {result}')

# Let me add debug prints to the actual function by creating a wrapper
# Actually, let me just trace through step by step by checking what happens at each priority

# The function has this priority order:
# 0. HYBRID (LUẬT 6) - checked first
# 1. LUẬT 1 -> DB_ONLY
# 2. LUẬT 2 -> DOC_ONLY
# 3. LUẬT 3 -> DOC_ONLY
# 4. LUẬT 8 -> OUT_OF_SCOPE
# 5. LUẬT 7 -> DIRECTORY
# 6. Document reference patterns -> DOC_ONLY/DIRECTORY
# 7. Directory keywords -> DIRECTORY/OUT_OF_SCOPE
# 8. LUẬT 4 -> DOC_ONLY
# 9. LUẬT 5 -> DOC_ONLY
# 10. LUẬT 6 (fallback) -> HYBRID
# 11. Default -> DB_ONLY/DOC_ONLY

# Let me check if LUẬT 4 is matching
q_folded = _fold(q)
print(f'q_folded: {q_folded}')

# LUẬT 4 keywords
luat4_keywords = ("tieu chuan", "bang cap", "tieu chi", "bao gom", "chuc danh", "dinh nghia",
                            "la gi", "la j", "la cay", "la cai", "gi la", "j la", "cay la", "cai la",
                            "the nao", "thế nào", "la mot", "là một", "la 1", "la 2", "la 3",
                            "truong phong", "giam doc", "pho giam doc", "tong giam doc", "ceo", "chu tich",
                            "nguoi dieu hanh", "nguoi quan ly", "quan ly")

# Check if any LUẬT 4 keyword matches
for k in luat4_keywords:
    if k in q_folded:
        print(f'LUẬT 4 keyword match: {k}')

# Check if "cua toi" in q
print(f'"cua toi" in q: {"cua toi" in q_folded}')
print(f'"cua minh" in q: {"cua minh" in q_folded}')

# LUẬT 5 keywords
doc5_keywords = ("quy dinh", "quy trinh", "don gia", "gia ", "cach tinh", "muc luong",
                     "quyet dinh", "quy che", "noi quy", "luat", "van ban", "ban van",
                     "dieu kien", "dinh muc", "mau don", "bieu mau", "chuan muc",
                     "quy che luong", "quy che thuong", "chinh sach",
                     "nghi phep", "lich", "truc", "dieu phoi", "phan cong", "danh sach",
                     "liet ke", "duoc dieu", "da dieu", "xin nghi", "bao nhieu ngay",
                     "bao nhieu gio", "muc", "dinh muc", "chuan",
                     "can cu", "can cu vao", "phu cap", "phucap",
                     "thai san", "thai sản", "lao dong nu", "lao động nữ", "nghi thai san", "nghỉ thai sản",
                     "truoc khi sinh", "trước khi sinh", "tối đa", "to da ")
for k in doc5_keywords:
    if " " in k:
        if k in q_folded:
            print(f'LUẬT 5 keyword match (multi): {k}')
    else:
        if re.search(r"\b" + re.escape(k) + r"\b", q_folded):
            print(f'LUẬT 5 keyword match (single): {k}')
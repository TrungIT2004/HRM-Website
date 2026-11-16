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

# Check policy_specific patterns
q_folded = _fold(q)
policy_specific = ("muc ", "trung binh", "to thieu", "to da ", "thuong ", "ho tro ", "muc ho tro")
for k in policy_specific:
    match = re.search(r"\b" + re.escape(k).rstrip() + r"\b", q_folded)
    if match:
        print(f'policy_specific match: {k} at {match.span()}')

# Check _DB_KEYWORDS and _DOC_KEYWORDS
from src.sql.router import _DB_KEYWORDS, _DOC_KEYWORDS
print(f'\n_DB_KEYWORDS matches:')
for k in _DB_KEYWORDS:
    if _fold(k) in q_folded:
        print(f'  {k}')

print(f'\n_DOC_KEYWORDS matches:')
for k in _DOC_KEYWORDS:
    if _fold(k) in q_folded:
        print(f'  {k}')
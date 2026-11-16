import unicodedata

# Check Đ normalization
s = 'Đ'  # Đ
s2 = 'đ'  # đ

print('D NFD:', [c for c in unicodedata.normalize('NFD', s)])
print('D category:', [unicodedata.category(c) for c in unicodedata.normalize('NFD', s)])
print('d NFD:', [c for c in unicodedata.normalize('NFD', s2)])
print('d category:', [unicodedata.category(c) for c in unicodedata.normalize('NFD', s2)])

# Test norm_text equivalent
def norm_text_test(s: str) -> str:
    import re
    _DASHES = str.maketrans({"‐": "-", "‑": "-", "‒": "-", "–": "-", "—": "-", "−": "-"})
    s = re.sub(r"\s+", " ", str(s or "")).strip().lower().translate(_DASHES)
    return "".join(c for c in unicodedata.normalize("NFD", s)
                   if unicodedata.category(c) != "Mn")

print('norm_text(Đ):', norm_text_test('Đ'))
print('norm_text(đ):', norm_text_test('đ'))
print('norm_text(QĐ-ACT):', norm_text_test('QĐ-ACT'))
print('norm_text(QD-ACT):', norm_text_test('QD-ACT'))
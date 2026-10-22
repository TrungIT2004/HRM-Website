"""Bake-off sach: 1 model/process, sanity identical=1.0 (one-shot)."""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dotenv import load_dotenv

load_dotenv()
from src.db.session import get_db_connection
from src.embeddings.local_embedder import LocalEmbedder

E = LocalEmbedder()
m = E.model
print("model:", E.model_name)

c = get_db_connection()
cur = c.cursor()
IDS = ['9fa35ecb-1107-48f7-ac57-80cce8366555', '6b29940a-972e-4803-8f64-7692a89431bd',
       'dbdbf44e-7b1f-4669-97ed-7d800c406301', '5e0ae774-251a-4394-80d0-03abb4388f8b']
cur.execute("SELECT id, LEFT(content, 60) FROM document_chunks WHERE id = ANY(%s::uuid[]);", (IDS,))
print("fetched:", [(str(i)[:8], t[:40]) for i, t in cur.fetchall()])
cur.execute("SELECT id, content FROM document_chunks WHERE id = ANY(%s::uuid[]);", (IDS,))
by_id = {str(i): t.strip() for i, t in cur.fetchall()}
ch917, chvpp, chluong, chmwg = (by_id[i] for i in IDS)
cur.close()
c.close()


def cos(a, b, pa=None, pb=None):
    import numpy as np
    kw = dict(show_progress_bar=False, normalize_embeddings=True)
    va = m.encode(a.strip(), prompt_name=pa, **kw) if pa else m.encode(a.strip(), **kw)
    vb = m.encode(b.strip(), prompt_name=pb, **kw) if pb else m.encode(b.strip(), **kw)
    return float(np.asarray(va).flatten() @ np.asarray(vb).flatten())


s = ch917[:200]
print("sanity identical: %.3f" % cos(s, s))
PAIRS = [
    ("Hết xe thì sao?", ch917),
    ("Máy tính Casio FX-570VN Plus giá bao nhiêu?", chvpp),
    ("02 năm đó tính từ khi nào?", chluong),
    ("Miễn nhiệm khi nào?", chmwg),
    ("Cổ đông 5% được đề cử mấy người?", chmwg),
]
PROMPTS = [k for k in (list((m.prompts or {}).keys()) if hasattr(m, "prompts") else [])]
print("prompts:", PROMPTS)
for q, ch in PAIRS:
    line = "plain %.3f" % cos(q, ch)
    for pq, pd in (("Retrieval-query", "Retrieval-document"), ("query", "document")):
        if pq in PROMPTS and pd in PROMPTS:
            try:
                line += " | %s/%s %.3f" % (pq, pd, cos(q, ch, pq, pd))
            except Exception as e:
                line += " | %s ERR" % pq
    print("%-8s %s | %s" % ("", q[:40], line))

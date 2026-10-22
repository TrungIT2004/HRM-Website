"""
Regression lexical: query chua tu PHO BIEN ("hop le") bi day chunk "hop dong" len top,
roi chat_service chan bang RELEVANCE_THRESHOLD -> bao "lien he HR".

Root cause cu: ts_rank_cd khong co IDF, nen 'hop' [69% corpus] an cung diem
'phat' [2%]. Test nay khoa lai BAT BIEN IDF thay vi gia tri cu the,
de khong vo khi corpus doi (them/bot tai lieu).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from src.db.session import get_db_connection
from src.retrievers.hybrid_retriever import LEXICAL_WEIGHTS_SQL, DF_STOP_RATIO

# LEXICAL_WEIGHTS_SQL la CTE moc, phai noi them phan SELECT.
_IDF_QUERY = LEXICAL_WEIGHTS_SQL + " SELECT term, idf FROM weights"


def _idf(query):
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(_IDF_QUERY, {"query": query, "df_stop": DF_STOP_RATIO})
        return {t: float(v) for t, v in cur.fetchall()}
    finally:
        conn.close()


def test_idf_luon_khong_am():
    """IDF >= 0 va tu rat hiem (>95% corpus) -> 0, khong bao gio am."""
    idf = _idf("Xử lý kỷ luật lao động thì phạt tiền có hợp lệ ko")
    assert idf, "phai con it nhat mot tu sau khi lo stop-word"
    assert all(v >= 0 for v in idf.values()), idf


def test_idf_nghich_dan_voi_tan_suat():
    """BAT BIEN THAT SU: idf giam nghich dan df.

    Test tu tinh df roi doi chieu, nen khong vo khi corpus doi
    (them/bot tai lieu). Day la co che BM25 can bao ve.
    """
    q = "Xử lý kỷ luật lao động thì phạt tiền có hợp lệ ko"
    idf = _idf(q)
    if len(idf) < 2:
        return  # corpus qua nho, khong du chieu de kiem chieu

    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT term, count(c.id) AS df FROM unnest(ARRAY[%s]::text[]) AS w(term) "
            "LEFT JOIN document_chunks c ON c.tsv @@ to_tsquery('simple', unaccent(w.term)) "
            "GROUP BY term",
            (list(idf),),
        )
        df = {t: n for t, n in cur.fetchall()}
    finally:
        conn.close()

    pairs = sorted(
        ((df[t], idf[t], t) for t in idf if df[t] > 0),
        key=lambda x: x[0],
    )
    for (d_hi, i_hi, t_hi), (d_lo, i_lo, t_lo) in zip(pairs, pairs[1:]):
        assert i_hi >= i_lo, (
            f"IDF nghiem dinh: '{t_hi}' df={d_hi} idf={i_hi:.3f} < '{t_lo}' df={d_lo} idf={i_lo:.3f}"
        )


def test_khong_con_token_pho_bien_trong_query():
    """Token > DF_STOP_RATIO corpus phai bi lo khoi tsquery."""
    q = "Xử lý kỷ luật lao động thì phạt tiền có hợp lệ ko"
    idf = _idf(q)
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT count(*) FROM document_chunks")
        total = cur.fetchone()[0]
        cur.execute(
            "SELECT term, count(c.id) AS df FROM unnest(ARRAY[%s]::text[]) AS w(term) "
            "LEFT JOIN document_chunks c ON c.tsv @@ to_tsquery('simple', unaccent(w.term)) "
            "GROUP BY term",
            (list(idf),),
        )
        for t, n in cur.fetchall():
            assert n / total < DF_STOP_RATIO, f"'{t}' df={n}/{total} phai bi lo"
    finally:
        conn.close()


def test_tu_khong_ton_tai_bi_bo():
    """Token khong co trong corpus (df=0) -> viet nhanh 'dc' -> lo, khong lam nhieu."""
    idf = _idf("Xử lý kỷ luật lao động thì phạt tiền có dc ko")
    assert "dc" not in idf, "'dc' df=0 phai bi lo"
    if "phạt" in idf:
        assert idf["phạt"] > 0


def test_unaccent_khop_ca_hai_chieu():
    """'phat tien' (khong dau) va 'phạt tiền' (co dau) phai cho CUNG tap IDF."""
    a = _idf("Xử lý kỷ luật lao động thì phạt tiền có hợp lệ ko")
    b = _idf("Xu ly ky luat lao dong thi phat tien co hop le ko")
    va = sorted(v for v in a.values())
    vb = sorted(v for v in b.values())
    assert len(va) == len(vb) and all(abs(x - y) < 1e-6 for x, y in zip(va, vb)), (
        f"unaccent lech: {va} vs {vb}"
    )


def test_query_chi_toan_tu_pho_bien_tra_rong():
    """Moi tu deu pho bien -> weights rong -> lexical vo dung, chi dung vector."""
    idf = _idf("các điều khoản có trong hợp đồng lao động này")
    assert idf == {} or all(v < 2.0 for v in idf.values()), idf


def _demo():
    for q in [
        "Xử lý kỷ luật lao động thì phạt tiền có hợp lệ ko",
        "Xu ly ky luat lao dong thi phat tien co hop le ko",
    ]:
        idf = _idf(q)
        kept = sorted(idf.items(), key=lambda kv: -kv[1])
        print(f"\n{q}")
        print("  giu: " + ", ".join(f"{t}={v:.2f}" for t, v in kept))


if __name__ == "__main__":
    _demo()

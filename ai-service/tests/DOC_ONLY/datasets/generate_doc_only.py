"""Sinh dataset DOC_ONLY 120 cau (12/file x 10 files) tu chunk THAT trong DB.

Dung key hien tai (.env OLLAMA_*). Judge sau doi key moi.
Schema 10 truong: id, question, ground_truth(draft, CAN review tay),
reference_contexts, relevant_chunk_ids, category, source_file,
conversation_id, turn_index/history, rewrite_expected, allowed_jobs/departments.

Chay tu ai-service:
    python tests/DOC_ONLY/datasets/generate_doc_only.py --dry-run   # khong goi LLM, check sample
    python tests/DOC_ONLY/datasets/generate_doc_only.py              # 120 calls LLM
    python tests/DOC_ONLY/datasets/generate_doc_only.py --per-file 2 # test nhanh 20 cau
Output: tests/DOC_ONLY/datasets/doc_only_120.json + .csv (utf-8-sig cho Excel)
"""
import argparse
import csv
import json
import os
import re
import sys
import time
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

OUT_DIR = Path(__file__).resolve().parent
OUT_JSON = OUT_DIR / "doc_only_120.json"
OUT_CSV = OUT_DIR / "doc_only_120.csv"

CATEGORIES = ("nghi_phep,luong_thuong,hop_dong,noi_quy_ky_luat,"
              "bo_nhiem_quan_tri,xe_cong_tac,van_phong_pham,"
              "bao_hiem_phuc_loi,thoi_gian_lam_viec,khac")

GEN_PROMPT = """Ban la nguoi soan bo test cho he RAG nhan su. Doc DOAN TAI LIEU va tra ve JSON:
{{"question": "<1 cau hoi nhan vien that su hoi, tieng Viet co dau, tra loi duoc CHI tu doan>",
"answer_draft": "<dap an ngan gon CHI tu doan, <80 tu. Doan thieu thong tin thi ghi dung: THIEU THONG TIN>",
"category": "<1 trong: {cats}>"}}
BAT BUOC: chi 1 object duy nhat {{...}}, KHONG mang [...], khong markdown, khong giai thich.

--- DOAN TAI LIEU ---
{content}
--- HET ---"""


def parse_json(text: str) -> dict | None:
    """Nhan ca object don lan mang [{...},{...}] (LLM hay tra mang du prompt
    cam) — lay phan tu dau co du question/answer_draft."""
    t = (text or "").strip()
    t = re.sub(r"^```(?:json)?\s*|\s*```$", "", t, flags=re.S).strip()
    try:
        d = json.loads(t)
        if isinstance(d, list):
            for item in d:
                if isinstance(item, dict) and item.get("question") and item.get("answer_draft"):
                    return item
            return None
        if isinstance(d, dict) and d.get("question") and d.get("answer_draft"):
            return d
    except Exception:
        pass
    # fallback: boc object dau tien (non-greedy) khi JSON bi cat duoi
    for m in re.finditer(r"\{.*?\}", t, flags=re.S):
        try:
            d = json.loads(m.group(0))
            if d.get("question") and d.get("answer_draft"):
                return d
        except Exception:
            continue
    return None


def sample_even(rows: list, n: int) -> list:
    if len(rows) <= n:
        return rows
    step = len(rows) / n
    return [rows[int(i * step)] for i in range(n)]


def fetch_chunks():
    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT id, file_name FROM knowledge_documents WHERE status='COMPLETED'"
            " ORDER BY file_name;")
        docs = cur.fetchall()
        per_file = {}
        for did, fname in docs:
            cur.execute(
                "SELECT c.id, c.chunk_index, c.content, c.breadcrumb,"
                " c.allowed_jobs, c.allowed_departments"
                " FROM document_chunks c WHERE c.document_id=%s"
                " AND char_length(c.content) >= 200 ORDER BY c.chunk_index;",
                (str(did),))
            per_file[fname] = cur.fetchall()
        return per_file
    finally:
        cur.close()
        conn.close()


def llm_row(client, model: str, content: str) -> dict | None:
    for _ in range(2):  # retry 1 lan
        try:
            res = client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": GEN_PROMPT.format(
                    cats=CATEGORIES, content=(content or "")[:2500])}],
                temperature=0.7,
                timeout=90,
            )
            d = parse_json(res.choices[0].message.content)
            if d and d.get("question") and d.get("answer_draft"):
                return d
        except Exception as e:
            print(f"  [llm loi] {type(e).__name__}: {e}"[:150], flush=True)
            time.sleep(3)
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--per-file", type=int, default=12,
                    help="Chi dung khi --total=0 (legacy).")
    ap.add_argument("--total", type=int, default=120,
                    help="Tong cau muc tieu, chia deu co tran (file mong lay het).")
    ap.add_argument("--dry-run", action="store_true",
                    help="Chi sample chunk, khong goi LLM.")
    args = ap.parse_args()

    per_file = fetch_chunks()
    print(f"[gen] {len(per_file)} files trong DB:")
    for f, rows in per_file.items():
        print(f"  {f}: {len(rows)} chunks du dai")

    if args.total and args.total > 0:
        # ponytail: file mong (214:3, 917:5, payrolls:1) lay het, phan con lai
        # chia deu co tran thay vi cung 12/file (khong du 120).
        names = sorted(per_file, key=lambda f: len(per_file[f]))
        quotas, remaining = {}, args.total
        for i, f in enumerate(names):
            left = len(names) - i
            q = min(len(per_file[f]), -(-remaining // left))  # ceil
            quotas[f] = q
            remaining -= q
        sampled = {f: sample_even(per_file[f], quotas[f]) for f in names}
        print(f"[gen] quota: {quotas}")
    else:
        sampled = {f: sample_even(rows, args.per_file) for f, rows in per_file.items()}
    total = sum(len(v) for v in sampled.values())
    print(f"[gen] sample {args.per_file}/file -> {total} chunks")

    if args.dry_run:
        for f, rows in sampled.items():
            for r in rows[:1]:
                print(f"  [{f}] chunk#{r[1]}: {(r[2] or '')[:100]}...".replace("\n", " "))
        print("[dry-run] OK, khong goi LLM.")
        return

    from openai import OpenAI
    client = OpenAI(
        base_url=os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1"),
        api_key=os.getenv("OLLAMA_API_KEY", "ollama"),
    )
    model = os.getenv("OLLAMA_MODEL", "gemma4:31b")
    print(f"[gen] model={model} key=...{os.getenv('OLLAMA_API_KEY', '')[-4:]}")

    rows_out, idx, n_fail = [], 0, 0
    for fname, chunks in sorted(sampled.items()):
        for cid, cidx, content, crumb, jobs, depts in chunks:
            idx += 1
            print(f"[{idx}/{total}] {fname} chunk#{cidx}", flush=True)
            d = llm_row(client, model, content)
            if not d:
                n_fail += 1
                continue
            rows_out.append({
                "id": f"D{idx:03d}",
                "question": d["question"].strip(),
                "ground_truth": d["answer_draft"].strip(),
                "needs_review": True,
                "reference_contexts": [(content or "").strip()[:2000]],
                "relevant_chunk_ids": [str(cid)],
                "category": (d.get("category") or "khac").strip(),
                "source_file": fname,
                "breadcrumb": crumb or "",
                "conversation_id": None,
                "turn_index": 1,
                "history": [],
                "rewrite_expected": "",
                "allowed_jobs": list(jobs or ["ALL"]),
                "allowed_departments": list(depts or ["ALL"]),
            })
            time.sleep(1)  # tranh rate-limit cloud

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(rows_out, ensure_ascii=False, indent=2), encoding="utf-8")
    with open(OUT_CSV, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=[
            "id", "question", "ground_truth", "needs_review", "category",
            "source_file", "breadcrumb", "relevant_chunk_ids",
            "allowed_jobs", "allowed_departments", "reference_contexts"])
        w.writeheader()
        for r in rows_out:
            w.writerow({k: (json.dumps(v, ensure_ascii=False) if isinstance(v, list) else v)
                        for k, v in r.items() if k in w.fieldnames})
    print(f"\n[gen] xong {len(rows_out)}/{total} (fail {n_fail})")
    print(f"  JSON: {OUT_JSON}\n  CSV : {OUT_CSV}")
    print("BAT BUOC: mo CSV review cot ground_truth, nhat la luong/quyen loi, truoc khi do.")


if __name__ == "__main__":
    main()

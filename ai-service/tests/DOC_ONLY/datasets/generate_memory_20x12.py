"""Sinh dataset MEMORY 20 conv x 12 turn (follow-up chuyen sau) tu chunk THAT trong DB.

Dung key JUDGE (.env OLLAMA_JUDGE_*) de tach biet voi key RAG cu.
Moi conv bam 1 cum tai lieu (xe/luong/VPP/EVN/MWG/PMSC/BLLD), 12 turn hoi xoay
sau: turn1 doc lap, turn2+ dung dai tu/luoc bo (no/cai do/truong hop nay/
con ... thi sao) + rewrite_expected la cau viet lai doc lap.
Dap an CHI tu context pool, <80 tu, thieu thi ghi dung: THIEU THONG TIN.

Schema moi turn GIONG doc_only_120.json + them:
  conversation_id=M01..M20, turn_index=1..12,
  history=[{role:USER/ASSISTANT, content}...] (gold turns truoc),
  rewrite_expected (turn1 = question), id=M01T01..M20T12.

Verify: 1 call Judge full-context/conv cham faithfulness tung turn.

Chay tu ai-service:
    python tests/DOC_ONLY/datasets/generate_memory_20x12.py --dry-run
    python tests/DOC_ONLY/datasets/generate_memory_20x12.py --limit 1   # 1 conv that
    python tests/DOC_ONLY/datasets/generate_memory_20x12.py             # full 20 conv
    python tests/DOC_ONLY/datasets/generate_memory_20x12.py --conv M05  # lam lai 1 conv
Output: doc_only_memory_20x12.json + .csv (utf-8-sig cho Excel)
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
load_dotenv(Path(__file__).resolve().parent.parent.parent.parent / ".env")

OUT_DIR = Path(__file__).resolve().parent
OUT_JSON = OUT_DIR / "doc_only_memory_20x12.json"
OUT_CSV = OUT_DIR / "doc_only_memory_20x12.csv"

# 20 conv follow-up chuyen sau, phu deu corpus (214+917 gop vi mong).
CONV_SPECS = [
    {"conv": "M01", "topic": "Dang ky xe di cong tac dot xuat va theo tuan", "subs": ["214.HD", "917.Q"], "category": "xe_cong_tac"},
    {"conv": "M02", "topic": "Dieu phoi xe, thue ngoai va trach nhiem su dung", "subs": ["917.Q"], "category": "xe_cong_tac"},
    {"conv": "M03", "topic": "Can cu ban hanh quy che luong thuong", "subs": ["sanKeToan"], "category": "luong_thuong"},
    {"conv": "M04", "topic": "Cach tinh luong co ban theo luong toi thieu vung x he so", "subs": ["sanKeToan"], "category": "luong_thuong"},
    {"conv": "M05", "topic": "Phu cap HQCV: cong thuc va danh gia hoan thanh", "subs": ["sanKeToan"], "category": "luong_thuong"},
    {"conv": "M06", "topic": "Phan phoi luong thuong theo ket qua SXKD va dong gop", "subs": ["sanKeToan"], "category": "luong_thuong"},
    {"conv": "M07", "topic": "Quy trinh quan ly van phong pham", "subs": ["QT.ACT"], "category": "van_phong_pham"},
    {"conv": "M08", "topic": "Gia bao thu va vat tu van phong trong bang BM01", "subs": ["QT.ACT"], "category": "van_phong_pham"},
    {"conv": "M09", "topic": "Dinh muc cap phat va su dung van phong pham", "subs": ["QT.ACT"], "category": "van_phong_pham"},
    {"conv": "M10", "topic": "HĐQT EVN Finance trinh ĐHDCD ban hanh quy che noi bo", "subs": ["EVNFinance"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M11", "topic": "Nguoi dieu hanh va Ban kiem soat EVN Finance", "subs": ["EVNFinance"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M12", "topic": "Hop HĐQT EVN Finance: trieu tap va bieu quyet", "subs": ["EVNFinance"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M13", "topic": "Thong bao moi hop ĐHDCD MWG", "subs": ["MWG"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M14", "topic": "HĐQT va Ban kiem soat MWG", "subs": ["MWG"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M15", "topic": "Quyen co dong va the thuc hop MWG", "subs": ["MWG"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M16", "topic": "Quan tri PMSC: HĐQT va quy che noi bo", "subs": ["Petrol"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M17", "topic": "BKS PMSC xu ly vi pham cua HĐQT/TGĐ", "subs": ["Petrol"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M18", "topic": "Hop ĐHDCD PMSC: trieu tap va bieu quyet", "subs": ["Petrol"], "category": "bo_nhiem_quan_tri"},
    {"conv": "M19", "topic": "Thoi gian lam viec, nghi phep theo Bo luat Lao dong", "subs": ["bo-luat-lao-dong"], "category": "thoi_gian_lam_viec"},
    {"conv": "M20", "topic": "Hop dong va tien luong theo Bo luat Lao dong", "subs": ["bo-luat-lao-dong"], "category": "hop_dong"},
]

DRAFT_PROMPT = """Ban la nguoi soan bo test MEMORY cho he RAG nhan su (tieng Viet co dau).
Chu de hoi thoai: {topic}
Tu TAI LIEU duoi day, viet HOI THOAI 12 turn hoi XOAY SAU 1 chu de (follow-up chuyen sau).

BAT BUOC:
- Turn1 la cau hoi doc lap day du (neu ro ten van ban/con so chu de).
- Turn2-12 la cau noi tiep: DUNG dai tu ("no", "cai do", "quy dinh nay", "truong hop nay",
  "muc nay", "con ... thi sao?", "vay bao lau?", "ai ky?") hoac luoc bo chu ngu,
  BAT BUOC can lich su moi hieu. Khong lap lai nguyen cau turn1.
- rewrite_expected: cau viet lai DOC LAP (khoi phuc day du thuc the tu lich su).
  Turn1 thi rewrite_expected = question.
- answer_draft: tra loi NGAN GON (<80 tu) CHI tu TAI LIEU. Tai lieu thieu thi ghi dung:
  THIEU THONG TIN. Khong suy dien, khong them kien thuc ngoai.
- 12 turn phai leo thang: mo dau -> chi tiet -> so sanh/moc thoi gian/trach nhiem -> chot lai.
- Tra ve JSON THUAN: mang 12 object [{{"question": "...", "answer_draft": "...",
  "rewrite_expected": "..."}}, ...]. KHONG markdown, khong giai thich.

--- TAI LIEU ---
{content}
--- HET ---"""

VERIFY_PROMPT = """Ban la giam khao faithfulness (tieng Viet). Cho HOI THOAI 12 turn va TAI LIEU.
Voi moi turn, kiem tra answer_draft co duoc TAI LIEU ho tro HOAN TOAN khong.
Tra JSON thuan: {{"turns": [{{"turn": 1, "ok": true/false, "note": "<ngan gon>"}}]}}.
Gat: bat ky chi tiet nao (so, ngay, ten, chuc danh) khong co trong TAI LIEU -> ok=false.

--- TAI LIEU ---
{content}
--- HOI THOAI ---
{conv}
--- HET ---"""


def parse_array(text: str):
    t = (text or "").strip()
    t = re.sub(r"^```(?:json)?\s*|\s*```$", "", t, flags=re.S).strip()
    try:
        d = json.loads(t)
        if isinstance(d, list) and len(d) >= 10:
            return d
    except Exception:
        pass
    m = re.search(r"\[.*\]", t, flags=re.S)
    if m:
        try:
            d = json.loads(m.group(0))
            if isinstance(d, list):
                return d
        except Exception:
            pass
    return None


def parse_verify(text: str):
    t = (text or "").strip()
    t = re.sub(r"^```(?:json)?\s*|\s*```$", "", t, flags=re.S).strip()
    for cand in (t, (re.search(r"\{.*\}", t, flags=re.S) or [None])[0] if re.search(r"\{.*\}", t, flags=re.S) else None):
        if not cand:
            continue
        try:
            d = json.loads(cand)
            if isinstance(d.get("turns"), list):
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


def pool_for_spec(per_file: dict, subs: list, n: int = 3, slot: int = 0, slots: int = 1):
    rows = []
    for fname, chunks in sorted(per_file.items()):
        if any(s in fname for s in subs):
            for cid, cidx, content, crumb, jobs, depts in chunks:
                rows.append({"fname": fname, "cid": str(cid), "cidx": cidx,
                             "content": (content or "").strip(),
                             "crumb": crumb or "", "jobs": list(jobs or ["ALL"]),
                             "depts": list(depts or ["ALL"])})
    rows.sort(key=lambda r: (r["fname"], r["cidx"]))
    if not rows:
        return []
    # ponytail: chia rows thanh `slots` phan theo conv thu `slot` de conv cung
    # nguon (vd 4 conv luong) khong dung trung 3 chunk -> hoi thoai khong trung lap.
    if slots > 1 and len(rows) > n:
        part = rows[slot::slots] or rows
        return sample_even(part, min(n, len(part)))
    return sample_even(rows, n)


def draft_conv(client, model: str, spec: dict, pool: list):
    content = "\n---\n".join(f"[{p['fname']} #{p['cidx']}]\n{p['content'][:1500]}" for p in pool)
    for _ in range(2):
        try:
            res = client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": DRAFT_PROMPT.format(
                    topic=spec["topic"], content=content[:6000])}],
                temperature=0.7, timeout=180)
            arr = parse_array(res.choices[0].message.content)
            if arr and len(arr) >= 10:
                # chuan hoa 12 turn (cat/du cham o day, giu 12 dau)
                out = []
                for t in arr[:12]:
                    q = str(t.get("question", "")).strip()
                    a = str(t.get("answer_draft", "")).strip()
                    rw = str(t.get("rewrite_expected", "")).strip() or q
                    if q and a:
                        out.append({"question": q, "answer_draft": a, "rewrite_expected": rw})
                if len(out) >= 10:
                    return out
        except Exception as e:
            print(f"  [draft loi] {type(e).__name__}: {e}"[:160], flush=True)
            time.sleep(3)
    return None


def verify_conv(client, model: str, pool: list, turns: list):
    content = "\n---\n".join((p["content"] or "")[:1500] for p in pool)[:6000]
    conv = "\n".join(f"T{i+1} Q: {t['question']}\nT{i+1} A: {t['answer_draft']}"
                     for i, t in enumerate(turns))
    try:
        res = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": VERIFY_PROMPT.format(
                content=content, conv=conv[:6000])}],
            temperature=0.0, timeout=180)
        return parse_verify(res.choices[0].message.content)
    except Exception as e:
        print(f"  [verify loi] {type(e).__name__}: {e}"[:160], flush=True)
        return None


def build_rows(spec: dict, pool: list, turns: list):
    main_file = pool[0]["fname"] if pool else ""
    jobs = pool[0]["jobs"] if pool else ["ALL"]
    depts = pool[0]["depts"] if pool else ["ALL"]
    ref_ctx = [(p["content"] or "")[:2000] for p in pool]
    chunk_ids = [p["cid"] for p in pool]
    crumb = pool[0]["crumb"] if pool else ""
    rows = []
    hist = []
    for i, t in enumerate(turns):
        rows.append({
            "id": f"{spec['conv']}T{i+1:02d}",
            "question": t["question"],
            "ground_truth": t["answer_draft"],
            "needs_review": True,
            "reference_contexts": ref_ctx,
            "relevant_chunk_ids": chunk_ids,
            "category": spec["category"],
            "source_file": main_file,
            "breadcrumb": crumb,
            "conversation_id": spec["conv"],
            "turn_index": i + 1,
            "history": [dict(h) for h in hist],
            "rewrite_expected": t["rewrite_expected"],
            "allowed_jobs": jobs,
            "allowed_departments": depts,
        })
        hist.append({"role": "USER", "content": t["question"]})
        hist.append({"role": "ASSISTANT", "content": t["answer_draft"]})
    return rows


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=20)
    ap.add_argument("--conv", type=str, default=None)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--skip-verify", action="store_true")
    args = ap.parse_args()

    per_file = fetch_chunks()
    print(f"[mem] {len(per_file)} files trong DB:")
    for f, rows in sorted(per_file.items()):
        print(f"  {f}: {len(rows)} chunks")

    specs = list(CONV_SPECS)
    if args.conv:
        specs = [s for s in specs if s["conv"] == args.conv.upper()]
        if not specs:
            print(f"[mem] khong thay conv {args.conv}")
            return
    specs = specs[: args.limit]

    pools = {}
    from collections import Counter
    seen = Counter()
    for s in specs:
        key = tuple(s["subs"])
        slot = seen[key]
        # dem tong so conv cung nguon trong full CONV_SPECS de chia slot on dinh
        slots = sum(1 for x in CONV_SPECS if tuple(x["subs"]) == key)
        seen[key] += 1
        pools[s["conv"]] = pool_for_spec(per_file, s["subs"], 3, slot, slots)
        fnames = sorted({p["fname"][:30] for p in pools[s["conv"]]})
        print(f"[mem] {s['conv']} {s['topic'][:50]}: {len(pools[s['conv']])} chunks {fnames}")

    if args.dry_run:
        print("[dry-run] OK, khong goi LLM.")
        return

    from openai import OpenAI
    base = os.getenv("OLLAMA_JUDGE_BASE_URL") or os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1")
    key = os.getenv("OLLAMA_JUDGE_API_KEY") or os.getenv("OLLAMA_API_KEY", "")
    model = os.getenv("OLLAMA_JUDGE_MODEL") or os.getenv("OLLAMA_MODEL", "gemma4:31b")
    if not os.getenv("OLLAMA_JUDGE_API_KEY"):
        print("[WARN] chua co OLLAMA_JUDGE_API_KEY — dung key RAG cu, mat tinh doc lap!")
    print(f"[mem] judge model={model} key=...{key[-4:]} base={base}")
    client = OpenAI(base_url=base, api_key=key)

    existing = []
    if OUT_JSON.exists():
        try:
            existing = json.loads(OUT_JSON.read_text(encoding="utf-8"))
        except Exception:
            existing = []
    done = {r.get("conversation_id") for r in existing} if existing else set()
    all_rows = list(existing) if existing else []
    if args.conv:
        all_rows = [r for r in all_rows if r.get("conversation_id") != args.conv.upper()]

    n_fail = 0
    for s in specs:
        if s["conv"] in done and not args.conv:
            print(f"[{s['conv']}] resume-skip")
            continue
        pool = pools[s["conv"]]
        if not pool:
            print(f"[{s['conv']}] khong co chunk -> bo qua")
            n_fail += 1
            continue
        print(f"[{s['conv']}] draft 12 turn ...", flush=True)
        turns = draft_conv(client, model, s, pool)
        if not turns:
            print(f"  [{s['conv']}] draft FAIL")
            n_fail += 1
            continue
        print(f"  [{s['conv']}] draft OK {len(turns)} turns", flush=True)
        if not args.skip_verify:
            print(f"[{s['conv']}] verify full-context ...", flush=True)
            rep = verify_conv(client, model, pool, turns)
            if rep:
                bad = [t for t in rep.get("turns", []) if not t.get("ok")]
                print(f"  [{s['conv']}] verify: {len(turns)-len(bad)}/{len(turns)} ok"
                      + (f", can review: {[b.get('turn') for b in bad]}" if bad else ""))
            else:
                print(f"  [{s['conv']}] verify FAIL -> giu needs_review=True")
            time.sleep(1)
        all_rows = [r for r in all_rows if r.get("conversation_id") != s["conv"]]
        all_rows.extend(build_rows(s, pool, turns))
        all_rows.sort(key=lambda r: (r.get("conversation_id", ""), r.get("turn_index", 0)))
        OUT_JSON.write_text(json.dumps(all_rows, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"  [{s['conv']}] saved ({len(all_rows)} turns total)", flush=True)
        time.sleep(1)

    with open(OUT_CSV, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=[
            "id", "conversation_id", "turn_index", "question", "ground_truth",
            "rewrite_expected", "needs_review", "category", "source_file",
            "breadcrumb", "relevant_chunk_ids", "allowed_jobs",
            "allowed_departments", "reference_contexts"])
        w.writeheader()
        for r in all_rows:
            w.writerow({k: (json.dumps(v, ensure_ascii=False) if isinstance(v, (list, dict)) else v)
                        for k, v in r.items() if k in w.fieldnames})
    print(f"\n[mem] xong {len(all_rows)}/{(len(specs)*12)} turns (fail {n_fail})")
    print(f"  JSON: {OUT_JSON}\n  CSV : {OUT_CSV}")
    print("BAT BUOC: mo CSV review cot ground_truth + rewrite_expected truoc khi do memory.")


if __name__ == "__main__":
    main()

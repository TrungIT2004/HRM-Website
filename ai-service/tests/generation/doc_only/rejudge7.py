"""Re-judge 55 FAILs voi top-7 contexts (dap an sinh tu top_k=7, judge cu chi thay top-3).
Cong them ten file/breadcrumb de xu ly nhom 'ten cong ty tu ten tai lieu'.

Chay tu ai-service:
    py tests/generation/doc_only/rejudge7.py --n 3
    py tests/generation/doc_only/rejudge7.py
Output: tests/generation/doc_only/ragas_eval_gemma_rejudge7.json
"""
import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
from dotenv import load_dotenv  # noqa: E402

load_dotenv()

IN = Path(__file__).parent / "ragas_eval_gemma_judged.json"
OUT = Path(__file__).parent / "ragas_eval_gemma_rejudge7.json"

SYSTEM = ("Ban la giam khao RAG tieng Viet. Chi tra JSON duy nhat, khong giai thich ngoai JSON. "
          "Dau ra dung dang: {\"verdict\": true|false, \"reason\": \"...\", \"unsupported\": \"...\"}")

# ponytail: ten cong ty / ten van ban suy truc tiep tu TEN TAI LIEU (dong dau moi block)
# duoc tinh la co can cu — judge cu khong thay ten file nen xu oan nhom nay.
RULES = ("Tieu chi: verdict=true khi MOI thong tin quan trong trong dap an "
         "(so lieu, ngay, buoc quy trinh, ten mau don) deu co can cu truc tiep trong NGUON. "
         "Ten cong ty / ten van ban neu suy truc tiep tu TEN TAI LIEU (dong dau moi block) "
         "thi tinh la co can cu, khong phai bia. "
         "verdict=false khi co bat ky so lieu/buoc/ten nao KHONG tim thay trong NGUON "
         "lan ten file, hoac dap an them thong tin ngoai NGUON. Bo qua loi chinh ta/OCR nhe. "
         "Cau tra loi 'khong co trong tai lieu' + NGUON that su khong co thi verdict=true.")


def build_user(q, a, ctxs):
    blocks = []
    for i, c in enumerate(ctxs[:7]):
        name = c.get("doc") or c.get("breadcrumb") or ""
        blocks.append(f"[TAI LIEU {i+1}] ({name})\n{(c.get('content') or '')[:4000]}")
    return f"[CAU HOI]\n{q}\n\n[DAP AN CAN CHAM]\n{a}\n\n[NGUON]\n" + "\n\n".join(blocks) + "\n\n" + RULES


def parse_verdict(text):
    m = re.search(r"\{.*\}", text, re.S)
    if not m:
        low = text.lower()
        if "true" in low and "false" not in low:
            return True, "fallback-keyword", ""
        return False, "fallback-keyword", text[:200]
    try:
        o = json.loads(m.group(0))
        v = o.get("verdict")
        if isinstance(v, bool):
            return v, o.get("reason", ""), o.get("unsupported", "")
        if isinstance(v, str):
            return v.lower() in ("true", "dung", "dat"), o.get("reason", ""), o.get("unsupported", "")
    except Exception:
        pass
    return None, "parse-fail", text[:200]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=0)
    args = ap.parse_args()

    from openai import OpenAI
    from src.chat.chat_service import ChatService
    from src.retrievers.hybrid_retriever import HybridRetriever
    client = OpenAI(base_url=os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1"),
                    api_key=os.getenv("OLLAMA_API_KEY", "ollama"), timeout=60.0)
    model = os.getenv("OLLAMA_MODEL", "gemma4:31b")
    svc = ChatService()
    ret = svc.retriever  # cung retriever duong answer_query dung
    print(f"[rejudge7] model={model}", flush=True)

    fails = [r for r in json.loads(IN.read_text(encoding="utf-8")) if not r.get("judge_verdict")]
    if args.n:
        fails = fails[:args.n]
    print(f"[rejudge7] {len(fails)} FAILs can cham lai top-7", flush=True)

    out_rows, flips = [], 0
    for i, r in enumerate(fails):
        t0 = time.time()
        # ponytail: tai hien dung evidence duong sinh dap an (_retrieve_lazy):
        # rewrite + alt cau goc, top_k=7. Rewrite khong luu luc eval nen condense lai
        # (temp 0, cung model — gan dung; lech rewrite nao ghi vao row de soi).
        try:
            rq = svc.condense_question(r["question"], [])
        except Exception:
            rq = r["question"]
        got = ret.retrieve(query=rq or r["question"], jobs=["ALL"], departments=["ALL"],
                            top_k=7, alt_queries=[r["question"]])
        ctxs = [{"content": c.get("content"), "doc": c.get("breadcrumb") or c.get("source_file") or ""} for c in got]
        try:
            res = client.chat.completions.create(
                model=model,
                messages=[{"role": "system", "content": SYSTEM},
                          {"role": "user", "content": build_user(r["question"], r["answer"], ctxs)}],
                temperature=0.0, max_tokens=512)
            text = res.choices[0].message.content.strip()
        except Exception as e:
            print(f"[{i+1}/{len(fails)}] id={r['id']} LLM LOI: {e}", flush=True)
            out_rows.append({**r, "judge7_verdict": None, "judge7_reason": f"LLM-ERROR: {e}"})
            continue
        v, reason, unsup = parse_verdict(text)
        if v is None:
            v = False
        flips += 1 if v else 0
        out_rows.append({**r, "judge7_n_ctx": len(ctxs), "judge7_verdict": v,
                         "judge7_reason": reason, "judge7_unsupported": unsup,
                         "judge7_rewritten": rq,
                         "judge7_elapsed": round(time.time() - t0, 1)})
        print(f"[{i+1}/{len(fails)}] id={r['id']} {'FLIP-True' if v else 'van-FAIL'} "
              f"({time.time()-t0:.1f}s) {str(reason)[:80]}", flush=True)
        if (i + 1) % 10 == 0:
            OUT.write_text(json.dumps(out_rows, ensure_ascii=False, indent=1), encoding="utf-8")

    OUT.write_text(json.dumps(out_rows, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"\n== REJUDGE7: {flips}/{len(out_rows)} flip thanh True | {len(out_rows)-flips} van FAIL | -> {OUT}")


if __name__ == "__main__":
    main()

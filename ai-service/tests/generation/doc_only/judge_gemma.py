"""Cham review_100_gemma.json bang gemma4:31b (1 call/cau, temperature 0).
Binary groundedness: moi claim trong answer phai co can cu trong contexts.

Chay tu ai-service:
    py tests/generation/doc_only/judge_gemma.py --n 3      # thu
    py tests/generation/doc_only/judge_gemma.py            # full 100
Output: tests/generation/doc_only/review_100_gemma_judged.json
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

IN = Path(__file__).parent / "ragas_eval_gemma.json"
OUT = Path(__file__).parent / "ragas_eval_gemma_judged.json"

SYSTEM = ("Ban la giam khao RAG tieng Viet. Chi tra JSON duy nhat, khong giai thich ngoai JSON. "
          "Dau ra dung dang: {\"verdict\": true|false, \"reason\": \"...\", \"unsupported\": \"...\"}")

def build_user(q, a, ctxs):
    blocks = "\n\n".join(f"[TAI LIEU {i+1}]\n{(c or '')[:4000]}" for i, c in enumerate(ctxs[:3]))
    return (f"[CAU HOI]\n{q}\n\n[DAP AN CAN CHAM]\n{a}\n\n[NGUON]\n{blocks}\n\n"
            "Tieu chi: verdict=true khi MOI thong tin quan trong trong dap an "
            "(so lieu, ngay, buoc quy trinh, ten mau don) deu co can cu truc tiep trong NGUON. "
            "verdict=false khi co bat ky so lieu/buoc/ten nao trong dap an KHONG tim thay trong NGUON, "
            "hoac dap an them thong tin ngoai NGUON. Bo qua loi chinh ta/OCR nhe. "
            "Cau tra loi 'khong co trong tai lieu' + NGUON that su khong co thi verdict=true.")


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
    ap.add_argument("--n", type=int, default=0, help="So cau cham (0 = het)")
    ap.add_argument("--resume", action="store_true", default=True, help="Bo qua cau da cham trong OUT")
    ap.add_argument("--in", dest="inp", type=str, default=None, help="File input (mac dinh ragas_eval_gemma.json)")
    ap.add_argument("--out", dest="outp", type=str, default=None, help="File output")
    args = ap.parse_args()

    from openai import OpenAI
    client = OpenAI(base_url=os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1"),
                    api_key=os.getenv("OLLAMA_API_KEY", "ollama"), timeout=60.0)
    model = os.getenv("OLLAMA_MODEL", "gemma4:31b")
    print(f"[judge] model={model}", flush=True)

    global IN, OUT
    if args.inp:
        IN = Path(args.inp)
    if args.outp:
        OUT = Path(args.outp)
    raw = json.loads(IN.read_text(encoding="utf-8"))
    rows = raw.get("rows", raw) if isinstance(raw, dict) else raw
    for k, r in enumerate(rows):  # ponytail: ragas file khong co id -> dung index
        r.setdefault("id", k)
        r.setdefault("question", r.get("user_input", r.get("question", "")))
        r.setdefault("answer", r.get("response", r.get("answer", "")))
        r.setdefault("contexts", r.get("retrieved_contexts", r.get("contexts", [])))
    if args.n:
        rows = rows[:args.n]
    done = {}
    if args.resume and OUT.exists():
        try:
            for r in json.loads(OUT.read_text(encoding="utf-8")):
                if r.get("judge_verdict") is not None:
                    done[r["id"]] = r
            print(f"[judge] resume {len(done)} cau", flush=True)
        except Exception as e:
            print(f"[judge] khong resume duoc: {e}", flush=True)

    out_rows, tps, fails = [], 0, 0
    for i, r in enumerate(rows):
        if r["id"] in done:
            out_rows.append(done[r["id"]])
            v = done[r["id"]]["judge_verdict"]
            tps += 1 if v else 0
            fails += 0 if v else 1
            continue
        t0 = time.time()
        try:
            res = client.chat.completions.create(
                model=model,
                messages=[{"role": "system", "content": SYSTEM},
                          {"role": "user", "content": build_user(r["question"], r["answer"], r.get("contexts", []))}],
                temperature=0.0, max_tokens=512)
            text = res.choices[0].message.content.strip()
        except Exception as e:
            print(f"[{i+1}/{len(rows)}] id={r['id']} LLM LOI: {e}", flush=True)
            out_rows.append({**r, "judge_verdict": None, "judge_reason": f"LLM-ERROR: {e}",
                             "judge_unsupported": "", "judge_model": model, "judge_elapsed": round(time.time()-t0, 1)})
            continue
        v, reason, unsup = parse_verdict(text)
        if v is None:
            print(f"[{i+1}/{len(rows)}] id={r['id']} PARSE-FAIL: {text[:150]}", flush=True)
            v = False
        out_rows.append({**r, "judge_verdict": v, "judge_reason": reason,
                         "judge_unsupported": unsup, "judge_model": model,
                         "judge_elapsed": round(time.time()-t0, 1)})
        tps += 1 if v else 0
        fails += 0 if v else 1
        print(f"[{i+1}/{len(rows)}] id={r['id']} verdict={v} ({time.time()-t0:.1f}s) {str(reason)[:80]}", flush=True)
        if (i+1) % 10 == 0:  # ponytail: ghi incremental, chet giua chung khong mat
            OUT.write_text(json.dumps(out_rows, ensure_ascii=False, indent=1), encoding="utf-8")

    OUT.write_text(json.dumps(out_rows, ensure_ascii=False, indent=1), encoding="utf-8")
    n = len(out_rows)
    print(f"\n== JUDGE {model}: {tps}/{n} PASS ({tps/n:.3f}) | {fails} FAIL | -> {OUT}")


if __name__ == "__main__":
    main()

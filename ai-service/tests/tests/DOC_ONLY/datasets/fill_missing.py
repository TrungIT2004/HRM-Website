"""Va 15 chunk thieu vao dataset co san (khong sinh lai 105 cau cu)."""
import csv
import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))
from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from tests.DOC_ONLY.datasets.generate_doc_only import (  # noqa: E402
    fetch_chunks, sample_even, GEN_PROMPT, CATEGORIES, llm_row)

OUT_DIR = Path(__file__).resolve().parent
OUT_JSON = OUT_DIR / "doc_only_120.json"
OUT_CSV = OUT_DIR / "doc_only_120.csv"


def main() -> None:
    done = json.loads(OUT_JSON.read_text(encoding="utf-8"))
    got = {c for x in done for c in x["relevant_chunk_ids"]}
    print(f"[fill] da co {len(done)} cau")

    per_file = fetch_chunks()
    names = sorted(per_file, key=lambda f: len(per_file[f]))
    quotas, remaining = {}, 120
    for i, f in enumerate(names):
        left = len(names) - i
        q = min(len(per_file[f]), -(-remaining // left))
        quotas[f] = q
        remaining -= q
    sampled = {f: sample_even(per_file[f], quotas[f]) for f in names}
    missing = [(f, r) for f, rows in sampled.items() for r in rows if str(r[0]) not in got]
    print(f"[fill] thieu {len(missing)} chunks")
    if not missing:
        return

    from openai import OpenAI
    client = OpenAI(base_url=os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1"),
                    api_key=os.getenv("OLLAMA_API_KEY", "ollama"))
    model = os.getenv("OLLAMA_MODEL", "gemma4:31b")

    idx, n_fail = len(done), 0
    for f, (cid, cidx, content, crumb, jobs, depts) in missing:
        idx += 1
        print(f"[{idx}/120] {f[:40]} chunk#{cidx}", flush=True)
        d = llm_row(client, model, content)
        if not d:
            n_fail += 1
            idx -= 1
            continue
        done.append({
            "id": f"D{idx:03d}",
            "question": d["question"].strip(),
            "ground_truth": d["answer_draft"].strip(),
            "needs_review": True,
            "reference_contexts": [(content or "").strip()[:2000]],
            "relevant_chunk_ids": [str(cid)],
            "category": (d.get("category") or "khac").strip(),
            "source_file": f,
            "breadcrumb": crumb or "",
            "conversation_id": None,
            "turn_index": 1,
            "history": [],
            "rewrite_expected": "",
            "allowed_jobs": list(jobs or ["ALL"]),
            "allowed_departments": list(depts or ["ALL"]),
        })
        time.sleep(1)

    OUT_JSON.write_text(json.dumps(done, ensure_ascii=False, indent=2), encoding="utf-8")
    with open(OUT_CSV, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=[
            "id", "question", "ground_truth", "needs_review", "category",
            "source_file", "breadcrumb", "relevant_chunk_ids",
            "allowed_jobs", "allowed_departments", "reference_contexts"])
        w.writeheader()
        for r in done:
            w.writerow({k: (json.dumps(v, ensure_ascii=False) if isinstance(v, list) else v)
                        for k, v in r.items() if k in w.fieldnames})
    print(f"\n[fill] xong {len(done)}/120 (fail {n_fail})")


if __name__ == "__main__":
    main()

"""Xuat file audit tay cho 20 cau bi judge gan co hallucination (+3 disputed).

Output: audit_hallucination.csv (utf-8-sig, mo bang Excel).
Nguoi review dien cot verdict: TRUE (= bia that) / FALSE (= oan) / UNSURE.
Chay 1 lan:
    python tests/DOC_ONLY/generation_metrics_tests/make_audit.py
Tong hop sau review:
    python tests/DOC_ONLY/generation_metrics_tests/make_audit.py --tally
"""
import csv
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "audit_hallucination.csv"


def load():
    ans = {r["id"]: r for r in json.loads((HERE / "answers.json").read_text(encoding="utf-8"))}
    gold = {r["id"]: r for r in
            json.loads((HERE.parent / "datasets" / "doc_only_120.json").read_text(encoding="utf-8"))}
    judge = {r["id"]: r for r in json.loads((HERE / "judge.json").read_text(encoding="utf-8"))["rows"]}
    return ans, gold, judge


def main() -> None:
    ans, gold, judge = load()
    if "--tally" in sys.argv:
        n_true = n_false = n_unsure = n_blank = 0
        with open(OUT, encoding="utf-8-sig") as fh:
            for r in csv.DictReader(fh):
                v = (r.get("verdict") or "").strip().upper()
                if v == "TRUE":
                    n_true += 1
                elif v == "FALSE":
                    n_false += 1
                elif v == "UNSURE":
                    n_unsure += 1
                else:
                    n_blank += 1
        n = n_true + n_false + n_unsure + n_blank
        print(f"TRUE(bia that)={n_true} FALSE(oan)={n_false} UNSURE={n_unsure} chua cham={n_blank}/{n}")
        if n_true + n_false:
            print(f"hallucination that ~ {n_true}/{(n_true + n_false)} mau audit "
                  f"-> he so x {(n_true / (n_true + n_false)):.2f} = "
                  f"{20 * n_true / (n_true + n_false):.1f}/120 cau "
                  f"(~{20 * n_true / (n_true + n_false) / 120:.3f})")
        return

    flagged = [jid for jid, j in judge.items()
               if j["run1"].get("hallucination") or j["run2"].get("hallucination")]
    with open(OUT, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=[
            "id", "final", "question", "ground_truth", "generated_answer",
            "quote_run1", "quote_run2", "evidence_run1", "evidence_run2",
            "reference_context", "cited_docs", "verdict",
            "ghi_chu (dien TRUE/FALSE/UNSURE vao verdict)"])
        w.writeheader()
        for jid in sorted(flagged):
            j, a, g = judge[jid], ans[jid], gold[jid]
            ev1, ev2 = j["run1"].get("evidence", ""), j["run2"].get("evidence", "")
            w.writerow({
                "id": jid, "final": j["final"], "question": a["question"],
                "ground_truth": g["ground_truth"], "generated_answer": a["answer"],
                "quote_run1": j["run1"].get("hallucination_quote", ""),
                "quote_run2": j["run2"].get("hallucination_quote", ""),
                "evidence_run1": json.dumps(ev1, ensure_ascii=False)[:1500]
                if not isinstance(ev1, str) else ev1[:1500],
                "evidence_run2": json.dumps(ev2, ensure_ascii=False)[:1500]
                if not isinstance(ev2, str) else ev2[:1500],
                "reference_context": " || ".join(g.get("reference_contexts", []))[:3000],
                "cited_docs": ", ".join(c.get("document_name", "") for c in a.get("citations", [])),
                "verdict": "",
                "ghi_chu (dien TRUE/FALSE/UNSURE vao verdict)": "",
            })
    print(f"{len(flagged)} cau -> {OUT}")


if __name__ == "__main__":
    main()

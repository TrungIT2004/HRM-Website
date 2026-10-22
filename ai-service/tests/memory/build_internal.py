"""Dung 30+ conversation noi bo (12 turns) tu generated_testset + BLLĐ chunks.

Blueprint: internal/blueprints/bp*.json -- list conversation [{sid, turns[]}],
moi turn {d, i, rw[, q][, a]}: (d,i) neo chunk testset de lay dap an verbatim;
q/a override khi viet cau noi (dap an ngan, can cu hint/chunk).
BLLĐ turns: q/a/rw tu viet, cid='BLLĐ-2019'.

Chay: python tests/memory/build_internal.py
Output: tests/memory/internal/memory_internal.csv (header giong memory_dataset.csv)
"""
import csv
import json
import sys
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

HERE = Path(__file__).resolve().parent
TESTSET = HERE.parent / "generated_testset.json"
OUT_CSV = HERE / "internal" / "memory_internal.csv"
BPDIR = HERE / "internal" / "blueprints"
BP = [BPDIR / "bp1.json", BPDIR / "bp2.json", BPDIR / "bp3.json",
      BPDIR / "bp_fix.json", BPDIR / "bp4.json",
      BPDIR / "bp5.json", BPDIR / "bp6.json"]

KEYS = {"214": "214.HD", "917": "917.Q", "luong": "sanKeToan.docx",
        "vpp": "QT.ACT", "evn": "EVNFinance", "mwg": "MWG",
        "petrol": "Petrol"}


def flat(s: str) -> str:
    return " ".join((s or "").split())


def main() -> None:
    rows = json.load(open(TESTSET, encoding="utf-8"))
    rows = rows if isinstance(rows, list) else rows.get("rows", [])
    groups = {}
    for r in rows:
        src = str(r.get("source_file", ""))
        key = next((k for k, sub in KEYS.items() if sub in src), None)
        if key:
            groups.setdefault(key, []).append(r)
    # gop turn bo sung theo sid (bp_fix), giu thu tu; bp4 ghi de 5 conv BLLĐ.
    # ponytail: replace theo ten file, khong theo index cuoi (them bp5/6 tung trat).
    REPLACE = {"bp4.json"}
    merged, order = {}, []
    for p in BP:
        for c in json.load(open(p, encoding="utf-8")):
            if p.name in REPLACE or c["sid"] not in merged:  # bp4: thay 5 conv BLLĐ
                if c["sid"] not in merged:
                    order.append(c["sid"])
                merged[c["sid"]] = {"sid": c["sid"], "turns": list(c["turns"])}
            else:
                merged[c["sid"]]["turns"].extend(c["turns"])
    convs = [merged[s] for s in order]
    OUT_CSV.parent.mkdir(exist_ok=True)
    n_turns = 0
    with open(OUT_CSV, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["turn_id", "session_id", "question", "answer", "rewrite", "pid"])
        for c in convs:
            for ti, t in enumerate(c["turns"]):
                if "d" in t:  # neo chunk testset, dap an verbatim
                    row = groups[t["d"]][t["i"]]
                    q = t.get("q", row["question"])
                    a = t.get("a", row["answer_draft"])
                    cid = row["chunk_id"]
                else:  # BLLĐ tu viet
                    q, a, cid = t["q"], t["a"], t.get("cid", "BLLĐ-2019")
                w.writerow([ti, c["sid"], flat(q), flat(a), flat(t["rw"]), cid])
                n_turns += 1
    print(f"[build] {len(convs)} convs, {n_turns} turns -> {OUT_CSV}")


if __name__ == "__main__":
    main()

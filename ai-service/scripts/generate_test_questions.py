"""
Sinh bo cau hoi test RAG tu 3 file "Tai lieu doanh nghiep thuc te".

Tai dung IngestionPipeline + MetadataEnricher san co (khong cai them ragas/langchain).
- PDFParser tu OCR trang scan bang EasyOCR local.
- Chi enrich LLM tren mau chunk (dau-giua-cuoi) de tranh timeout voi file lon
  (enrich_all mac dinh >20 chunks se dung fallback rule-based, cau hoi rat generic).
- LLM dung theo LLM_PROVIDER trong .env (ollama/gemini/openai).

Chay tu thu muc ai-service:
    python scripts/generate_test_questions.py
    python scripts/generate_test_questions.py --provider gemini --per-file 8
    python scripts/generate_test_questions.py --draft-answers   # them cot answer_draft (LLM soan tu chunk, CAN review tay)
Output:
    tests/generated_testset.json  (chi tiet chunk + cau hoi)
    tests/generated_testset.csv   (question, ground_truth_hint, answer_draft, source_file, breadcrumb)
"""
import argparse
import csv
import json
import os
import sys
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src.pipeline import IngestionPipeline  # noqa: E402
from src.metadata.metadata_enricher import MetadataEnricher  # noqa: E402

DOCS_DIR = Path(r"C:\Users\ad\Desktop\RAG-Test-Docs\Tài liệu doanh nghiệp thực tế")
OUTPUT_JSON = Path(__file__).resolve().parent.parent / "tests" / "generated_testset.json"
OUTPUT_CSV = Path(__file__).resolve().parent.parent / "tests" / "generated_testset.csv"


DRAFT_PROMPT = """Ban la tro ly soan dap an mau cho bo test. Doc DOAN TAI LIEU va tra loi CAU HOI, CHI dung thong tin trong doan.
Neu doan khong du thong tin de tra loi day du, tra loi dung mot dong: THIEU THONG TIN.
Tra loi ngan gon bang tieng Viet (co dau).

--- DOAN TAI LIEU ---
{content}
--- CAU HOI ---
{question}
--- DAP AN ---"""


def draft_answer(question: str, content: str, client, model: str) -> str:
    """LLM soan nhap dap an tu chunk. Bat buoc review tay truoc khi lam ground truth."""
    try:
        res = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": DRAFT_PROMPT.format(
                content=(content or "")[:2500], question=question)}],
        )
        return (res.choices[0].message.content or "").strip()
    except Exception as e:
        return f"[LOI DRAFT: {e}]"


def sample_chunks(chunks, per_file: int):
    """Lay mau deu dau-giua-cuoi de phu het tai lieu ma khong goi LLM qua nhieu."""
    if len(chunks) <= per_file:
        return chunks
    step = len(chunks) / per_file
    idx = [int(i * step) for i in range(per_file)]
    return [chunks[i] for i in idx]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--provider", default=None,
                    help="Ghi de LLM_PROVIDER trong .env (ollama/gemini/openai)")
    ap.add_argument("--per-file", type=int, default=8,
                    help="So chunk mau enrich LLM moi file (mac dinh 8)")
    ap.add_argument("--draft-answers", action="store_true",
                    help="LLM soan nhap dap an tu chunk (cot answer_draft, BAT BUOC review tay)")
    args = ap.parse_args()

    if args.provider:
        os.environ["LLM_PROVIDER"] = args.provider
    print(f"[generate] LLM_PROVIDER={os.getenv('LLM_PROVIDER', 'ollama')}")

    files = sorted([f for ext in ("*.pdf", "*.docx") for f in DOCS_DIR.glob(ext)])
    if not files:
        print(f"[generate] Khong thay file PDF/DOCX nao trong {DOCS_DIR}")
        sys.exit(1)

    llm_client, llm_model = None, None
    if args.draft_answers:
        from openai import OpenAI  # noqa: E402
        llm_client = OpenAI(
            base_url=os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1"),
            api_key=os.getenv("OLLAMA_API_KEY", "ollama"),
        )
        llm_model = os.getenv("OLLAMA_MODEL", "gemma4:31b")

    # Chunk nhanh, chua enrich (PDFParser tu OCR trang scan; tranh fallback
    # rule-based cua enrich_all voi file lon)
    pipeline = IngestionPipeline(enrich_with_llm=False)
    enricher = MetadataEnricher(provider=args.provider)
    rows = []

    for f in files:
        print(f"\n[generate] Chunking: {f.name}")
        chunks = pipeline.process_file(f)
        print(f"[generate] -> {len(chunks)} chunks, lay mau {args.per_file} chunk enrich LLM")
        for c in sample_chunks(chunks, args.per_file):
            try:
                c = enricher.enrich_chunk(c)
            except Exception as e:
                print(f"[generate] enrich loi chunk {c.chunk_id}: {e}")
                continue
            for q in (c.hypothetical_questions or []):
                draft = (draft_answer(q, c.content, llm_client, llm_model)
                         if args.draft_answers else "")
                rows.append({
                    "question": q,
                    "ground_truth_hint": c.summary or "",
                    "answer_draft": draft,
                    "needs_review": args.draft_answers,
                    "source_file": f.name,
                    "breadcrumb": c.breadcrumb,
                    "chunk_id": c.chunk_id,
                    "keywords": ", ".join(c.keywords or []),
                    "content_preview": (c.content or "")[:300].replace("\n", " "),
                })

    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_JSON, "w", encoding="utf-8") as fh:
        json.dump(rows, fh, ensure_ascii=False, indent=2)
    # utf-8-sig (BOM) de Excel mo dung tieng Viet
    with open(OUTPUT_CSV, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=[
            "question", "ground_truth_hint", "answer_draft", "needs_review",
            "source_file", "breadcrumb", "chunk_id", "keywords", "content_preview",
        ])
        w.writeheader()
        w.writerows(rows)

    print(f"\n[generate] Xong: {len(rows)} cau hoi tu {len(files)} files")
    print(f"  JSON: {OUTPUT_JSON}")
    print(f"  CSV : {OUTPUT_CSV}\n")
    for i, r in enumerate(rows, 1):
        print(f"{i}. [{r['source_file']}] {r['question']}")
    print("\nLUU Y: doc lai CSV, sua ground_truth_hint thanh dap an dung roi moi dem di test RAG.")


if __name__ == "__main__":
    main()

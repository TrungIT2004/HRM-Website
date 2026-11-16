"""Deterministic Fact-Checker for DOC_ONLY Generation Evaluation.

Replaces LLM judge (gpt-oss/gemma) with deterministic verification:
- Numeric fidelity: Every number in answer must appear in retrieved chunks (±1% tolerance for rates)
- Policy grounding: Every policy/article reference must match DOC chunk title or content
- No hallucination: Answer tokens not in (question + retrieved context) flagged
- Refusal correctness: "I don't know" allowed only when no relevant chunks retrieved

Usage:
    python -m tests.generation.doc_only.fact_checker --input tests/generation/doc_only/ragas_eval_gemma.json --n 20
Output: tests/generation/doc_only/fact_check_results.json
"""
import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, asdict

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass


# Vietnamese diacritics normalization
_DASHES = str.maketrans({"‐": "-", "‑": "-", "‒": "-", "–": "-", "—": "-", "−": "-"})
# Đ/đ don't decompose in NFD, handle explicitly
_D_STROKE = str.maketrans({"Đ": "D", "đ": "d"})


def norm_text(s: str) -> str:
    """Normalize Vietnamese text for comparison."""
    s = re.sub(r"\s+", " ", str(s or "")).strip().lower().translate(_DASHES)
    # Handle Đ/đ before NFD (they don't decompose)
    s = s.translate(_D_STROKE)
    return "".join(c for c in __import__("unicodedata").normalize("NFD", s)
                   if __import__("unicodedata").category(c) != "Mn")


def norm_num(s: str) -> Optional[str]:
    """Extract and normalize number from string."""
    t = re.sub(r"\s", "", s)
    if "," in t:
        t = t.replace(".", "").replace(",", ".")
    elif t.count(".") > 1:
        t = t.replace(".", "")
    if re.fullmatch(r"\d+(\.\d+)?", t):
        try:
            return str(float(t))
        except ValueError:
            pass
    return None


def extract_numbers(text: str) -> List[Tuple[str, str]]:
    """Extract all numbers from text with their original form."""
    numbers = []
    for m in re.finditer(r"\d[\d\s.,]*\d|\d", text):
        orig = m.group(0)
        norm = norm_num(orig)
        if norm:
            numbers.append((norm, orig))
    return numbers


def extract_policy_refs(text: str) -> List[str]:
    """Extract policy/article references from text (e.g., 'Điều 5', 'Quyết định 917/QĐ-ACT')."""
    refs = []
    # Match patterns like: Điều 1, Điều 5.2, Quyết định 917/QĐ-ACT, Quy chế 15/2023/QĐ, etc.
    # EXCLUDE generic phrases like "quy chế nội bộ", "quy định của công ty"
    # Require a document identifier after the keyword (number, code, etc.)
    patterns = [
        r"Điều\s+\d+(?:\.\d+)?",
        r"Quyết\s+định\s+[\w/\.\-]+",
        r"Quy\s+chế\s+\d+[\w/\.\-]*",  # Quy chế 15/2023/QĐ, Quy chế 123, etc.
        r"Chương\s+\d+",
        r"Mẫu\s+\w+",
        r"Biểu\s+mẫu\s+\w+",
        r"BM\d+",
        r"QT\.ACT\.\w+",
        r"HD-ACT-\w+",
        r"\d+/\d{4}/QĐ",
    ]
    for pat in patterns:
        for m in re.finditer(pat, text, re.IGNORECASE):
            refs.append(m.group(0).strip())

    # Filter out generic phrases that are not specific policy references
    filtered = []
    for ref in refs:
        ref_low = ref.lower()
        # Skip if it's just "quy chế" or "quy định" without a specific identifier
        if ref_low in ("quy chế", "quy định", "nội bộ", "công ty", "quy chế nội bộ", "quy định của công ty"):
            continue
        # Skip if it ends with just "nội" or "bộ" (generic)
        if ref_low.endswith((" nội", " bộ", " của", " tại", " về")):
            continue
        filtered.append(ref)
    return filtered


# Common refusal template phrases (Vietnamese) - these are NOT hallucinations
_REFUSAL_TEMPLATE_WORDS = {
    "rất", "tiếc", "quy", "chế", "nội", "bộ", "hiện", "tại", "công", "ty",
    "không", "có", "thông", "tin", "quy", "định", "về", "câu", "hỏi", "này",
    "bạn", "vui", "lòng", "liên", "hệ", "trực", "tiếp", "phòng", "nhân",
    "sự", "hr", "để", "được", "hướng", "dẫn", "chi", "tiết", "dữ", "liệu",
    "tìm", "thấy", "chưa", "mẫu", "bản", "ghi", "nhận", "xác", "nhận",
}

def extract_keywords(text: str, min_len: int = 4) -> List[str]:
    """Extract meaningful keywords from text (for hallucination detection)."""
    words = re.findall(r"[\wàáảãạăắằẳẵặâấầẩẫậđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ]{%d,}" % min_len, text, re.IGNORECASE)
    # Filter out common stopwords AND refusal template words
    stopwords = {"của", "cho", "và", "các", "được", "không", "này", "đó", "khi", "là", "trong", "theo", "với", "từ", "về", "những", "các", "như", "để", "bị", "đã", "sẽ", "có", "làm", "có", "thì", "nếu", "mà", "hay", "hoặc", "cũng", "vẫn", "chỉ", "đều", "mỗi", "tất", "cả"}
    stopwords.update(_REFUSAL_TEMPLATE_WORDS)
    return [w.lower() for w in words if w.lower() not in stopwords and len(w) >= min_len]


def check_numeric_fidelity(answer: str, contexts: List[str]) -> Tuple[float, List[str], List[str]]:
    """Check if every number in answer appears in contexts.

    Returns: (score, supported_numbers, unsupported_numbers)
    """
    ans_nums = extract_numbers(answer)
    if not ans_nums:
        return 1.0, [], []  # No numbers to check

    # Flatten all context numbers
    ctx_nums = []
    for ctx in contexts:
        ctx_nums.extend(extract_numbers(ctx))

    ctx_norm = set(n for n, _ in ctx_nums)

    supported = []
    unsupported = []
    for norm, orig in ans_nums:
        found = False
        for ctx_norm_val in ctx_norm:
            try:
                if abs(float(norm) - float(ctx_norm_val)) <= max(0.01, 0.01 * abs(float(norm))):
                    found = True
                    break
            except ValueError:
                pass
        if found:
            supported.append(orig)
        else:
            unsupported.append(orig)

    score = len(supported) / len(ans_nums) if ans_nums else 1.0
    return score, supported, unsupported


def check_policy_grounding(answer: str, contexts: List[str]) -> Tuple[float, List[str], List[str]]:
    """Check if policy/article references in answer match DOC chunks."""
    refs = extract_policy_refs(answer)
    if not refs:
        return 1.0, [], []  # No policy refs to check

    supported = []
    unsupported = []
    all_ctx = " ".join(contexts)

    for ref in refs:
        # Normalize both for comparison
        ref_norm = norm_text(ref)
        ctx_norm = norm_text(all_ctx)
        if ref_norm in ctx_norm:
            supported.append(ref)
        else:
            unsupported.append(ref)

    score = len(supported) / len(refs) if refs else 1.0
    return score, supported, unsupported


def check_hallucination(answer: str, question: str, contexts: List[str]) -> Tuple[float, List[str]]:
    """Check for hallucinated content - answer tokens not in question+contexts.

    Returns: (score, hallucinated_keywords)
    """
    # Build allowed vocabulary from question + contexts
    allowed_text = question + " " + " ".join(contexts)
    allowed_keywords = set(extract_keywords(allowed_text))

    # Extract keywords from answer
    ans_keywords = extract_keywords(answer)

    hallucinated = []
    for kw in ans_keywords:
        if kw not in allowed_keywords:
            hallucinated.append(kw)

    # Score: proportion of answer keywords that are grounded
    if not ans_keywords:
        return 1.0, []
    score = 1.0 - (len(hallucinated) / len(ans_keywords))
    return max(0.0, score), hallucinated


def check_refusal_correctness(answer: str, question: str, contexts: List[str]) -> Tuple[float, str]:
    """Check if refusal ('không có thông tin', 'liên hệ HR') is correct.

    Refusal is correct when retrieved contexts don't contain information to answer the question.
    Heuristic: if key entities/numbers from question don't appear in contexts, refusal is justified.
    """
    refusal_markers = [
        "không có thông tin", "khong co thong tin",
        "liên hệ", "lien he", "nhân sự", "nhan su",
        "chưa có dữ liệu", "chua co du lieu",
        "không tìm thấy", "khong tim thay",
        "không có dữ liệu", "khong co du lieu",
    ]

    answer_low = norm_text(answer)
    is_refusal = any(marker in answer_low for marker in refusal_markers)

    if not is_refusal:
        return 1.0, "not_refusal"  # Not a refusal, no penalty

    # No contexts at all -> correct refusal
    if not contexts or not any(ctx and len(ctx.strip()) > 50 for ctx in contexts):
        return 1.0, "correct_refusal_no_context"

    # Check if question's key entities appear in contexts
    # Extract meaningful terms from question (excluding common words)
    question_keywords = set(extract_keywords(question, min_len=3))
    all_context = " ".join(contexts)
    context_keywords = set(extract_keywords(all_context, min_len=3))

    # If question has specific entities (proper nouns, numbers, policy refs)
    # and NONE appear in contexts -> refusal is correct
    if question_keywords:
        overlap = question_keywords & context_keywords
        # If very low overlap (< 20%), contexts likely don't answer the question
        if len(overlap) / len(question_keywords) < 0.2:
            return 1.0, "correct_refusal_low_overlap"

    # Default: contexts exist but may not be relevant - be lenient
    return 0.5, "partial_refusal_has_context"


@dataclass
class FactCheckResult:
    question: str
    answer: str
    faithfulness: float
    answer_relevancy: float
    context_precision: float
    numeric_fidelity: float
    policy_grounding: float
    hallucination_score: float
    refusal_correctness: float
    unsupported_numbers: List[str]
    unsupported_policies: List[str]
    hallucinated_keywords: List[str]
    refusal_status: str
    contexts_count: int


def evaluate_answer(question: str, answer: str, contexts: List[str]) -> FactCheckResult:
    """Run all fact-checks on a single answer."""

    # 1. Numeric fidelity
    num_score, _, unsup_nums = check_numeric_fidelity(answer, contexts)

    # 2. Policy grounding
    pol_score, _, unsup_pols = check_policy_grounding(answer, contexts)

    # 3. Hallucination detection
    hal_score, hal_kws = check_hallucination(answer, question, contexts)

    # 4. Refusal correctness
    ref_score, ref_status = check_refusal_correctness(answer, question, contexts)

    # Detect refusal
    answer_low = norm_text(answer)
    refusal_words = {"liên hệ", "lien he", "nhân sự", "nhan su", "không có", "khong co", "chưa có", "chua co", "rất tiếc", "rat tiec"}
    is_refusal = any(w in answer_low for w in refusal_words)

    # Check if contexts have relevant info (question-keyword overlap with contexts)
    q_keywords = set(norm_text(question).split())
    ctx_has_relevant = False
    if contexts:
        ctx_text = " ".join(norm_text(c) for c in contexts)
        ctx_words = set(ctx_text.split())
        overlap = len(q_keywords & ctx_words) / len(q_keywords) if q_keywords else 0
        ctx_has_relevant = overlap > 0.2  # Threshold: contexts cover >20% of question keywords

    # Combined metrics - UPDATED to align with human judgment:
    # Faithfulness: penalize refusals when contexts have relevant info
    # (a refusal when answer exists in contexts = unfaithful to the available info)
    base_faithfulness = num_score * pol_score * hal_score
    if is_refusal and ctx_has_relevant:
        faithfulness = base_faithfulness * 0.3  # Heavy penalty: refusal despite available info
    else:
        faithfulness = base_faithfulness

    # Answer relevancy: based on question-answer keyword overlap (not just refusal)
    ans_words = set(answer_low.split())
    qa_overlap = len(q_keywords & ans_words) / len(q_keywords) if q_keywords else 0
    # Non-refusal answers get base score from overlap; refusals get 0 unless appropriate
    if is_refusal:
        answer_relevancy = 0.0 if ctx_has_relevant else 0.5  # Partial credit for correct refusal
    else:
        answer_relevancy = min(1.0, qa_overlap * 1.5)  # Scale overlap to [0,1]

    # Context precision: proportion of answer content grounded in contexts
    # If refusal, precision is low (no content to ground); else use hallucination as proxy
    if is_refusal:
        context_precision = 0.0
    else:
        context_precision = hal_score if contexts else 0.0

    return FactCheckResult(
        question=question[:200],
        answer=answer[:500],
        faithfulness=round(faithfulness, 4),
        answer_relevancy=round(answer_relevancy, 4),
        context_precision=round(context_precision, 4),
        numeric_fidelity=round(num_score, 4),
        policy_grounding=round(pol_score, 4),
        hallucination_score=round(hal_score, 4),
        refusal_correctness=round(ref_score, 4),
        unsupported_numbers=unsup_nums,
        unsupported_policies=unsup_pols,
        hallucinated_keywords=hal_kws[:10],  # Limit output
        refusal_status=ref_status,
        contexts_count=len(contexts)
    )


def main():
    ap = argparse.ArgumentParser(description="Deterministic fact-checker for DOC_ONLY generation")
    ap.add_argument("--input", type=str, default="tests/tests/generation/doc_only/ragas_eval_gemma.json",
                    help="Input JSON file with questions, answers, contexts")
    ap.add_argument("--output", type=str, default="tests/generation/doc_only/fact_check_results.json",
                    help="Output JSON file")
    ap.add_argument("--n", type=int, default=0, help="Number of questions to evaluate (0 = all)")
    ap.add_argument("--gold", type=str, default=None,
                    help="Optional gold standard file (review_30_manual.json) for calibration")
    args = ap.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"[fact_checker] Input file not found: {input_path}")
        sys.exit(1)

    data = json.loads(input_path.read_text(encoding="utf-8"))
    rows = data.get("rows", data) if isinstance(data, dict) else data

    if args.n > 0:
        rows = rows[:args.n]

    print(f"[fact_checker] Evaluating {len(rows)} answers...", flush=True)

    results = []
    for i, row in enumerate(rows):
        question = row.get("question") or row.get("user_input") or ""
        answer = row.get("answer") or row.get("response") or ""
        contexts = row.get("contexts") or row.get("retrieved_contexts") or []

        if not question or not answer:
            print(f"  [{i+1}] Skipping: missing question or answer")
            continue

        result = evaluate_answer(question, answer, contexts)
        results.append(asdict(result))

        if (i + 1) % 10 == 0:
            print(f"  [{i+1}/{len(rows)}] faithfulness={result.faithfulness:.3f} "
                  f"relevancy={result.answer_relevancy:.3f} "
                  f"precision={result.context_precision:.3f}", flush=True)

    # Summary statistics
    if results:
        n = len(results)
        summary = {
            "n": n,
            "faithfulness_mean": round(sum(r["faithfulness"] for r in results) / n, 4),
            "answer_relevancy_mean": round(sum(r["answer_relevancy"] for r in results) / n, 4),
            "context_precision_mean": round(sum(r["context_precision"] for r in results) / n, 4),
            "numeric_fidelity_mean": round(sum(r["numeric_fidelity"] for r in results) / n, 4),
            "policy_grounding_mean": round(sum(r["policy_grounding"] for r in results) / n, 4),
            "hallucination_score_mean": round(sum(r["hallucination_score"] for r in results) / n, 4),
            "refusal_correctness_mean": round(sum(r["refusal_correctness"] for r in results) / n, 4),
            "pass_faithfulness": sum(1 for r in results if r["faithfulness"] >= 0.75),
            "pass_relevancy": sum(1 for r in results if r["answer_relevancy"] >= 0.75),
            "pass_precision": sum(1 for r in results if r["context_precision"] >= 0.75),
        }
        summary["faithfulness_pass_rate"] = round(summary["pass_faithfulness"] / n, 4)
        summary["relevancy_pass_rate"] = round(summary["pass_relevancy"] / n, 4)
        summary["precision_pass_rate"] = round(summary["pass_precision"] / n, 4)
    else:
        summary = {"n": 0}

    output = {
        "summary": summary,
        "rows": results
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"\n== FACT CHECKER SUMMARY ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> {output_path}")

    # Check against gold standard if provided
    if args.gold:
        gold_path = Path(args.gold)
        if gold_path.exists():
            gold = json.loads(gold_path.read_text(encoding="utf-8"))
            print(f"\n[gold calibration] Loaded {len(gold)} gold labels")
            calibrate_against_gold(results, gold)


def calibrate_against_gold(fc_results: list, gold_labels: list) -> None:
    """
    Calibrate fact-checker against human gold labels.

    Gold labels have: id, source_file, breadcrumb, question, reference, content_preview, answer (gold answer)
    FC results have: question, answer (LLM answer), and computed metrics.

    Strategy: Match by question text (fuzzy). For each match:
    - Compute similarity between LLM answer and gold answer
    - If LLM answer ≈ gold answer (high overlap), human expects PASS (faithful & relevant)
    - If LLM answer is refusal/empty, human expects FAIL
    - Compare FC verdicts (pass/fail at 0.75) with this derived expectation
    """
    # Build gold lookup by normalized question
    def norm_q(q: str) -> str:
        return re.sub(r"\s+", " ", q.strip().lower())

    def norm_text(t: str) -> str:
        return re.sub(r"\s+", " ", str(t or "")).strip().lower()

    def answer_similarity(ans1: str, ans2: str) -> float:
        """Compute Jaccard similarity of normalized word sets."""
        w1 = set(norm_text(ans1).split())
        w2 = set(norm_text(ans2).split())
        if not w1 or not w2:
            return 0.0
        return len(w1 & w2) / len(w1 | w2)

    def is_refusal(ans: str) -> bool:
        low = norm_text(ans)
        refusal_words = {"liên hệ", "lien he", "nhân sự", "nhan su", "không có", "khong co", "chưa có", "chua co", "rất tiếc", "rat tiec"}
        return any(w in low for w in refusal_words)

    gold_by_q = {norm_q(g["question"]): g for g in gold_labels}

    matches = 0
    faithfulness_agree = 0
    relevancy_agree = 0
    precision_agree = 0

    details = []

    for fc in fc_results:
        q_norm = norm_q(fc["question"])
        # Find best match in gold
        best_match = None
        best_score = 0
        for gq, gl in gold_by_q.items():
            fc_words = set(q_norm.split())
            g_words = set(gq.split())
            if fc_words and g_words:
                overlap = len(fc_words & g_words) / len(fc_words | g_words)
                if overlap > best_score and overlap > 0.5:
                    best_score = overlap
                    best_match = gl

        if best_match:
            matches += 1
            gold_ans = best_match.get("answer", "")
            llm_ans = fc["answer"]

            # Derive human expectation from LLM vs Gold similarity
            sim = answer_similarity(llm_ans, gold_ans)
            is_ref = is_refusal(llm_ans)

            # Human expects PASS if LLM answer is similar to gold (not a refusal)
            human_expects_faithful = (sim > 0.3) and not is_ref
            human_expects_relevant = (sim > 0.3) and not is_ref

            # FC verdict at 0.75 threshold
            fc_faithful = fc["faithfulness"] >= 0.75
            fc_relevant = fc["answer_relevancy"] >= 0.75
            fc_precise = fc["context_precision"] >= 0.75

            # Agreement: FC verdict matches human expectation
            faith_agree = fc_faithful == human_expects_faithful
            rel_agree = fc_relevant == human_expects_relevant
            # Precision: if LLM answer uses contexts well (high sim with gold which is grounded), FC should say precise
            prec_agree = fc_precise == (sim > 0.3)

            if faith_agree:
                faithfulness_agree += 1
            if rel_agree:
                relevancy_agree += 1
            if prec_agree:
                precision_agree += 1

            details.append({
                "question": fc["question"][:80],
                "gold_id": best_match["id"],
                "llm_answer": llm_ans[:100],
                "gold_answer": gold_ans[:100],
                "similarity": round(sim, 3),
                "is_refusal": is_ref,
                "human_exp_faithful": human_expects_faithful,
                "human_exp_relevant": human_expects_relevant,
                "fc_faithfulness": fc["faithfulness"],
                "fc_relevancy": fc["answer_relevancy"],
                "fc_precision": fc["context_precision"],
                "fc_faithful_pass": fc_faithful,
                "fc_relevant_pass": fc_relevant,
                "faith_agree": faith_agree,
                "rel_agree": rel_agree,
            })

    if matches > 0:
        print(f"\n== GOLD CALIBRATION ({matches} matched) ==")
        print(f"  Faithfulness agreement: {faithfulness_agree}/{matches} = {faithfulness_agree/matches:.2%}")
        print(f"  Relevancy agreement:    {relevancy_agree}/{matches} = {relevancy_agree/matches:.2%}")
        print(f"  Precision agreement:    {precision_agree}/{matches} = {precision_agree/matches:.2%}")

        # Show mismatches for debugging
        mismatches = [d for d in details if not d["faith_agree"] or not d["rel_agree"]]
        if mismatches:
            print(f"\n  Mismatches ({len(mismatches)}):")
            for m in mismatches[:15]:
                print(f"    Q: {m['question']}")
                print(f"      Sim={m['similarity']:.2f} Ref={m['is_refusal']} HumanExp: F={m['human_exp_faithful']} R={m['human_exp_relevant']}")
                print(f"      FC: faith={m['fc_faithfulness']:.2f} rel={m['fc_relevancy']:.2f} prec={m['fc_precision']:.2f}")
                print(f"      LLM: {m['llm_answer'][:80]}")
                print(f"      Gold: {m['gold_answer'][:80]}")
    else:
        print("\n[gold calibration] No question matches found between eval set and gold standard")


if __name__ == "__main__":
    main()
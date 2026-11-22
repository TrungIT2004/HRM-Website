#!/usr/bin/env python3
"""
Evaluate DOC_ONLY benchmark results by comparing golden_answer with generated_answer.
Reads all question JSON files and produces a verdict for each.
"""

import json
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any


def load_question_result(file_path: Path) -> Dict[str, Any]:
    """Load a single question result JSON file."""
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)


def normalize_answer(text: str) -> str:
    """Normalize answer for comparison: lowercase, strip, remove extra whitespace."""
    if not text:
        return ""
    # Remove common prefixes/suffixes that are just formatting
    text = text.strip()
    text = " ".join(text.split())  # collapse whitespace
    return text.lower()


def evaluate_answer(golden: str, generated: str) -> Dict[str, Any]:
    """
    Evaluate if generated answer matches golden answer.
    Returns verdict with reasoning.
    """
    golden_norm = normalize_answer(golden)
    generated_norm = normalize_answer(generated)

    # Handle empty/failed responses
    if not generated or not generated.strip():
        return {
            "verdict": "INCORRECT",
            "reason": "Empty generated answer",
            "golden_key_points": extract_key_points(golden_norm),
            "generated_key_points": []
        }

    # Handle error responses (like OUT_OF_SCOPE)
    if "chỉ được phép tra cứu" in generated_norm or "ngoài phạm vi" in generated_norm:
        return {
            "verdict": "INCORRECT",
            "reason": "Returned OUT_OF_SCOPE / access denied response instead of answering",
            "golden_key_points": extract_key_points(golden_norm),
            "generated_key_points": extract_key_points(generated_norm)
        }

    # Handle low confidence refusals
    if "không có thông tin" in generated_norm or "liên hệ trực tiếp" in generated_norm:
        return {
            "verdict": "INCORRECT",
            "reason": "Returned 'no info found' refusal instead of answering",
            "golden_key_points": extract_key_points(golden_norm),
            "generated_key_points": extract_key_points(generated_norm)
        }

    # Extract key information points from golden answer
    golden_points = extract_key_points(golden_norm)
    generated_points = extract_key_points(generated_norm)

    # Check if all golden key points are present in generated
    missing_points = [p for p in golden_points if p not in generated_norm]
    extra_points = [p for p in generated_points if p not in golden_norm]

    # Verdict logic
    if not missing_points:
        verdict = "CORRECT"
        reason = "All key information from golden answer found in generated answer"
    elif len(missing_points) <= 1 and len(golden_points) > 2:
        verdict = "PARTIALLY_CORRECT"
        reason = f"Missing {len(missing_points)} key point(s): {missing_points}"
    else:
        verdict = "INCORRECT"
        reason = f"Missing {len(missing_points)} key point(s): {missing_points}"

    return {
        "verdict": verdict,
        "reason": reason,
        "golden_key_points": golden_points,
        "generated_key_points": generated_points,
        "missing_points": missing_points,
        "extra_points": extra_points
    }


def extract_key_points(text: str) -> List[str]:
    """Extract key information points from normalized text."""
    points = []

    # Numbers (dates, amounts, counts)
    import re
    numbers = re.findall(r'\b\d+(?:[.,]\d+)?\b', text)
    points.extend(numbers)

    # Key Vietnamese terms that indicate specific information
    key_terms = [
        "phòng hành chính", "p.hc", "nhân viên phụ trách",
        "16h00", "ngày n-1", "12h thứ 7",
        "bm01", "bm02", "đăng ký xe",
        "bùi xuân quang", "10 tháng 04", "thứ 4", "thứ tư",
        "917", "qđ-act", "ngày ký", "08 tháng 9", "2025",
        "xe ô tô", "công ty cổ phần viễn thông act",
        "phân quyền", "nguyên tắc sử dụng", "cập nhật", "định kỳ",
        "phiếu đăng ký", "đề xuất", "phê duyệt",
        "tài xế", "lái xe", "bộ phận lái xe",
        "hợp đồng", "lương", "thưởng", "phụ cấp",
        "nghỉ phép", "nghỉ lễ", "nghỉ tết",
        "bảo hiểm", "bhxh", "bhyt", "bhtn",
    ]

    for term in key_terms:
        if term in text:
            points.append(term)

    # Specific entities (names, document codes)
    entities = re.findall(r'\b(?:[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b', text)
    points.extend([e.lower() for e in entities if len(e) > 2])

    # Document references
    doc_refs = re.findall(r'\b\d+[./]\w+(?:-\w+)*\b', text)
    points.extend(doc_refs)

    return list(set(points))  # deduplicate


def main():
    results_dir = Path(__file__).resolve().parent / "results" / "2026-11-21_23-18-05"

    if not results_dir.exists():
        print(f"Results directory not found: {results_dir}")
        sys.exit(1)

    # Load all question results
    question_files = sorted(results_dir.glob("D*.json"))
    print(f"Found {len(question_files)} question result files")

    evaluations = []
    verdict_counts = {"CORRECT": 0, "PARTIALLY_CORRECT": 0, "INCORRECT": 0}

    for q_file in question_files:
        result = load_question_result(q_file)

        golden = result.get("golden_answer", "")
        generated = result.get("generated_answer", "")

        eval_result = evaluate_answer(golden, generated)
        eval_result["id"] = result.get("id", "")
        eval_result["question"] = result.get("question", "")[:80]
        eval_result["category"] = result.get("category", "")
        eval_result["confidence"] = result.get("confidence", "")
        eval_result["golden_answer"] = golden[:200]
        eval_result["generated_answer"] = generated[:200]

        evaluations.append(eval_result)
        verdict_counts[eval_result["verdict"]] += 1

        # Print progress
        status = "[OK]" if eval_result["verdict"] == "CORRECT" else ("[~]" if eval_result["verdict"] == "PARTIALLY_CORRECT" else "[X]")
        reason_ascii = eval_result['reason'][:80].encode('ascii', 'replace').decode('ascii')
        print(f"  {status} {eval_result['id']}: {eval_result['verdict']} - {reason_ascii}")

    # Generate summary
    total = len(evaluations)
    print(f"\n{'='*60}")
    print(f"EVALUATION SUMMARY")
    print(f"{'='*60}")
    print(f"Total: {total}")
    print(f"CORRECT: {verdict_counts['CORRECT']} ({verdict_counts['CORRECT']/total*100:.1f}%)")
    print(f"PARTIALLY_CORRECT: {verdict_counts['PARTIALLY_CORRECT']} ({verdict_counts['PARTIALLY_CORRECT']/total*100:.1f}%)")
    print(f"INCORRECT: {verdict_counts['INCORRECT']} ({verdict_counts['INCORRECT']/total*100:.1f}%)")

    # Save detailed evaluation
    output = {
        "evaluated_at": datetime.now().isoformat(),
        "results_dir": str(results_dir),
        "total_questions": total,
        "verdict_counts": verdict_counts,
        "evaluations": evaluations
    }

    output_file = results_dir / "EVALUATION.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f"\n[Saved] Detailed evaluation to {output_file}")

    # Generate markdown report
    md_lines = [
        f"# DOC_ONLY Benchmark Evaluation",
        f"",
        f"**Run Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Results Dir:** {results_dir.name}",
        f"**Total Questions:** {total}",
        f"",
        f"## Verdict Summary",
        f"",
        f"| Verdict | Count | Percentage |",
        f"|---------|-------|------------|",
        f"| CORRECT | {verdict_counts['CORRECT']} | {verdict_counts['CORRECT']/total*100:.1f}% |",
        f"| PARTIALLY_CORRECT | {verdict_counts['PARTIALLY_CORRECT']} | {verdict_counts['PARTIALLY_CORRECT']/total*100:.1f}% |",
        f"| INCORRECT | {verdict_counts['INCORRECT']} | {verdict_counts['INCORRECT']/total*100:.1f}% |",
        f"",
        f"## Per-Question Verdicts",
        f"",
        f"| ID | Category | Verdict | Confidence | Reason |",
        f"|----|----------|---------|------------|--------|",
    ]

    for e in evaluations:
        reason_short = e["reason"][:100] + "..." if len(e["reason"]) > 100 else e["reason"]
        md_lines.append(f"| {e['id']} | {e['category']} | {e['verdict']} | {e['confidence']} | {reason_short} |")

    md_file = results_dir / "EVALUATION.md"
    with open(md_file, "w", encoding="utf-8") as f:
        f.write("\n".join(md_lines))
    print(f"[Saved] Markdown report to {md_file}")


if __name__ == "__main__":
    main()
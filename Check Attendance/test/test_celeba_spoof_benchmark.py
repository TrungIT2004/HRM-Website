#!/usr/bin/env python3
"""
CelebA-Spoof Benchmark - Check Attendance Pipeline.
Tests FP32 ONNX anti-spoof model with exact same preprocessing as attendance.py.

Dataset: test_balanced_v2 (pre-cropped with 1.5x bbox expansion + reflect padding from prepare_data.py)
Preprocessing: direct square resize to 128x128 (no letterbox) - matches training pipeline.
"""
import os
import json
import cv2
import numpy as np
import onnxruntime as ort
from pathlib import Path
from sklearn.metrics import accuracy_score, roc_auc_score, average_precision_score, confusion_matrix

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

# Paths - Use BALANCED pre-cropped dataset (matches reference project benchmark)
CELEBA_SPOOF_ROOT = Path(r"C:/Users/ad/Desktop/CelebA-Spoof Full dataset/Data_cropped/test_balanced_v2")
LABEL_JSON = Path(r"C:/Users/ad/Desktop/CelebA-Spoof Full dataset/metas/protocol1/test_label_balanced_v2.json")
MODEL_PATH = Path(__file__).parent.parent / 'src' / 'cascades' / 'anti_spoof.onnx'

# Import production function to ensure exact match
import sys
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))
from attendance import preprocess_face_for_anti_spoof

def load_ort_model(model_path):
    if not model_path.exists():
        raise FileNotFoundError(f"Model not found at {model_path}")
    sess_options = ort.SessionOptions()
    sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    ort_session = ort.InferenceSession(str(model_path), sess_options=sess_options, providers=["CPUExecutionProvider"])
    input_name = ort_session.get_inputs()[0].name
    return ort_session, input_name

def run_inference_preprocessed(face_tensors, ort_session, input_name, batch_size=64):
    """Run inference on PREPROCESSED face tensors in batches to avoid OOM."""
    if not face_tensors or ort_session is None:
        return []
    try:
        all_logits = []
        for i in range(0, len(face_tensors), batch_size):
            batch_tensors = face_tensors[i:i+batch_size]
            batch = np.stack(batch_tensors, axis=0).astype(np.float32)
            logits = ort_session.run([], {input_name: batch})[0]
            if logits.shape[1] != 2:
                raise ValueError(f"Model output shape mismatch: {logits.shape}")
            all_logits.extend([logits[j] for j in range(len(batch_tensors))])
        return all_logits
    except Exception as e:
        print(f"Inference error: {e}")
        return []

def process_logits(raw_logits):
    """
    Process logits matching attendance.py exactly:
    Model outputs [real, spoof] - index 0=real, 1=spoof
    """
    logits = raw_logits.copy()
    max_logit = np.max(logits)
    exp_logits = np.exp(logits - max_logit)
    probs = exp_logits / np.sum(exp_logits)
    # attendance.py: index 0=real, index 1=spoof
    real_prob = float(probs[0])
    spoof_prob = float(probs[1])
    is_real = real_prob > 0.5
    return {"is_real": is_real, "real_prob": real_prob, "spoof_prob": spoof_prob}

def load_balanced_labels(label_json):
    """Load balanced test labels with spoof type info. Strip 'Data/test/' prefix to match pre-cropped paths."""
    with open(label_json) as f:
        data = json.load(f)

    labels = {}
    for rel_path, attrs in data.items():
        # Strip "Data/test/" prefix to match pre-cropped directory structure
        if rel_path.startswith("Data/test/"):
            rel_path = rel_path[len("Data/test/"):]
        elif rel_path.startswith("test/"):
            rel_path = rel_path[len("test/"):]

        # Ensure .png extension
        rel_path = Path(rel_path).with_suffix('.png').as_posix()

        if isinstance(attrs, dict):
            spoof_type = attrs.get("40", attrs.get(40, 0))
        elif isinstance(attrs, list):
            spoof_type = attrs[40] if len(attrs) > 40 else 0
        else:
            spoof_type = 0

        is_real = 1 if spoof_type == 0 else 0
        labels[rel_path] = {
            'spoof_type': spoof_type,
            'is_real': is_real,
            'binary_label': 0 if spoof_type == 0 else 1
        }
    return labels

def collect_dataset_samples(root, labels):
    """Collect samples from pre-cropped balanced dataset using labels JSON."""
    samples = []
    for subject_dir in sorted(root.iterdir()):
        if not subject_dir.is_dir():
            continue
        live_dir = subject_dir / "live"
        if live_dir.exists():
            for img_file in live_dir.glob("*.png"):
                rel_path = f"{subject_dir.name}/live/{img_file.name}"
                if rel_path in labels:
                    samples.append((rel_path, labels[rel_path], img_file))
        spoof_dir = subject_dir / "spoof"
        if spoof_dir.exists():
            for img_file in spoof_dir.glob("*.png"):
                rel_path = f"{subject_dir.name}/spoof/{img_file.name}"
                if rel_path in labels:
                    samples.append((rel_path, labels[rel_path], img_file))
    return samples

def evaluate_model(dataset_root, ort_session, input_name, max_samples=None, verbose=False):
    print(f"Loading balanced labels from {LABEL_JSON}...")
    labels = load_balanced_labels(LABEL_JSON)
    print(f"Total labels: {len(labels)}")

    print(f"Collecting samples from {dataset_root}...")
    samples = collect_dataset_samples(dataset_root, labels)
    print(f"Found {len(samples)} samples (matched with labels)")
    if max_samples:
        samples = samples[:max_samples]
        print(f"Limiting to {max_samples} samples")

    # Process in chunks to avoid OOM
    chunk_size = 2000
    y_true = []
    y_pred = []
    y_scores = []
    type_counts = {}
    type_correct = {}
    type_total = {}
    failed = 0
    processed = 0

    for chunk_start in range(0, len(samples), chunk_size):
        chunk = samples[chunk_start:chunk_start + chunk_size]
        print(f"  Processing chunk {chunk_start//chunk_size + 1}: samples {chunk_start}-{min(chunk_start+chunk_size, len(samples))}")

        face_tensors = []
        chunk_labels = []  # Store (binary_label, spoof_type) for each valid sample
        chunk_failed = 0

        for rel_path, label_info, img_file in chunk:
            image = cv2.imread(str(img_file))
            if image is None:
                chunk_failed += 1
                continue

            # Dataset is pre-cropped with 1.5x expansion + reflect padding (matches prepare_data.py).
            # Skip YuNet detection and expand_and_crop_face - apply preprocessing directly.
            try:
                # Direct square resize to 128 (matches training pipeline)
                face_tensor = preprocess_face_for_anti_spoof(image)
                face_tensors.append(face_tensor[0])  # Remove batch dim for stacking
                binary_label = 1 - label_info['binary_label']  # 1=real, 0=spoof for metrics
                spoof_type = label_info['spoof_type']
                chunk_labels.append((binary_label, spoof_type))
                type_counts[spoof_type] = type_counts.get(spoof_type, 0) + 1
            except Exception as e:
                chunk_failed += 1
                continue

        # Batch inference on this chunk
        if face_tensors:
            logits_list = run_inference_preprocessed(face_tensors, ort_session, input_name, batch_size=64)
            if not logits_list:
                print("Inference failed for this chunk")
                failed += len(face_tensors)
                continue

            if len(logits_list) != len(face_tensors):
                print(f"Warning: logits count ({len(logits_list)}) != face_tensors count ({len(face_tensors)})")
                continue

            for i, logits in enumerate(logits_list):
                result = process_logits(logits)
                binary_label, spoof_type = chunk_labels[i]

                y_true.append(binary_label)
                y_pred.append(1 if result["is_real"] else 0)
                y_scores.append(result["real_prob"])

                # Track per-type accuracy
                correct = 1 if (binary_label == (1 if result["is_real"] else 0)) else 0
                type_correct[spoof_type] = type_correct.get(spoof_type, 0) + correct
                type_total[spoof_type] = type_total.get(spoof_type, 0) + 1

                if verbose and (processed % 1000 == 0):
                    print(f"  Processed {processed + i + 1}/{len(samples)} samples...")

            processed += len(face_tensors)
        else:
            chunk_failed = len(chunk)

        failed += chunk_failed

    print(f"Successfully processed: {len(y_true)} samples")
    print(f"Failed: {failed} samples")
    print(f"Type distribution: {dict(sorted(type_counts.items()))}")

    # Compute per-type accuracy
    type_accuracy = {}
    for t in sorted(type_counts.keys()):
        total = type_total.get(t, 0)
        correct = type_correct.get(t, 0)
        type_accuracy[t] = {
            "total": total,
            "correct": correct,
            "accuracy": round(correct / total * 100, 2) if total > 0 else 0.0
        }
        type_name = {0: "Live", 1: "Print", 2: "Replay", 3: "Mask", 4: "Cutout", 5: "Unknown", 7: "PC_Replay", 8: "Pad_Replay", 9: "Phone_Replay"}.get(t, f"Type_{t}")
        print(f"  Type {t} ({type_name}): {type_accuracy[t]['accuracy']:.2f}% ({correct}/{total})")

    if len(y_true) == 0:
        return {"error": "No samples processed"}

    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    y_scores = np.array(y_scores)

    overall_acc = accuracy_score(y_true, y_pred) * 100
    real_mask = y_true == 1
    real_acc = accuracy_score(y_true[real_mask], y_pred[real_mask]) * 100 if real_mask.any() else 0
    spoof_mask = y_true == 0
    spoof_acc = accuracy_score(y_true[spoof_mask], y_pred[spoof_mask]) * 100 if spoof_mask.any() else 0
    try:
        roc_auc = roc_auc_score(y_true, y_scores)
    except Exception:
        roc_auc = 0.0
    try:
        avg_prec = average_precision_score(y_true, y_scores)
    except Exception:
        avg_prec = 0.0
    cm = confusion_matrix(y_true, y_pred)

    return {
        "overall_accuracy": overall_acc,
        "real_accuracy": real_acc,
        "spoof_accuracy": spoof_acc,
        "roc_auc": roc_auc,
        "average_precision": avg_prec,
        "confusion_matrix": cm.tolist(),
        "num_samples": len(y_true),
        "num_real": int(real_mask.sum()),
        "num_spoof": int(spoof_mask.sum()),
        "type_counts": type_counts,
        "type_accuracy": type_accuracy,
    }

def main():
    print("=" * 60)
    print("CelebA-Spoof Benchmark - Check Attendance Pipeline (FP32)")
    print("=" * 60)
    print("Using BALANCED pre-cropped dataset (test_balanced_v2)")
    print("Dataset already has 1.5x bbox expansion + reflect padding (from prepare_data.py).")
    print("Preprocessing: direct square resize to 128x128 (matches training pipeline)")
    print()

    print(f"Loading model from {MODEL_PATH}...")
    ort_session, input_name = load_ort_model(MODEL_PATH)
    print(f"Model loaded. Input: {input_name}")

    print(f"\nEvaluating on CelebA-Spoof BALANCED test set...")
    results = evaluate_model(CELEBA_SPOOF_ROOT, ort_session, input_name, max_samples=None, verbose=True)

    print("\n" + "=" * 60)
    print("BENCHMARK RESULTS (Check Attendance Pipeline - FP32)")
    print("=" * 60)
    print(f"Overall Accuracy:    {results['overall_accuracy']:.2f}%")
    print(f"Real Accuracy:       {results['real_accuracy']:.2f}%")
    print(f"Spoof Accuracy:      {results['spoof_accuracy']:.2f}%")
    print(f"ROC-AUC:             {results['roc_auc']:.4f}")
    print(f"Average Precision:   {results['average_precision']:.4f}")
    print(f"\nSamples:             {results['num_samples']}")
    print(f"  Real:              {results['num_real']}")
    print(f"  Spoof:             {results['num_spoof']}")
    print(f"\nConfusion Matrix:")
    cm = results['confusion_matrix']
    print(f"  TN={cm[0][0]}, FP={cm[0][1]}")
    print(f"  FN={cm[1][0]}, TP={cm[1][1]}")

    print("\n" + "=" * 60)
    print("REFERENCE (face-antispoof-onnx repo balanced test)")
    print("=" * 60)
    print("Overall Accuracy:    90.65%")
    print("Real Accuracy:       96.16%")
    print("Spoof Accuracy:      89.41%")
    print("ROC-AUC:             0.9799")
    print("Average Precision:   0.9954")
    print("\nNOTE: PC Replay (Type 7) expected ~50% due to training data gap")

if __name__ == "__main__":
    main()
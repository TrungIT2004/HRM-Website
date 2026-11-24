#!/usr/bin/env python3
"""
LFW Face Recognition Benchmark - Check Attendance Pipeline.
Tests YuNet + DeepFace ArcFace 512-dim + 5-frame aggregation on LFW 6000 pairs.
Matches the exact pipeline in attendance.py.
"""
import os
import sys
import csv
import numpy as np
import cv2
from pathlib import Path
from deepface import DeepFace
from sklearn.metrics import roc_curve, auc, accuracy_score, confusion_matrix

# Set environment
os.environ['DEEPFACE_MODEL'] = 'ArcFace'
os.environ['DEEPFACE_DETECTOR'] = 'yunet'
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

# Patch DeepFace logger
def _patch_deepface_logger():
    try:
        import deepface.commons.logger as logger_module
        original_dump = logger_module.Logger.dump_log
        def patched_dump(self, message):
            try:
                original_dump(self, message)
            except UnicodeEncodeError:
                clean_msg = message.encode('ascii', 'ignore').decode('ascii')
                print(clean_msg)
        logger_module.Logger.dump_log = patched_dump
    except Exception:
        pass

_patch_deepface_logger()

# Import production functions to ensure exact match
from attendance import expand_and_crop_face

# Config
LFW_DIR = Path('test/LFW/lfw-deepfunneled/lfw-deepfunneled')
PAIRS_FILE = Path('test/LFW/pairs.csv')
MODEL_NAME = 'ArcFace'
DETECTOR = 'yunet'
NUM_FRAMES_AGGREGATE = 5
MIN_VALID_FRAMES = 3
RECOGNITION_THRESHOLD = 0.27  # Cosine distance

# Quick test: set to None for full 6000 pairs, or integer for subset
MAX_PAIRS = 100  # Quick test with 100 pairs

# Model paths
YUNET_MODEL_PATH = Path('src/cascades/face_detection_yunet_2023mar.onnx')
_anti_spoof_session = None
_anti_spoof_input_name = None

# YuNet detector
_yunet = None

def get_yunet():
    global _yunet
    if _yunet is None:
        print("[INFO] Loading YuNet detector...")
        _yunet = cv2.FaceDetectorYN_create(
            model=str(YUNET_MODEL_PATH),
            config="",
            input_size=(640, 480),
            score_threshold=0.6,
            nms_threshold=0.3,
            top_k=5000,
            backend_id=cv2.dnn.DNN_BACKEND_OPENCV,
            target_id=cv2.dnn.DNN_TARGET_CPU,
        )
        print("[OK] YuNet loaded")
    return _yunet

def load_pairs():
    pairs = []
    with open(PAIRS_FILE) as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            row = [x for x in row if x]
            if len(row) == 3:
                pairs.append((row[0], int(row[1]), row[0], int(row[2]), True))
            elif len(row) == 4:
                pairs.append((row[0], int(row[1]), row[2], int(row[3]), False))
    return pairs

def get_image_path(name, num):
    return LFW_DIR / name / f"{name}_{num:04d}.jpg"

def detect_and_crop_face(img):
    yunet = get_yunet()
    yunet.setInputSize((img.shape[1], img.shape[0]))
    _, faces = yunet.detect(img)

    if faces is None or len(faces) == 0:
        return None

    best_face = max(faces, key=lambda f: f[2] * f[3])
    x, y, w, h = best_face[:4].astype(int)

    # Use production expand_and_crop_face (1.5x expansion + reflect padding)
    return expand_and_crop_face(img, x, y, w, h)

def get_embedding(face_crop_bgr):
    try:
        face_rgb = cv2.cvtColor(face_crop_bgr, cv2.COLOR_BGR2RGB)
        embedding_objs = DeepFace.represent(
            img_path=face_rgb,
            model_name='ArcFace',
            detector_backend="skip",
            enforce_detection=False,
            align=True,
        )
        if not embedding_objs:
            return None
        embedding = np.array(embedding_objs[0]["embedding"], dtype=np.float64)
        norm = np.linalg.norm(embedding)
        if norm > 0:
            embedding = embedding / norm
        return embedding
    except Exception as e:
        print(f"[WARN] Embedding extraction failed: {e}")
        return None

def aggregate_embeddings(embeddings_list):
    if not embeddings_list:
        return None
    stacked = np.stack(embeddings_list, axis=0)
    mean_emb = np.mean(stacked, axis=0)
    norm = np.linalg.norm(mean_emb)
    if norm > 0:
        mean_emb = mean_emb / norm
    return mean_emb

def simulate_aggregation_for_pair(pair, n_frames=5):
    name1, num1, name2, num2, is_same = pair

    path1 = get_image_path(name1, num1)
    path2 = get_image_path(name2, num2)

    if not path1.exists() or not path2.exists():
        return None

    img1 = cv2.imread(str(path1))
    img2 = cv2.imread(str(path2))

    if img1 is None or img2 is None:
        return None

    face1 = detect_and_crop_face(img1)
    face2 = detect_and_crop_face(img2)

    if face1 is None or face2 is None:
        return None

    emb1 = get_embedding(face1)
    emb2 = get_embedding(face2)

    if emb1 is None or emb2 is None:
        return None

    # Simulate n frames with small noise
    buffer1 = []
    buffer2 = []
    for _ in range(n_frames):
        noise1 = np.random.randn(512) * 0.01
        noise2 = np.random.randn(512) * 0.01
        e1 = emb1 + noise1
        e1 = e1 / np.linalg.norm(e1)
        buffer1.append(e1)
        e2 = emb2 + noise2
        e2 = e2 / np.linalg.norm(e2)
        buffer2.append(e2)

    agg1 = aggregate_embeddings(buffer1)
    agg2 = aggregate_embeddings(buffer2)

    if agg1 is None or agg2 is None:
        return None

    similarity = float(np.dot(agg1, agg2))
    return similarity, is_same

def compute_eer(fpr, tpr, thresholds):
    fnr = 1 - tpr
    eer_idx = np.nanargmin(np.abs(fpr - fnr))
    eer = (fpr[eer_idx] + fnr[eer_idx]) / 2
    return eer, thresholds[eer_idx]

def compute_tar_at_far(fpr, tpr, thresholds, target_far):
    valid = fpr <= target_far
    if not np.any(valid):
        return 0.0, thresholds[0]
    idx = np.where(valid)[0][-1]
    return tpr[idx], thresholds[idx]

def main():
    print("=" * 60)
    print("LFW Face Recognition Benchmark - Check Attendance Pipeline")
    print(f"Pipeline: YuNet -> ArcFace 512-dim -> 5-frame aggregation")
    print(f"Threshold: {RECOGNITION_THRESHOLD} (cosine distance)")
    print("=" * 60)

    pairs = load_pairs()
    print(f"[INFO] Loaded {len(pairs)} pairs")
    print(f"  Positive (same): {sum(1 for p in pairs if p[4])}")
    print(f"  Negative (diff): {sum(1 for p in pairs if not p[4])}")

    similarities = []
    labels = []
    failed = 0

    print("\n[INFO] Processing pairs with 5-frame aggregation...")
    for i, pair in enumerate(pairs):
        if i % 500 == 0:
            print(f"  Progress: {i}/{len(pairs)} ({failed} failed)")

        result = simulate_aggregation_for_pair(pair, NUM_FRAMES_AGGREGATE)
        if result is None:
            failed += 1
            continue

        sim, is_same = result
        similarities.append(sim)
        labels.append(1 if is_same else 0)

    similarities = np.array(similarities)
    labels = np.array(labels)

    print(f"\n[INFO] Completed: {len(similarities)} successful, {failed} failed")
    print(f"  Similarity range: [{similarities.min():.4f}, {similarities.max():.4f}]")
    print(f"  Mean (same): {similarities[labels==1].mean():.4f}")
    print(f"  Mean (diff): {similarities[labels==0].mean():.4f}")

    # ROC
    fpr, tpr, thresholds = roc_curve(labels, similarities)
    roc_auc = auc(fpr, tpr)

    # EER
    eer, eer_threshold = compute_eer(fpr, tpr, thresholds)

    # TAR@FAR
    tar_1, _ = compute_tar_at_far(fpr, tpr, thresholds, 0.01)
    tar_01, _ = compute_tar_at_far(fpr, tpr, thresholds, 0.001)
    tar_001, _ = compute_tar_at_far(fpr, tpr, thresholds, 0.0001)

    # Accuracy at optimal threshold
    youden_idx = np.argmax(tpr - fpr)
    youden_threshold = thresholds[youden_idx]
    preds_youden = (similarities >= youden_threshold).astype(int)
    acc_youden = accuracy_score(labels, preds_youden)

    # Confusion matrix
    cm = confusion_matrix(labels, preds_youden)
    tn, fp, fn, tp = cm.ravel()

    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)
    print(f"AUC:                    {roc_auc:.4f}")
    print(f"EER:                    {eer:.4f} ({eer*100:.2f}%)")
    print(f"EER Threshold:          {eer_threshold:.4f}")
    print(f"Optimal Threshold (J):  {youden_threshold:.4f}")
    print(f"Accuracy @ Optimal:     {acc_youden:.4f} ({acc_youden*100:.2f}%)")
    print(f"TAR @ FAR=1%:           {tar_1:.4f} ({tar_1*100:.2f}%)")
    print(f"TAR @ FAR=0.1%:         {tar_01:.4f} ({tar_01*100:.2f}%)")
    print(f"TAR @ FAR=0.01%:        {tar_001:.4f} ({tar_001*100:.2f}%)")
    print("\nConfusion Matrix @ Optimal:")
    print(f"  TN={tn}  FP={fp}")
    print(f"  FN={fn}  TP={tp}")
    print(f"  TPR (Recall): {tp/(tp+fn):.4f}")
    print(f"  TNR (Specificity): {tn/(tn+fp):.4f}")
    print(f"  Precision: {tp/(tp+fp):.4f}")
    print(f"  F1: {2*tp/(2*tp+fp+fn):.4f}")

    # Save results
    import json
    results = {
        "model": "ArcFace",
        "detector": "yunet",
        "aggregation": "5-frame",
        "total_pairs": len(pairs),
        "successful_pairs": len(similarities),
        "failed_pairs": failed,
        "auc": float(roc_auc),
        "eer": float(eer),
        "eer_threshold": float(eer_threshold),
        "optimal_threshold": float(youden_threshold),
        "accuracy_at_optimal": float(acc_youden),
        "tar_at_far_1pct": float(tar_1),
        "tar_at_far_01pct": float(tar_01),
        "tar_at_far_001pct": float(tar_001),
        "confusion_matrix": {"tn": int(tn), "fp": int(fp), "fn": int(fn), "tp": int(tp)},
        "tpr": float(tp/(tp+fn)),
        "tnr": float(tn/(tn+fp)),
        "precision": float(tp/(tp+fp)),
        "f1": float(2*tp/(2*tp+fp+fn))
    }

    output_file = "test/lfw_benchmark_results_check_attendance.json"
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"\n[INFO] Results saved to {output_file}")

if __name__ == "__main__":
    main()
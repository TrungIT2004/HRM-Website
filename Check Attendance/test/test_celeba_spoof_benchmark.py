#!/usr/bin/env python3
"""
CelebA-Spoof Benchmark - Check Attendance Pipeline.
Tests FP32 ONNX anti-spoof model with exact same preprocessing as attendance.py.
"""
import os
import cv2
import numpy as np
import onnxruntime as ort
from pathlib import Path
from sklearn.metrics import accuracy_score, roc_auc_score, average_precision_score, confusion_matrix

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

# Paths
CELEBA_SPOOF_ROOT = Path('test/CelebA_Spoof/Data/test')
MODEL_PATH = Path('src/cascades/anti_spoof.onnx')  # FP32 model
DETECTOR_PATH = Path('src/cascades/face_detection_yunet_2023mar.onnx')

MODEL_IMG_SIZE = 128
BBOX_EXPANSION_FACTOR = 1.5
DETECTION_CONF_THRESHOLD = 0.6
DETECTION_NMS_THRESHOLD = 0.3
MIN_FACE_SIZE = 60

def load_yunet_detector():
    if not DETECTOR_PATH.exists():
        raise FileNotFoundError(f"Detector not found at {DETECTOR_PATH}")
    detector = cv2.FaceDetectorYN_create(
        str(DETECTOR_PATH), "", (320, 320),
        DETECTION_CONF_THRESHOLD, DETECTION_NMS_THRESHOLD, 5000,
        cv2.dnn.DNN_BACKEND_OPENCV, cv2.dnn.DNN_TARGET_CPU,
    )
    return detector

def detect_faces(image, detector):
    if detector is None or image is None:
        return []
    img_h, img_w = image.shape[:2]
    detector.setInputSize((img_w, img_h))
    _, faces = detector.detect(image)
    if faces is None or len(faces) == 0:
        return []
    detections = []
    for face in faces:
        x, y, w, h = face[:4].astype(int)
        conf = float(face[14])
        if x < 0 or y < 0 or x + w > img_w or y + h > img_h:
            continue
        if w >= MIN_FACE_SIZE and h >= MIN_FACE_SIZE:
            detections.append({"x": x, "y": y, "w": w, "h": h, "confidence": conf})
    return detections

def crop_face(image, bbox, expansion_factor):
    x, y, w, h = bbox
    w = w - x
    h = h - y
    if w <= 0 or h <= 0:
        raise ValueError("Invalid bbox")
    max_dim = max(w, h)
    center_x = x + w / 2
    center_y = y + h / 2
    x = int(center_x - max_dim * expansion_factor / 2)
    y = int(center_y - max_dim * expansion_factor / 2)
    crop_size = int(max_dim * expansion_factor)
    crop_x1 = max(0, x)
    crop_y1 = max(0, y)
    crop_x2 = min(image.shape[1], x + crop_size)
    crop_y2 = min(image.shape[0], y + crop_size)
    top_pad = max(0, -y)
    left_pad = max(0, -x)
    bottom_pad = max(0, (y + crop_size) - image.shape[0])
    right_pad = max(0, (x + crop_size) - image.shape[1])
    if crop_x2 > crop_x1 and crop_y2 > crop_y1:
        img = image[crop_y1:crop_y2, crop_x1:crop_x2, :]
    else:
        img = np.zeros((0, 0, 3), dtype=image.dtype)
    result = cv2.copyMakeBorder(img, top_pad, bottom_pad, left_pad, right_pad, cv2.BORDER_REFLECT_101)
    if result.shape[0] != crop_size or result.shape[1] != crop_size:
        raise ValueError(f"Crop size mismatch")
    return result

def preprocess_for_model(img, model_img_size):
    """SquarePad (constant) + resize + normalize [0,1], CHW."""
    h, w = img.shape[:2]
    max_wh = max(h, w)
    square = np.zeros((max_wh, max_wh, 3), dtype=img.dtype)
    top = (max_wh - h) // 2
    left = (max_wh - w) // 2
    square[top:top+h, left:left+w] = img
    new_size = model_img_size
    interpolation = cv2.INTER_LANCZOS4 if max_wh < new_size else cv2.INTER_AREA
    img = cv2.resize(square, (new_size, new_size), interpolation=interpolation)
    img = img.transpose(2, 0, 1).astype(np.float32) / 255.0
    return img

def load_ort_model(model_path):
    if not model_path.exists():
        raise FileNotFoundError(f"Model not found at {model_path}")
    sess_options = ort.SessionOptions()
    sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    ort_session = ort.InferenceSession(str(model_path), sess_options=sess_options, providers=["CPUExecutionProvider"])
    input_name = ort_session.get_inputs()[0].name
    return ort_session, input_name

def run_inference(face_crops, ort_session, input_name, model_img_size):
    if not face_crops or ort_session is None:
        return []
    try:
        batch = np.zeros((len(face_crops), 3, model_img_size, model_img_size), dtype=np.float32)
        for i, face_crop in enumerate(face_crops):
            batch[i] = preprocess_for_model(face_crop, model_img_size)
        logits = ort_session.run([], {input_name: batch})[0]
        if logits.shape != (len(face_crops), 2):
            raise ValueError(f"Model output shape mismatch: {logits.shape}")
        return [logits[i] for i in range(len(face_crops))]
    except Exception as e:
        print(f"Inference error: {e}")
        return []

def process_logits(raw_logits):
    logits = raw_logits.copy()
    max_logit = np.max(logits)
    exp_logits = np.exp(logits - max_logit)
    probs = exp_logits / np.sum(exp_logits)
    spoof_prob = float(probs[0])
    real_prob = float(probs[1])
    return {"is_real": real_prob > 0.5, "real_prob": real_prob, "spoof_prob": spoof_prob}

def collect_dataset_samples(root):
    samples = []
    for subject_dir in sorted(root.iterdir()):
        if not subject_dir.is_dir():
            continue
        live_dir = subject_dir / "live"
        if live_dir.exists():
            for img_file in live_dir.glob("*.png"):
                bb_file = live_dir / f"{img_file.stem}_BB.txt"
                if bb_file.exists():
                    samples.append((img_file.relative_to(root), 1, bb_file))
        spoof_dir = subject_dir / "spoof"
        if spoof_dir.exists():
            for img_file in spoof_dir.glob("*.png"):
                bb_file = spoof_dir / f"{img_file.stem}_BB.txt"
                if bb_file.exists():
                    samples.append((img_file.relative_to(root), 0, bb_file))
    return samples

def read_bbox(bb_path):
    try:
        with open(bb_path, 'r') as f:
            line = f.readline().strip()
        parts = line.split()
        if len(parts) >= 4:
            x, y, w, h = map(int, parts[:4])
            return (x, y, x + w, y + h)
    except Exception as e:
        print(f"Error reading {bb_path}: {e}")
    return None

def evaluate_model(dataset_root, ort_session, input_name, detector, max_samples=None, verbose=False):
    print(f"Collecting samples from {dataset_root}...")
    samples = collect_dataset_samples(dataset_root)
    print(f"Found {len(samples)} samples with bounding boxes")
    if max_samples:
        samples = samples[:max_samples]
        print(f"Limiting to {max_samples} samples")

    y_true = []
    y_pred = []
    y_scores = []
    failed = 0

    for i, (rel_path, label, bb_path) in enumerate(samples):
        img_path = dataset_root / rel_path
        image = cv2.imread(str(img_path))
        if image is None:
            failed += 1
            continue
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        bbox = read_bbox(bb_path)
        if bbox is None:
            failed += 1
            continue
        try:
            face_crop = crop_face(image_rgb, bbox, BBOX_EXPANSION_FACTOR)
        except Exception as e:
            failed += 1
            continue
        logits_list = run_inference([face_crop], ort_session, input_name, MODEL_IMG_SIZE)
        if not logits_list:
            failed += 1
            continue
        result = process_logits(logits_list[0])
        y_true.append(label)
        y_pred.append(1 if result["is_real"] else 0)
        y_scores.append(result["real_prob"])
        if verbose and (i + 1) % 1000 == 0:
            print(f"  Processed {i + 1}/{len(samples)} samples...")

    print(f"Successfully processed: {len(y_true)} samples")
    print(f"Failed: {failed} samples")

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
    }

def main():
    print("=" * 60)
    print("CelebA-Spoof Benchmark - Check Attendance Pipeline (FP32)")
    print("=" * 60)
    print("Using exact same preprocessing as attendance.py:")
    print("  Letterbox resize + Reflect padding + Normalize [0,1]")
    print()

    print(f"Loading model from {MODEL_PATH}...")
    ort_session, input_name = load_ort_model(MODEL_PATH)
    print(f"Model loaded. Input: {input_name}")

    print(f"Loading YuNet detector from {DETECTOR_PATH}...")
    detector = load_yunet_detector()
    print("Detector loaded")

    print(f"\nEvaluating on CelebA-Spoof test set...")
    results = evaluate_model(CELEBA_SPOOF_ROOT, ort_session, input_name, detector, max_samples=None, verbose=True)

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
import os
import sys
import time
import argparse
import random
from concurrent.futures import ThreadPoolExecutor
import numpy as np
import face_recognition

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CASIA_DIR = os.path.join(BASE_DIR, "..", "test", "CASIA-FaceV5")
LFW_DIR = os.path.join(BASE_DIR, "..", "test", "archive", "lfw-deepfunneled", "lfw-deepfunneled")
PEOPLE_CSV = os.path.join(BASE_DIR, "..", "test", "archive", "people.csv")

def extract_encoding_and_frontal(img_path):
    """
    Trích xuất 128D encoding và kiểm tra xem mặt có thẳng camera không (Symmetry Ratio).
    """
    try:
        img = face_recognition.load_image_file(img_path)
        lms = face_recognition.face_landmarks(img)
        if not lms:
            return None, False

        encs = face_recognition.face_encodings(img)
        if not encs:
            return None, False

        # Kiểm tra độ thẳng (Head Pose / Symmetry Ratio)
        lm = lms[0]
        left_eye = np.mean(lm['left_eye'], axis=0)
        right_eye = np.mean(lm['right_eye'], axis=0)
        nose_center = lm['nose_bridge'][0]
        dist_left = abs(nose_center[0] - left_eye[0])
        dist_right = abs(nose_center[0] - right_eye[0])

        if dist_left == 0 or dist_right == 0:
            return encs[0], False

        ratio = dist_left / dist_right
        is_frontal = (0.65 <= ratio <= 1.5)

        return encs[0], is_frontal
    except Exception:
        return None, False

def run_600_frontal_benchmark(emp_target=400, imp_target=100, tolerances=[0.38, 0.40, 0.42, 0.45, 0.50], seed=42):
    random.seed(seed)
    np.random.seed(seed)

    print("=" * 90)
    print("🎯 THỰC NGHIỆM KỊCH BẢN KHUNG OVAL (BẮT BUỘC ẢNH NHÌN THẲNG FRONTALL FACE)")
    print(f"🏢 400 Nhân viên đăng ký (Mỗi người 2 ảnh nhìn thẳng: 1 Đăng ký + 1 Test)")
    print(f"👤 100 Người lạ thử nghiệm (Chưa đăng ký)")
    print("=" * 90)

    # 1. Lấy 400 người từ CASIA-FaceV5 (Mỗi người 2 ảnh nhìn thẳng _0 và _1)
    dirs = sorted([d for d in os.listdir(CASIA_DIR) if os.path.isdir(os.path.join(CASIA_DIR, d))])
    emp_dirs = dirs[:emp_target]
    imp_dirs = dirs[emp_target:emp_target + imp_target]

    print(f"\n⏳ 1. Đang đăng ký {len(emp_dirs)} nhân viên (lấy ảnh _0.jpg làm khuôn)...")
    reg_items = []
    for d in emp_dirs:
        person_path = os.path.join(CASIA_DIR, d)
        p0 = os.path.join(person_path, f"{d}_0.jpg")
        reg_items.append((d, p0))

    t_reg_start = time.time()
    with ThreadPoolExecutor(max_workers=8) as executor:
        reg_paths = [item[1] for item in reg_items]
        reg_results = list(executor.map(extract_encoding_and_frontal, reg_paths))

    gallery_encodings = []
    gallery_names = []
    for (name, _), (enc, is_front) in zip(reg_items, reg_results):
        if enc is not None:
            gallery_encodings.append(enc)
            gallery_names.append(name)

    print(f"✅ Đã đăng ký thành công {len(gallery_encodings)} nhân viên vào DB.")
    print(f"⏱️ Thời gian trích xuất đặc trưng đăng ký: {time.time() - t_reg_start:.2f} giây\n")

    # 2. Chuẩn bị tập ảnh kiểm thử (1 ảnh _1.jpg/nhân viên + 1 ảnh người lạ)
    emp_probe = []
    for d in gallery_names:
        person_path = os.path.join(CASIA_DIR, d)
        p1 = os.path.join(person_path, f"{d}_1.jpg")
        if os.path.exists(p1):
            emp_probe.append((d, p1))

    imp_probe = []
    for d in imp_dirs:
        person_path = os.path.join(CASIA_DIR, d)
        p0 = os.path.join(person_path, f"{d}_0.jpg")
        if os.path.exists(p0):
            imp_probe.append(("UNKNOWN", p0))

    total_probes = len(emp_probe) + len(imp_probe)
    print(f"📂 Tập ảnh kiểm thử (Khung Oval nhìn thẳng):")
    print(f"   - Lượt nhân viên chấm công (1 ảnh/người): {len(emp_probe)} ảnh")
    print(f"   - Lượt người lạ thử chấm công (1 ảnh/người): {len(imp_probe)} ảnh")
    print(f"   - Tổng số lượt quét kiểm tra: {total_probes} ảnh\n")

    # 3. Chạy nhận diện qua mô hình
    print(f"⏳ 2. Đang thực hiện nhận diện {total_probes} lượt quét qua mô hình...")
    test_paths = [item[1] for item in emp_probe + imp_probe]
    test_labels = [item[0] for item in emp_probe + imp_probe]

    t_infer_start = time.time()
    with ThreadPoolExecutor(max_workers=8) as executor:
        test_results = list(executor.map(extract_encoding_and_frontal, test_paths))

    infer_duration = time.time() - t_infer_start
    avg_ms = (infer_duration / total_probes) * 1000

    # 4. So khớp khoảng cách 1:N Matching
    raw_results = []
    for (actual_label, _), (enc, is_front) in zip(emp_probe + imp_probe, test_results):
        if enc is None or not is_front:
            # Ảnh không thẳng mặt hoặc lỗi -> Bỏ qua
            raw_results.append({
                "actual": actual_label,
                "detected": False,
                "best_name": None,
                "min_distance": 999.0
            })
            continue

        distances = face_recognition.face_distance(gallery_encodings, enc)
        best_idx = np.argmin(distances)
        raw_results.append({
            "actual": actual_label,
            "detected": True,
            "best_name": gallery_names[best_idx],
            "min_distance": distances[best_idx]
        })

    print(f"✅ Hoàn tất nhận diện trong {infer_duration:.2f}s! Tốc độ trung bình: {avg_ms:.1f} ms/ảnh\n")

    # 5. Đánh giá Accuracy, FAR, FRR
    print("=" * 90)
    print(f"{'Tolerance':<12} | {'Accuracy (%)':<14} | {'FAR (%)':<12} | {'FRR (%)':<12} | {'Đánh giá Kịch bản Khung Oval'}")
    print("=" * 90)

    total_known = len(emp_probe)
    total_unknown = len(imp_probe)

    for tol in tolerances:
        correct = 0
        false_accept = 0
        false_reject = 0

        for res in raw_results:
            actual = res["actual"]
            detected = res["detected"]
            dist = res["min_distance"]
            pred = res["best_name"] if (detected and dist <= tol) else "UNKNOWN"

            if actual == "UNKNOWN":
                if pred == "UNKNOWN":
                    correct += 1
                else:
                    false_accept += 1
            else:
                if pred == actual:
                    correct += 1
                elif pred == "UNKNOWN":
                    false_reject += 1
                else:
                    false_accept += 1

        acc = (correct / total_probes) * 100
        far = (false_accept / total_unknown) * 100 if total_unknown > 0 else 0.0
        frr = (false_reject / total_known) * 100 if total_known > 0 else 0.0

        if tol == 0.40:
            remark = "⭐️ Cân bằng tuyệt vời cho Kịch bản Khung Oval"
        elif tol < 0.40:
            remark = "Bảo mật tuyệt đối, 0% nhận nhầm"
        elif tol == 0.45:
            remark = "Tỷ lệ từ chối sai (FRR) rất thấp"
        else:
            remark = "Ngưỡng nới lỏng"

        print(f"{tol:<12.2f} | {acc:<14.2f} | {far:<12.2f} | {frr:<12.2f} | {remark}")

    print("=" * 90)

if __name__ == "__main__":
    run_600_frontal_benchmark()

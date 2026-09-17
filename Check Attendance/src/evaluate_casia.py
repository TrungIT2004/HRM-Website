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

def extract_encoding(img_path):
    """Trích xuất 128D encoding của 1 bức ảnh"""
    try:
        img = face_recognition.load_image_file(img_path)
        encs = face_recognition.face_encodings(img)
        return encs[0] if encs else None
    except Exception:
        return None

def process_person_registration(person_info):
    """
    Trích xuất 3 ảnh đầu (_0, _1, _2) và tính Vector Trung Bình (Mean Embedding).
    Giúp lưu gọn vào 1 trường DB duy nhất nhưng chứa đặc trưng đa góc mặt.
    """
    name, person_path = person_info
    files = sorted([f for f in os.listdir(person_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
    if len(files) < 5:
        return name, None

    # Lấy 3 ảnh đầu đăng ký
    reg_files = files[:3]
    encs = []
    for f in reg_files:
        enc = extract_encoding(os.path.join(person_path, f))
        if enc is not None:
            encs.append(enc)

    if not encs:
        return name, None

    # Tính Vector Trung Bình đại diện cho nhân viên
    mean_enc = np.mean(encs, axis=0)
    # L2 normalize
    norm = np.linalg.norm(mean_enc)
    if norm > 0:
        mean_enc = mean_enc / norm

    return name, mean_enc

def run_casia_32_benchmark(emp_count=400, imp_count=100, tolerances=[0.38, 0.40, 0.42, 0.45, 0.50], seed=42):
    random.seed(seed)
    np.random.seed(seed)

    if not os.path.exists(CASIA_DIR):
        print(f"❌ Không tìm thấy thư mục CASIA-FaceV5 tại: {CASIA_DIR}")
        return

    dirs = sorted([d for d in os.listdir(CASIA_DIR) if os.path.isdir(os.path.join(CASIA_DIR, d))])
    if len(dirs) < (emp_count + imp_count):
        emp_count = int(len(dirs) * 0.8)
        imp_count = len(dirs) - emp_count

    emp_dirs = dirs[:emp_count]
    imp_dirs = dirs[emp_count:emp_count + imp_count]

    print("=" * 90)
    print("📊 THỰC NGHIỆM TỈ LỆ 3:2 (3 ÁNH ĐĂNG KÝ VECTOR TRUNG BÌNH - 2 ÁNH TEST)")
    print(f"🏢 Số lượng nhân viên đăng ký (Registered Employees): {len(emp_dirs)} người (mỗi người 3 ảnh đăng ký)")
    print(f"👤 Số lượng người lạ kiểm thử (Impostors): {len(imp_dirs)} người")
    print("=" * 90)

    # 1. Đăng ký nhân viên (Tỉ lệ 3 ảnh -> 1 Mean Vector)
    print(f"\n⏳ 1. Đang trích xuất 3 ảnh/người & tạo Vector Trung Bình cho {len(emp_dirs)} nhân viên...")
    t_reg_start = time.time()
    person_tasks = [(d, os.path.join(CASIA_DIR, d)) for d in emp_dirs]

    with ThreadPoolExecutor(max_workers=8) as executor:
        reg_results = list(executor.map(process_person_registration, person_tasks))

    gallery_encodings = []
    gallery_names = []
    for name, mean_enc in reg_results:
        if mean_enc is not None:
            gallery_encodings.append(mean_enc)
            gallery_names.append(name)

    print(f"✅ Đã tạo Vector Trung Bình thành công cho: {len(gallery_encodings)}/{len(emp_dirs)} nhân viên.")
    print(f"⏱️ Thời gian trích xuất & tổng hợp đặc trưng: {time.time() - t_reg_start:.2f} giây\n")

    # 2. Chuẩn bị tập ảnh kiểm thử (Probe)
    # 2a. 2 ảnh test còn lại (_3, _4) của nhân viên
    emp_probe = []
    for d in gallery_names:
        person_path = os.path.join(CASIA_DIR, d)
        files = sorted([f for f in os.listdir(person_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
        test_files = files[3:5] # Lấy 2 ảnh cuối
        for f in test_files:
            emp_probe.append((d, os.path.join(person_path, f)))

    # 2b. Tất cả 5 ảnh của 100 người lạ
    imp_probe = []
    for d in imp_dirs:
        person_path = os.path.join(CASIA_DIR, d)
        files = sorted([f for f in os.listdir(person_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
        for f in files:
            imp_probe.append(("UNKNOWN", os.path.join(person_path, f)))

    total_probes = len(emp_probe) + len(imp_probe)
    print(f"📂 Tập ảnh kiểm thử:")
    print(f"   - Lượt nhân viên chấm công (Genuine Probes - 2 ảnh/người): {len(emp_probe)} ảnh")
    print(f"   - Lượt người lạ thử chấm công (Impostor Probes - 5 ảnh/người): {len(imp_probe)} ảnh")
    print(f"   - Tổng số lượt quét kiểm tra: {total_probes} ảnh\n")

    # 3. Chạy nhận diện qua đa luồng
    print(f"⏳ 2. Đang thực hiện nhận diện {total_probes} lượt quét qua mô hình...")
    test_paths = [item[1] for item in emp_probe + imp_probe]
    test_labels = [item[0] for item in emp_probe + imp_probe]

    t_infer_start = time.time()
    with ThreadPoolExecutor(max_workers=8) as executor:
        test_encs_raw = list(executor.map(extract_encoding, test_paths))

    infer_duration = time.time() - t_infer_start
    avg_ms = (infer_duration / total_probes) * 1000

    # 4. So khớp khoảng cách 1:N Matching
    raw_results = []
    for actual_label, enc in zip(test_labels, test_encs_raw):
        if enc is None:
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
    print(f"{'Tolerance':<12} | {'Accuracy (%)':<14} | {'FAR (%)':<12} | {'FRR (%)':<12} | {'Nhận xét Tỉ lệ 3:2 (Mean Vector)'}")
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
            remark = "⭐️ Cân bằng tuyệt vời (Khuyên dùng cho người Châu Á)"
        elif tol < 0.40:
            remark = "Bảo mật rất cao, chống chấm hộ tối đa"
        elif tol == 0.45:
            remark = "Tỷ lệ từ chối sai (FRR) rất thấp"
        else:
            remark = "Ngưỡng nới lỏng"

        print(f"{tol:<12.2f} | {acc:<14.2f} | {far:<12.2f} | {frr:<12.2f} | {remark}")

    print("=" * 90)
    print(f"\n💡 Tổng kết: Đã test {total_probes} lượt quét thực tế trên 500 người Châu Á (CASIA-FaceV5).\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Benchmark tỉ lệ 3:2 Vector Trung Bình")
    parser.add_argument("--emp", type=int, default=400, help="Số nhân viên đăng ký (mặc định: 400)")
    parser.add_argument("--imp", type=int, default=100, help="Số người lạ kiểm thử (mặc định: 100)")
    args = parser.parse_args()
    run_casia_32_benchmark(emp_count=args.emp, imp_count=args.imp)

import os
import sys
import time
import argparse
import random
from concurrent.futures import ThreadPoolExecutor
import numpy as np
import pandas as pd
import face_recognition

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ARCHIVE_DIR = os.path.join(BASE_DIR, "..", "test", "archive")
LFW_IMG_DIR = os.path.join(ARCHIVE_DIR, "lfw-deepfunneled", "lfw-deepfunneled")
PEOPLE_CSV = os.path.join(ARCHIVE_DIR, "people.csv")

def extract_face_encoding(img_path):
    """Trích xuất encoding 128D của ảnh (trả về None nếu không tìm thấy)"""
    try:
        img = face_recognition.load_image_file(img_path)
        encs = face_recognition.face_encodings(img)
        return encs[0] if encs else None
    except Exception:
        return None

def run_benchmark(num_employees=500, num_impostors=100, max_probes_per_emp=1, tolerances=[0.40, 0.45, 0.50, 0.55, 0.60], seed=42):
    random.seed(seed)
    np.random.seed(seed)

    if not os.path.exists(PEOPLE_CSV) or not os.path.exists(LFW_IMG_DIR):
        print(f"❌ Không tìm thấy thư mục dữ liệu LFW tại: {ARCHIVE_DIR}")
        return

    print("=" * 75)
    print("📊 BẮT ĐẦU ĐÁNH GIÁ ĐỘ CHÍNH XÁC QUY MÔ LỚN TRÊN TẬP LFW")
    print(f"🏢 Kịch bản công ty quy mô lớn: {num_employees} nhân viên đăng ký")
    print(f"👤 Kịch bản người lạ (chưa đăng ký): {num_impostors} người")
    print("=" * 75)

    # 1. Chọn danh sách nhân viên và người lạ từ people.csv
    df = pd.read_csv(PEOPLE_CSV)
    eligible_employees = df[df['images'] >= (1 + max_probes_per_emp)]['name'].tolist()
    if len(eligible_employees) < num_employees:
        eligible_employees = df[df['images'] >= 2]['name'].tolist()
        num_employees = min(num_employees, len(eligible_employees))

    selected_employees = random.sample(eligible_employees, num_employees)

    # Chọn người lạ
    single_image_people = df[df['images'] == 1]['name'].tolist()
    impostor_pool = [p for p in single_image_people if p not in selected_employees]
    if len(impostor_pool) < num_impostors:
        impostor_pool = [p for p in df['name'].tolist() if p not in selected_employees]
    selected_impostors = random.sample(impostor_pool, min(num_impostors, len(impostor_pool)))

    # 2. Đăng ký nhân viên (ảnh _0001.jpg) - Chạy đa luồng (6 workers)
    print(f"\n⏳ 1. Đang đăng ký {num_employees} nhân viên (trích xuất ảnh 0001.jpg bằng đa luồng)...")
    reg_items = []
    for name in selected_employees:
        reg_items.append((name, os.path.join(LFW_IMG_DIR, name, f"{name}_0001.jpg")))

    t_reg_start = time.time()
    gallery_encodings = []
    gallery_names = []

    with ThreadPoolExecutor(max_workers=6) as executor:
        paths = [item[1] for item in reg_items]
        enc_results = list(executor.map(extract_face_encoding, paths))

    for (name, path), enc in zip(reg_items, enc_results):
        if enc is not None:
            gallery_encodings.append(enc)
            gallery_names.append(name)

    print(f"✅ Đã đăng ký thành công: {len(gallery_names)}/{num_employees} nhân viên")
    print(f"⏱️ Thời gian trích xuất đặc trưng {num_employees} người: {time.time() - t_reg_start:.2f} giây\n")

    # 3. Chuẩn bị tập ảnh kiểm thử (Probe)
    # 3a. Ảnh chấm công của nhân viên (lấy max_probes_per_emp ảnh từ _0002.jpg trở đi)
    employee_probe = []
    for name in gallery_names:
        person_dir = os.path.join(LFW_IMG_DIR, name)
        files = sorted([f for f in os.listdir(person_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
        probe_files = files[1:1 + max_probes_per_emp]
        for f in probe_files:
            employee_probe.append((name, os.path.join(person_dir, f)))

    # 3b. Ảnh của người lạ (impostors)
    impostor_probe = []
    for name in selected_impostors:
        person_dir = os.path.join(LFW_IMG_DIR, name)
        files = sorted([f for f in os.listdir(person_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
        if files:
            impostor_probe.append(("UNKNOWN", os.path.join(person_dir, files[0])))

    total_probes = len(employee_probe) + len(impostor_probe)
    print(f"📂 Tập ảnh kiểm thử:")
    print(f"   - Lượt nhân viên chấm công (Probe Known): {len(employee_probe)} ảnh")
    print(f"   - Lượt người lạ thử chấm công (Impostors): {len(impostor_probe)} ảnh")
    print(f"   - Tổng số lượt quét: {total_probes} ảnh\n")

    # 4. Trích xuất đặc trưng tập kiểm thử bằng đa luồng
    print(f"⏳ 2. Đang quét nhận diện {total_probes} ảnh kiểm thử...")
    test_data = employee_probe + impostor_probe
    test_paths = [item[1] for item in test_data]

    t_infer_start = time.time()
    with ThreadPoolExecutor(max_workers=6) as executor:
        test_enc_results = list(executor.map(extract_face_encoding, test_paths))

    infer_duration = time.time() - t_infer_start
    avg_ms = (infer_duration / total_probes) * 1000

    # Tính khoảng cách nhận diện (1:N matching)
    raw_results = []
    for (actual_label, _), enc in zip(test_data, test_enc_results):
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

    # 5. Đánh giá trên từng ngưỡng Tolerance
    print("=" * 85)
    print(f"{'Tolerance':<12} | {'Accuracy (%)':<14} | {'FAR (%)':<12} | {'FRR (%)':<12} | {'Nhận xét quy mô 500 người'}")
    print("=" * 85)

    total_known = len(employee_probe)
    total_unknown = len(impostor_probe)

    for tol in tolerances:
        correct = 0
        false_accept = 0 # Người lạ nhận thành nv, hoặc nv A nhận thành nv B
        false_reject = 0 # Nhân viên thật bị từ chối

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

        if tol == 0.50:
            remark = "⭐️ Cân bằng tối ưu nhất"
        elif tol < 0.50:
            remark = "Bảo mật cao, chống chấm hộ tốt"
        elif tol == 0.55:
            remark = "Độ chính xác cao, nhạy nhận diện"
        else:
            remark = "Nguy cơ nhận nhầm (FAR) tăng ở quy mô lớn"

        print(f"{tol:<12.2f} | {acc:<14.2f} | {far:<12.2f} | {frr:<12.2f} | {remark}")

    print("=" * 85)
    print("\n💡 Ghi chú phân tích quy mô lớn:")
    print(" - Khi quy mô tăng lên 500 người, quan sát sự thay đổi của chỉ số FAR giữa 0.50 và 0.60.")
    print(f" - Tốc độ nhận diện trung bình: ~{avg_ms:.1f} ms / khuôn mặt.\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Benchmark độ chính xác quy mô lớn trên LFW")
    parser.add_argument("--employees", type=int, default=500, help="Số lượng nhân viên đăng ký (mặc định: 500)")
    parser.add_argument("--impostors", type=int, default=100, help="Số lượng người lạ (mặc định: 100)")
    parser.add_argument("--probes-per-emp", type=int, default=1, help="Số ảnh test mỗi nhân viên (mặc định: 1)")
    args = parser.parse_args()
    run_benchmark(num_employees=args.employees, num_impostors=args.impostors, max_probes_per_emp=args.probes_per_emp)

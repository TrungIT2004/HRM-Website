import cv2
import face_recognition
import numpy as np
import datetime
import time
import os
import sys
import json
import csv
import argparse

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
EMBEDDINGS_FILE = os.path.join(BASE_DIR, "embeddings.json")
LOG_FILE = os.path.join(BASE_DIR, "attendance_log.csv")
AUDIO_DIR = os.path.join(BASE_DIR, "audios")

# Khởi tạo âm thanh (tùy chọn)
sound_enabled = False
try:
    import pygame
    pygame.mixer.init()
    sound_enabled = True
except Exception:
    sound_enabled = False

def play_audio(filename):
    if not sound_enabled:
        return
    audio_path = os.path.join(AUDIO_DIR, filename)
    if os.path.exists(audio_path):
        try:
            pygame.mixer.music.load(audio_path)
            pygame.mixer.music.play()
        except Exception:
            pass

def main():
    parser = argparse.ArgumentParser(description="Chấm công nhận diện khuôn mặt Offline")
    parser.add_argument("--tolerance", type=float, default=0.5,
                        help="Ngưỡng so khớp (mặc định: 0.5, càng nhỏ càng khắt khe)")
    args = parser.parse_args()
    tolerance = args.tolerance

    # 1. Tải danh sách nhân viên đã đăng ký
    if not os.path.exists(EMBEDDINGS_FILE):
        print(f"❌ Không tìm thấy file dữ liệu: {EMBEDDINGS_FILE}")
        print("👉 Vui lòng chạy 'python src/register_standalone.py' để đăng ký trước!")
        return

    with open(EMBEDDINGS_FILE, "r", encoding="utf-8") as f:
        database = json.load(f)

    if not database:
        print("❌ Chưa có nhân viên nào trong dữ liệu! Vui lòng đăng ký trước.")
        return

    known_names = list(database.keys())
    known_encodings = [np.array(emb, dtype=np.float64) for emb in database.values()]

    print("=" * 60)
    print("🟢 HỆ THỐNG CHẤM CÔNG OFFLINE (STANDALONE)")
    print(f"👥 Đã nạp {len(known_names)} người: {', '.join(known_names)}")
    print(f"🎯 Ngưỡng nhận diện (Tolerance): {tolerance}")
    print(f"📝 File ghi log chấm công: {LOG_FILE}")
    print("👉 Bấm 'q' để thoát chương trình.")
    print("=" * 60)

    # Khởi tạo file log CSV nếu chưa có
    if not os.path.exists(LOG_FILE):
        with open(LOG_FILE, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(["Timestamp", "Name", "Distance", "Status"])

    # 2. Mở Camera
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("❌ Không thể mở Webcam!")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    COOLDOWN_SECONDS = 5.0
    last_attendance_time = {}
    status_text = "San sang quet..."
    status_color = (255, 255, 255)
    status_until = 0.0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        now_ts = time.time()
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Phát hiện khuôn mặt
        face_locations = face_recognition.face_locations(rgb, model='hog')
        face_encodings = face_recognition.face_encodings(rgb, face_locations)

        for (top, right, bottom, left), face_enc in zip(face_locations, face_encodings):
            # Tính khoảng cách Euclidean
            distances = face_recognition.face_distance(known_encodings, face_enc)
            best_idx = np.argmin(distances)
            min_dist = distances[best_idx]

            if min_dist <= tolerance:
                name = known_names[best_idx]
                box_color = (0, 255, 0)
                label = f"{name} ({min_dist:.2f})"

                # Kiểm tra cooldown để không ghi log liên tục
                last_time = last_attendance_time.get(name, 0.0)
                if now_ts - last_time >= COOLDOWN_SECONDS:
                    last_attendance_time[name] = now_ts
                    now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

                    # Ghi vào CSV
                    with open(LOG_FILE, "a", newline="", encoding="utf-8") as f:
                        writer = csv.writer(f)
                        writer.writerow([now_str, name, f"{min_dist:.4f}", "SUCCESS"])

                    print(f"✅ [{now_str}] {name} CHẤM CÔNG THÀNH CÔNG! (Khoảng cách: {min_dist:.3f})")
                    play_audio("clock_in.mp3")

                    status_text = f"XIN CHAO: {name}!"
                    status_color = (0, 255, 0)
                    status_until = now_ts + 3.0
            else:
                box_color = (0, 0, 255)
                label = f"Nguoi la ({min_dist:.2f})"

            # Vẽ khung và tên
            cv2.rectangle(frame, (left, top), (right, bottom), box_color, 2)
            cv2.putText(frame, label, (left, max(top - 10, 20)),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, box_color, 2)

        # Hiển thị thông báo trạng thái
        if now_ts < status_until:
            cv2.putText(frame, status_text, (20, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, status_color, 2)

        cv2.imshow("Cham Cong - Standalone", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()
    print("🔚 Đã tắt camera chấm công.")

if __name__ == "__main__":
    main()

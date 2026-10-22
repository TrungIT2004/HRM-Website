import cv2
import face_recognition
import os
import sys
import json

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FACES_DIR = os.path.join(BASE_DIR, "registered_faces")
EMBEDDINGS_FILE = os.path.join(BASE_DIR, "embeddings.json")

os.makedirs(FACES_DIR, exist_ok=True)

# Tải dữ liệu đăng ký cũ nếu đã có
database = {}
if os.path.exists(EMBEDDINGS_FILE):
    try:
        with open(EMBEDDINGS_FILE, "r", encoding="utf-8") as f:
            database = json.load(f)
    except Exception as e:
        print(f"⚠️ Không đọc được file dữ liệu cũ: {e}")
        database = {}

print("=" * 60)
print("📸 ĐĂNG KÝ KHUÔN MẶT ĐỘC LẬP (STANDALONE - KHÔNG DÙNG DB / API)")
print(f"📁 Thư mục lưu ảnh: {FACES_DIR}")
print(f"💾 File vector đặc trưng: {EMBEDDINGS_FILE}")
print("👉 Bấm 's' trên cửa sổ camera để chụp ảnh và đăng ký.")
print("👉 Bấm 'q' trên cửa sổ camera để thoát.")
print("=" * 60)

cap = cv2.VideoCapture(0)
if not cap.isOpened():
    print("❌ Không thể mở Webcam!")
    exit(1)

while True:
    ret, frame = cap.read()
    if not ret:
        print("❌ Không nhận được tín hiệu từ Webcam!")
        break

    display_frame = frame.copy()
    cv2.putText(display_frame, "Nhan 's' de chup | 'q' de thoat", (20, 35),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    cv2.imshow("Dang Ky Khuon Mat - Standalone", display_frame)

    key = cv2.waitKey(1) & 0xFF
    if key == ord('q'):
        break
    elif key == ord('s'):
        name = input("\n👉 Nhập tên hoặc mã nhân viên: ").strip()
        if not name:
            print("❌ Tên không được để trống!")
            continue

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        face_locations = face_recognition.face_locations(rgb, model='hog')

        if not face_locations:
            print("❌ Không tìm thấy khuôn mặt trong khung hình! Vui lòng nhìn thẳng vào camera.")
            continue

        encodings = face_recognition.face_encodings(rgb, face_locations)
        if encodings:
            # Lưu ảnh chụp
            face_img_path = os.path.join(FACES_DIR, f"{name}.jpg")
            cv2.imwrite(face_img_path, frame)

            # Lưu vector embedding 128 chiều vào dictionary
            database[name] = encodings[0].tolist()
            with open(EMBEDDINGS_FILE, "w", encoding="utf-8") as f:
                json.dump(database, f, indent=2, ensure_ascii=False)

            print(f"✅ Đăng ký thành công cho: {name}")
            print(f"📁 Ảnh lưu tại: {face_img_path}")
            print(f"💾 Cập nhật dữ liệu vào: {EMBEDDINGS_FILE}")
            print(f"👥 Tổng số người đã đăng ký: {len(database)}\n")

cap.release()
cv2.destroyAllWindows()
print("🔚 Đã đóng chương trình đăng ký.")

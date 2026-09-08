import cv2
import face_recognition
import numpy as np
import os
import psycopg2
from db_config import DB_CONFIG

# Kết nối database
conn = psycopg2.connect(**DB_CONFIG)
cur = conn.cursor()

FACE_DIR = "faces"
os.makedirs(FACE_DIR, exist_ok=True)

def user_exists(user_id):
    cur.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
    return cur.fetchone() is not None

def get_user_by_email(email):
    cur.execute("SELECT user_id, first_name, last_name FROM users WHERE email = %s", (email,))
    return cur.fetchone()

def save_embedding_to_db(user_id, embedding_list):
    # embedding_list là list float (128 chiều)
    cur.execute(
        "UPDATE users SET face_embedding = %s WHERE user_id = %s",
        (embedding_list, user_id)
    )
    conn.commit()

print("📸 Đăng ký khuôn mặt - Nhấn 's' để chụp, 'q' để thoát")
cap = cv2.VideoCapture(0)
if not cap.isOpened():
    print("❌ Không thể mở webcam!")
    exit()

while True:
    ret, frame = cap.read()
    if not ret:
        break
    cv2.putText(frame, "Nhan 's' de chup, 'q' de thoat", (20, 40),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
    cv2.imshow("Dang ky", frame)
    key = cv2.waitKey(1) & 0xFF
    if key == ord('q'):
        break
    elif key == ord('s'):
        identifier = input("Nhập email hoặc user_id: ").strip()
        if not identifier:
            print("❌ Không được để trống!")
            continue

        user_id = None
        fullname = None
        if '@' in identifier:
            row = get_user_by_email(identifier)
            if row:
                user_id = row[0]
                fullname = f"{row[1]} {row[2]}"
            else:
                print(f"❌ Không tìm thấy email {identifier}")
                continue
        else:
            if user_exists(identifier):
                user_id = identifier
                cur.execute("SELECT first_name, last_name FROM users WHERE user_id = %s", (user_id,))
                row = cur.fetchone()
                if row:
                    fullname = f"{row[0]} {row[1]}"
            else:
                print(f"❌ Không tìm thấy user_id {identifier}")
                continue

        # Lưu ảnh (tùy chọn)
        face_path = os.path.join(FACE_DIR, f"{user_id}.jpg")
        cv2.imwrite(face_path, frame)
        print(f"✅ Đã lưu ảnh tại {face_path}")

        # Trích xuất encoding
        try:
            image = face_recognition.load_image_file(face_path)
            encodings = face_recognition.face_encodings(image)
            if not encodings:
                print("❌ Không tìm thấy khuôn mặt trong ảnh!")
                continue
            embedding_list = encodings[0].tolist()  # numpy -> list
            save_embedding_to_db(user_id, embedding_list)
            print(f"✅ Đã lưu embedding cho user {user_id} ({fullname}) vào database")
        except Exception as e:
            print(f"❌ Lỗi: {e}")
            continue

cap.release()
cv2.destroyAllWindows()
cur.close()
conn.close()
print("🔚 Đóng chương trình đăng ký.")
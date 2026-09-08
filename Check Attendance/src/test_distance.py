import cv2
import face_recognition
import numpy as np

# 1. Load ảnh đăng ký
reg_img = face_recognition.load_image_file("faces/45d45cfb-6fcf-44e7-aad5-6b5ab0095d10.jpg")
reg_enc = face_recognition.face_encodings(reg_img)
if not reg_enc:
    print("❌ Không tìm thấy khuôn mặt trong ảnh đăng ký!")
    exit()
reg_enc = reg_enc[0]

# 2. Chụp ảnh từ webcam
cap = cv2.VideoCapture(0)
print("📸 Nhấn phím bất kỳ để chụp ảnh từ webcam...")
while True:
    ret, frame = cap.read()
    if not ret:
        break
    cv2.imshow("Webcam - Nhan phim bat ky de chup", frame)
    if cv2.waitKey(1) != -1:
        break
cap.release()
cv2.destroyAllWindows()

# 3. Trích xuất encoding từ webcam
rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
face_locations = face_recognition.face_locations(rgb, model='hog')
if not face_locations:
    print("❌ Không tìm thấy khuôn mặt trong webcam!")
    exit()

test_enc = face_recognition.face_encodings(rgb, face_locations)[0]

# 4. Tính khoảng cách Euclidean
distance = np.linalg.norm(reg_enc - test_enc)
print(f"📏 Khoảng cách Euclidean: {distance:.4f}")

# 5. So sánh
if distance <= 0.6:
    print("✅ Khoảng cách <= 0.6 → hệ thống sẽ nhận diện được.")
else:
    print(f"❌ Khoảng cách > 0.6 → cần tăng tolerance hoặc chụp lại ảnh đăng ký.")
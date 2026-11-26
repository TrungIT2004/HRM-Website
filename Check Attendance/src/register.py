import cv2
import json
import numpy as np
import os
import sys
import psycopg2
from pathlib import Path
from deepface import DeepFace
from db_config import DB_CONFIG

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

# === PATHS ===
BASE_DIR = Path(__file__).resolve().parent
CASCADES_DIR = BASE_DIR / "cascades"
FACE_DIR = BASE_DIR / "faces"

# === MODEL PATHS ===
YUNET_MODEL_PATH = CASCADES_DIR / "face_detection_yunet_2023mar.onnx"

# === DEEPFACE CONFIG (must match attendance.py) ===
DEEPFACE_MODEL = "ArcFace"          # 512-dim embeddings
DETECTOR_BACKEND = "skip"           # face already detected by YuNet

# === ANTI-SPOOF CROP (matches attendance.py prepare_data pipeline) ===
BBOX_EXPANSION_FACTOR = 1.5

# Kết nối database
conn = psycopg2.connect(**DB_CONFIG)
cur = conn.cursor()

FACE_DIR.mkdir(parents=True, exist_ok=True)

if not YUNET_MODEL_PATH.exists():
    raise FileNotFoundError(f"YuNet model not found at {YUNET_MODEL_PATH}")

_yunet_detector = None


def get_yunet_detector():
    global _yunet_detector
    if _yunet_detector is None:
        print(f"[INFO] Loading YuNet face detector...")
        _yunet_detector = cv2.FaceDetectorYN_create(
            model=str(YUNET_MODEL_PATH),
            config="",
            input_size=(640, 480),
            score_threshold=0.6,
            nms_threshold=0.3,
            top_k=5000,
            backend_id=cv2.dnn.DNN_BACKEND_OPENCV,
            target_id=cv2.dnn.DNN_TARGET_CPU,
        )
        print("[OK] YuNet detector loaded")
    return _yunet_detector


def detect_faces_yunet(frame: np.ndarray):
    """Detect faces using YuNet. Returns list of (top, right, bottom, left)."""
    yunet = get_yunet_detector()
    yunet.setInputSize((frame.shape[1], frame.shape[0]))
    _, faces = yunet.detect(frame)

    if faces is None or len(faces) == 0:
        return []

    face_locations = []
    for face in faces:
        x, y, w, h = face[:4].astype(int)
        left, top = x, y
        right, bottom = x + w, y + h

        left = max(0, left)
        top = max(0, top)
        right = min(frame.shape[1], right)
        bottom = min(frame.shape[0], bottom)

        if right > left and bottom > top:
            face_locations.append((top, right, bottom, left))

    return face_locations


def expand_and_crop_face(frame: np.ndarray, x: int, y: int, w: int, h: int) -> np.ndarray:
    """Expand YuNet bbox by BBOX_EXPANSION_FACTOR and crop with reflect padding (matches attendance.py)."""
    center_x = x + w // 2
    center_y = y + h // 2
    side_len = int(max(w, h) * BBOX_EXPANSION_FACTOR)

    x1 = center_x - side_len // 2
    y1 = center_y - side_len // 2
    x2 = x1 + side_len
    y2 = y1 + side_len

    pad_top = max(0, -y1)
    pad_bottom = max(0, y2 - frame.shape[0])
    pad_left = max(0, -x1)
    pad_right = max(0, x2 - frame.shape[1])

    crop_y1 = max(0, y1)
    crop_y2 = min(frame.shape[0], y2)
    crop_x1 = max(0, x1)
    crop_x2 = min(frame.shape[1], x2)

    face_crop = frame[crop_y1:crop_y2, crop_x1:crop_x2]

    if pad_top or pad_bottom or pad_left or pad_right:
        face_crop = cv2.copyMakeBorder(
            face_crop, pad_top, pad_bottom, pad_left, pad_right,
            cv2.BORDER_REFLECT_101
        )

    return face_crop


def extract_face_embedding(face_crop_bgr: np.ndarray):
    """
    Extract ArcFace 512-dim embedding from face crop using DeepFace.
    Returns L2-normalized numpy array or None on failure.
    """
    try:
        face_rgb = cv2.cvtColor(face_crop_bgr, cv2.COLOR_BGR2RGB)

        embedding_objs = DeepFace.represent(
            img_path=face_rgb,
            model_name=DEEPFACE_MODEL,
            detector_backend=DETECTOR_BACKEND,
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
        print(f"[WARN] Lỗi trích xuất embedding: {e}")
        return None


def user_exists(user_id):
    cur.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
    return cur.fetchone() is not None


def get_user_by_email(email):
    cur.execute(
        "SELECT user_id, first_name, last_name FROM users WHERE email = %s", (email,))
    return cur.fetchone()


def save_embedding_to_db(user_id, embedding_list):
    # embedding_list là list float (512 chiều, ArcFace). Lưu dưới dạng JSON chuỗi
    # để attendance.py đọc lại qua json.loads và L2-normalize trước khi cosine match.
    cur.execute(
        "UPDATE users SET face_embedding = %s WHERE user_id = %s",
        (json.dumps(embedding_list, ensure_ascii=False), user_id)
    )
    conn.commit()


def main():
    print("📸 Đăng ký khuôn mặt - Nhấn 's' để chụp, 'q' để thoát")
    print(f"[INFO] Model nhận diện: {DEEPFACE_MODEL} (512-dim) | Detector: YuNet")

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("❌ Không thể mở webcam!")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

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
                    cur.execute(
                        "SELECT first_name, last_name FROM users WHERE user_id = %s", (user_id,))
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

            # Phát hiện khuôn mặt bằng YuNet và cắt giống pipeline chấm công (attendance.py)
            face_locations = detect_faces_yunet(frame)
            if not face_locations:
                print("❌ Không tìm thấy khuôn mặt trong khung hình!")
                continue

            # Lấy khuôn mặt lớn nhất
            top, right, bottom, left = face_locations[0]
            x, y, w, h = left, top, right - left, bottom - top
            face_crop = expand_and_crop_face(frame, x, y, w, h)
            if face_crop.size == 0:
                print("❌ Không cắt được vùng khuôn mặt!")
                continue

            # Trích xuất embedding 512 chiều (ArcFace)
            embedding = extract_face_embedding(face_crop)
            if embedding is None:
                print("❌ Không trích xuất được embedding từ khuôn mặt!")
                continue

            embedding_list = embedding.tolist()  # numpy -> list
            save_embedding_to_db(user_id, embedding_list)
            print(f"✅ Đã lưu embedding ({len(embedding_list)} chiều) cho user "
                  f"{user_id} ({fullname}) vào database")

    cap.release()
    cv2.destroyAllWindows()
    cur.close()
    conn.close()
    print("🔚 Đóng chương trình đăng ký.")


if __name__ == "__main__":
    main()

import cv2
import numpy as np
import datetime
import time
import os
import json
import pygame
import argparse
import sys
import requests
from pathlib import Path
from deepface import DeepFace

# === PATHS ===
BASE_DIR = Path(__file__).parent
AUDIO_DIR = BASE_DIR / "audios"
CASCADES_DIR = BASE_DIR / "cascades"

# === MODEL PATHS ===
YUNET_MODEL_PATH = CASCADES_DIR / "face_detection_yunet_2023mar.onnx"
ANTI_SPOOF_MODEL_PATH = CASCADES_DIR / "anti_spoof.onnx"  # FP32 model

# === AUDIO CONFIG ===
pygame.mixer.init()

AUDIO_FILES = {
    "clock_in":             AUDIO_DIR / "clock_in.mp3",
    "clock_out":            AUDIO_DIR / "clock_out.mp3",
    "face_not_found":       AUDIO_DIR / "face_not_found.mp3",
    "face_not_registered":  AUDIO_DIR / "face_not_registered.mp3",
    "network_error":        AUDIO_DIR / "network_error.mp3",
    "system_error":         AUDIO_DIR / "system_error.mp3",
    "too_soon":             AUDIO_DIR / "too_soon.mp3",
    "not_working_day":      AUDIO_DIR / "not_working_day.mp3",
    "ot_clock_in":          AUDIO_DIR / "ot_clock_in.mp3",
    "ot_clock_out":         AUDIO_DIR / "ot_clock_out.mp3",
    "no_ot_record":         AUDIO_DIR / "no_ot_record.mp3",
    "insufficient_ot_time": AUDIO_DIR / "insufficient_ot_time.mp3",
    "spoof_detected":       AUDIO_DIR / "spoof_detected.mp3",
}

AUDIO_PADDING_SECONDS = 0.5
_audio_busy_until = 0.0
_audio_windows = {}

# === DEEPFACE CONFIG ===
DEEPFACE_MODEL = "ArcFace"
DEEPFACE_DETECTOR = "yunet"
RECOGNITION_THRESHOLD = 0.27  # Cosine distance threshold for 512-dim ArcFace
ANTI_SPOOFING_ENABLED = True
ANTI_SPOOF_THRESHOLD = 0.55

# === AGGREGATION CONFIG ===
NUM_FRAMES_AGGREGATE = 5
MIN_VALID_FRAMES = 3

# === API CONFIG ===
BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "http://localhost:8080")
ATTENDANCE_API_URL = f"{BACKEND_BASE_URL}/api/attendances"
OVERTIME_API_URL = f"{BACKEND_BASE_URL}/api/overtime"

# === DB CONFIG ===
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": os.getenv("DB_NAME", "hrm"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", ""),
}

# === CACHE ===
_deepface_models = {}
_yunet_detector = None
_anti_spoof_session = None
_anti_spoof_input_name = None

# === UTILS ===
def runtime_clock():
    return cv2.getTickCount() / cv2.getTickFrequency()

def get_audio_window(file_path):
    if file_path not in _audio_windows:
        try:
            _audio_windows[file_path] = pygame.mixer.Sound(str(file_path)).get_length()
        except pygame.error as e:
            print(f"⚠️ Không đọc được thời lượng audio {file_path}: {e}")
            _audio_windows[file_path] = 4.0
    return _audio_windows[file_path] + AUDIO_PADDING_SECONDS

def play_sound(sound_type):
    global _audio_busy_until
    file_path = AUDIO_FILES.get(sound_type)
    if not file_path or not file_path.exists():
        print(f"⚠️ File âm thanh không tồn tại: {sound_type} ({file_path})")
        return False

    try:
        now = runtime_clock()
        if now < _audio_busy_until:
            return False

        audio_window = get_audio_window(file_path)
        sound = pygame.mixer.Sound(str(file_path))
        sound.play()
        _audio_busy_until = now + audio_window
        print(f"🔊 Đã phát âm thanh: {sound_type}")
        return True
    except Exception as e:
        print(f"⚠️ Lỗi phát âm thanh {sound_type}: {e}")
        return False

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

# === DEEPFACE MODEL LOADING ===
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

def get_deepface_models():
    global _deepface_models
    if "recognition" not in _deepface_models:
        print(f"[INFO] Loading DeepFace recognition model: {DEEPFACE_MODEL}")
        _deepface_models["recognition"] = DeepFace.build_model(DEEPFACE_MODEL)
        print(f"[OK] Loaded {DEEPFACE_MODEL}")
    return _deepface_models

# === YUNET DETECTOR ===
def get_yunet_detector():
    global _yunet_detector
    if _yunet_detector is None:
        print(f"[INFO] Loading YuNet face detector...")
        if not YUNET_MODEL_PATH.exists():
            raise FileNotFoundError(f"YuNet model not found at {YUNET_MODEL_PATH}")
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

# === ANTI-SPOOFING (FP32 ONNX) ===
def _load_anti_spoof_model():
    global _anti_spoof_session, _anti_spoof_input_name
    if _anti_spoof_session is None:
        if not ANTI_SPOOF_MODEL_PATH.exists():
            raise FileNotFoundError(f"Anti-spoof model not found at {ANTI_SPOOF_MODEL_PATH}")
        import onnxruntime as ort
        sess_options = ort.SessionOptions()
        sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        _anti_spoof_session = ort.InferenceSession(
            str(ANTI_SPOOF_MODEL_PATH),
            sess_options=sess_options,
            providers=["CPUExecutionProvider"]
        )
        _anti_spoof_input_name = _anti_spoof_session.get_inputs()[0].name
        print(f"[OK] Anti-spoof FP32 model loaded: {_anti_spoof_input_name}")

# BBOX_EXPANSION_FACTOR matches prepare_data.py for anti-spoof training data prep
BBOX_EXPANSION_FACTOR = 1.5

def preprocess_face_for_anti_spoof(face_crop_bgr: np.ndarray) -> np.ndarray:
    """
    Preprocess face crop for FP32 anti-spoof model.
    Matches prepare_data.py training pipeline: direct square resize + reflect padding + normalize [0,1], CHW format.
    NO letterbox - direct square resize like training data preparation.
    """
    face_rgb = cv2.cvtColor(face_crop_bgr, cv2.COLOR_BGR2RGB)
    INPUT_SIZE = 128

    # Direct square resize (matches prepare_data.py - no letterbox)
    # If enlarging: INTER_LANCZOS4, if shrinking: INTER_AREA
    h, w = face_rgb.shape[:2]
    interpolation = cv2.INTER_LANCZOS4 if max(h, w) < INPUT_SIZE else cv2.INTER_AREA
    face_resized = cv2.resize(face_rgb, (INPUT_SIZE, INPUT_SIZE), interpolation=interpolation)

    # Normalize to [0, 1] and convert to CHW
    face_norm = face_resized.transpose(2, 0, 1).astype(np.float32) / 255.0
    blob = np.expand_dims(face_norm, axis=0)
    return blob


def expand_and_crop_face(frame: np.ndarray, x: int, y: int, w: int, h: int) -> np.ndarray:
    """
    Expand YuNet bbox by BBOX_EXPANSION_FACTOR and crop with reflect padding.
    Matches prepare_data.py logic: expand around center, pad with BORDER_REFLECT_101 if needed.
    """
    center_x = x + w // 2
    center_y = y + h // 2
    side_len = int(max(w, h) * BBOX_EXPANSION_FACTOR)

    x1 = center_x - side_len // 2
    y1 = center_y - side_len // 2
    x2 = x1 + side_len
    y2 = y1 + side_len

    # Pad with reflect if crop goes beyond image boundaries
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
            face_crop,
            pad_top, pad_bottom, pad_left, pad_right,
            cv2.BORDER_REFLECT_101
        )

    return face_crop

def check_anti_spoof(face_crop_bgr: np.ndarray) -> dict:
    """
    Run anti-spoofing inference on a face crop using FP32 ONNX model.
    Returns dict with is_real, antispoof_score, real_prob, spoof_prob.
    """
    _load_anti_spoof_model()

    blob = preprocess_face_for_anti_spoof(face_crop_bgr)
    output = _anti_spoof_session.run([], {_anti_spoof_input_name: blob})[0]  # (1, 2)

    logits = output[0]
    # Numerically stable softmax
    max_logit = np.max(logits)
    exp_logits = np.exp(logits - max_logit)
    probs = exp_logits / np.sum(exp_logits)

    # Model outputs [real, spoof] - index 0=real, 1=spoof
    real_prob = float(probs[0])
    spoof_prob = float(probs[1])
    is_real = real_prob > 0.5
    antispoof_score = real_prob

    return {
        "is_real": is_real,
        "antispoof_score": antispoof_score,
        "real_prob": real_prob,
        "spoof_prob": spoof_prob,
    }

# === FACE RECOGNITION (ArcFace 512-dim) ===
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

        # Ensure coordinates within frame
        left = max(0, left)
        top = max(0, top)
        right = min(frame.shape[1], right)
        bottom = min(frame.shape[0], bottom)

        if right > left and bottom > top:
            face_locations.append((top, right, bottom, left))

    return face_locations

def extract_face_embedding(face_crop_bgr: np.ndarray) -> np.ndarray:
    """
    Extract ArcFace 512-dim embedding from face crop using DeepFace.
    Returns L2-normalized embedding or None on failure.
    """
    try:
        face_rgb = cv2.cvtColor(face_crop_bgr, cv2.COLOR_BGR2RGB)
        get_deepface_models()

        embedding_objs = DeepFace.represent(
            img_path=face_rgb,
            model_name=DEEPFACE_MODEL,
            detector_backend="skip",
            enforce_detection=False,
            align=True,
        )

        if not embedding_objs:
            return None

        embedding = np.array(embedding_objs[0]["embedding"], dtype=np.float64)

        # L2 normalize
        norm = np.linalg.norm(embedding)
        if norm > 0:
            embedding = embedding / norm

        return embedding

    except Exception as e:
        print(f"[WARN] Lỗi trích xuất embedding: {e}")
        return None

def aggregate_embeddings(embeddings_list):
    """Aggregate multiple embeddings by averaging, then L2 normalize."""
    if not embeddings_list:
        return None
    stacked = np.stack(embeddings_list, axis=0)
    mean_emb = np.mean(stacked, axis=0)
    norm = np.linalg.norm(mean_emb)
    if norm > 0:
        mean_emb = mean_emb / norm
    return mean_emb

def recognize_face_aggregated(face_embeddings_buffer, employee_embeddings, employee_ids, employee_names):
    """Recognize face using aggregated embedding. Returns (user_id, fullname, error)."""
    if not face_embeddings_buffer:
        return None, None, "face_not_found"

    agg_embedding = aggregate_embeddings(face_embeddings_buffer)
    if agg_embedding is None:
        return None, None, "face_not_found"

    best_idx = -1
    best_similarity = -1.0

    for idx, emp_emb in enumerate(employee_embeddings):
        similarity = np.dot(agg_embedding, emp_emb)
        if similarity > best_similarity:
            best_similarity = similarity
            best_idx = idx

    distance = 1.0 - best_similarity  # cosine distance

    print(f"[INFO] Best match: {employee_names[best_idx] if best_idx >= 0 else 'None'} "
          f"(similarity={best_similarity:.4f}, distance={distance:.4f}, threshold={RECOGNITION_THRESHOLD})")

    if best_idx >= 0 and distance <= RECOGNITION_THRESHOLD:
        return employee_ids[best_idx], employee_names[best_idx], None

    return None, None, "face_not_registered"

def load_employees(cur):
    """Load employees with face embeddings from database."""
    cur.execute("""
        SELECT user_id, first_name, last_name, face_embedding
        FROM users
        WHERE face_embedding IS NOT NULL
    """)
    rows = cur.fetchall()

    employee_ids = []
    employee_names = []
    employee_embeddings = []

    for user_id, first_name, last_name, embedding in rows:
        try:
            if isinstance(embedding, str):
                emb_list = json.loads(embedding)
            elif hasattr(embedding, 'tolist'):
                emb_list = embedding.tolist()
            else:
                emb_list = list(embedding)

            emb_array = np.array(emb_list, dtype=np.float64)
            norm = np.linalg.norm(emb_array)
            if norm > 0:
                emb_array = emb_array / norm

            employee_ids.append(user_id)
            employee_names.append(f"{first_name} {last_name}")
            employee_embeddings.append(emb_array)
        except Exception as e:
            print(f"[ERROR] Lỗi chuyển đổi embedding user {user_id}: {e}")
            continue
    return employee_ids, employee_names, employee_embeddings

# === API FUNCTIONS ===
def mark_regular_attendance(user_id, fullname, now):
    api_url = f"{ATTENDANCE_API_URL}/{user_id}"
    try:
        response = requests.put(api_url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            action = data.get("action")
            time_str = now.strftime('%H:%M:%S')
            if action == "CHECK_IN":
                print(f"[OK] {fullname} chấm công VÀO CA thường lúc {time_str}")
                return "in", None
            elif action == "CHECK_OUT":
                print(f"[OK] {fullname} chấm công TÂN CA thường lúc {time_str}")
                return "out", None
            else:
                return "system_error", None
        else:
            try:
                error_data = response.json()
                return None, error_data.get("errorCode")
            except Exception:
                return None, "SYSTEM_ERROR"
    except requests.exceptions.RequestException as e:
        print(f"[WARN] Lỗi kết nối API Ca thường: {e}")
        return "network_error", None

def mark_overtime_attendance(user_id, fullname, now):
    api_url = f"{OVERTIME_API_URL}/{user_id}"
    try:
        response = requests.put(api_url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            action = data.get("action")
            time_str = now.strftime('%H:%M:%S')
            if action == "CLOCK_IN":
                print(f"[OK] {fullname} chấm công OT VÀO CA lúc {time_str}")
                return "ot_in"
            elif action == "CLOCK_OUT":
                print(f"[OK] {fullname} chấm công OT TÂN CA lúc {time_str}")
                return "ot_out"
            else:
                return "system_error"
        else:
            try:
                error_data = response.json()
                error_code = error_data.get("errorCode")
                if error_code == "RECORD_NOT_FOUND":
                    print(f"[ERROR] {fullname}: Không có lịch OT nào được phê duyệt hôm nay.")
                    return "no_ot_record"
                elif error_code == "INSUFFICIENT_OT_TIME":
                    print(f"[ERROR] {fullname}: Chưa đủ thời gian OT (tối thiểu 1 tiếng).")
                    return "insufficient_ot_time"
                else:
                    print(f"[ERROR] {fullname}: Lỗi OT ({error_code}).")
                    return "system_error"
            except Exception:
                return "system_error"
    except requests.exceptions.RequestException as e:
        print(f"[WARN] Lỗi kết nối API OT: {e}")
        return "network_error"

def mark_attendance(user_id, fullname, now, mode="AUTO"):
    if mode == "OVERTIME":
        return mark_overtime_attendance(user_id, fullname, now)

    status, error_code = mark_regular_attendance(user_id, fullname, now)
    if status is not None:
        return status

    if mode == "AUTO" and error_code in ["NOT_WORK_DAY", "ATTENDANCE_NOT_FOUND"]:
        print(f"[INFO] {fullname}: Không thuộc ca thường ({error_code}). Kiểm tra lịch OT...")
        ot_status = mark_overtime_attendance(user_id, fullname, now)
        if ot_status == "no_ot_record":
            return "not_working_day"
        return ot_status

    if error_code == "NOT_WORK_DAY":
        return "not_working_day"
    elif error_code == "INSUFFICIENT_WORK_TIME":
        return "too_soon"
    else:
        return "system_error"

# === MAIN LOOP ===
def run_attendance():
    _patch_deepface_logger()

    print("[INFO] Khởi tạo DeepFace models...")
    get_deepface_models()
    print("[OK] DeepFace models sẵn sàng")

    # Initialize YuNet
    get_yunet_detector()

    conn = get_db_connection()
    cur = conn.cursor()
    employee_ids, employee_names, employee_embeddings = load_employees(cur)

    if not employee_embeddings:
        print("[WARN] Không có user nào đăng ký khuôn mặt hợp lệ.")
        cur.close()
        conn.close()
        return

    print(f"[OK] Đã tải {len(employee_embeddings)} user đã đăng ký.")
    print(f"[INFO] Model nhận diện: {DEEPFACE_MODEL} (512-dim)")
    print(f"[INFO] Detector: YuNet")
    print(f"[INFO] Anti-spoof: FP32 ONNX ({'ENABLED' if ANTI_SPOOFING_ENABLED else 'DISABLED'})")
    print(f"[INFO] Anti-spoof threshold: {ANTI_SPOOF_THRESHOLD}")
    print(f"[INFO] Frames để tổng hợp: {NUM_FRAMES_AGGREGATE} (tối thiểu {MIN_VALID_FRAMES})")
    print(f"[INFO] Ngưỡng nhận diện (cosine distance): {RECOGNITION_THRESHOLD}")

    cap = cv2.VideoCapture(0)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    MODES = ["AUTO", "REGULAR", "OVERTIME"]
    current_mode_idx = 0

    print("[OK] Hệ thống chấm công đang chạy...")
    print("[INFO] Nhấn 'm' để chuyển đổi chế độ (AUTO / REGULAR / OVERTIME)")
    print("[INFO] Nhấn 'q' để thoát.")

    PROCESS_INTERVAL = 1.0  # Process every 1 second
    STATUS_HOLD_SECONDS = 5.0
    COOLDOWN_SECONDS = 3
    SPOOF_COOLDOWN_SECONDS = 5
    GLOBAL_COOLDOWN_SECONDS = 4

    next_process_time = 0.0
    start_time = runtime_clock()

    last_response_at = {}
    last_response_ui = {}
    last_unrecognized_response_at = 0.0
    last_spoof_response_at = 0.0
    last_global_cooldown = 0.0

    status_text = None
    status_color = (255, 255, 255)
    status_until = 0.0

    face_embeddings_buffer = []
    current_face_bbox = None
    frames_since_detection = 0

    def show_status(text, color):
        nonlocal status_text, status_color, status_until
        status_text = text
        status_color = color
        status_until = runtime_clock() + STATUS_HOLD_SECONDS

    STATUS_UI = {
        "in":                   ("clock_in", "VAO CA THUONG", (0, 255, 0)),
        "out":                  ("clock_out", "TAN CA THUONG", (0, 255, 255)),
        "ot_in":                ("ot_clock_in", "OT VAO CA", (0, 255, 0)),
        "ot_out":               ("ot_clock_out", "OT TAN CA", (0, 255, 255)),
        "no_ot_record":         ("no_ot_record", "KHONG CO LICH OT DUOC DUYET", (0, 0, 255)),
        "insufficient_ot_time": ("insufficient_ot_time", "CHUA DU GIO OT (Toi thieu 1h)", (0, 0, 255)),
        "too_soon":             ("too_soon", "CHUA DU GIO (Can doi >1 tieng)", (0, 0, 255)),
        "not_working_day":      ("not_working_day", "KHONG CO LICH LAM VIEC / OT", (0, 0, 255)),
        "system_error":         ("system_error", "LOI DU LIEU HE THONG", (0, 0, 255)),
        "network_error":        ("network_error", "MAT KET NOI SERVER", (0, 0, 255)),
    }

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        now_ts = runtime_clock()
        due = now_ts >= next_process_time

        # Check global cooldown
        any_cooldown = (
            now_ts - last_global_cooldown < GLOBAL_COOLDOWN_SECONDS or
            now_ts - last_spoof_response_at < SPOOF_COOLDOWN_SECONDS or
            now_ts - last_unrecognized_response_at < COOLDOWN_SECONDS or
            any(now_ts - t < COOLDOWN_SECONDS for t in last_response_at.values())
        )

        if due:
            next_process_time = now_ts + PROCESS_INTERVAL

            if not any_cooldown:
                # Detect faces using YuNet
                face_locations = detect_faces_yunet(frame)
            else:
                face_locations = []
        else:
            face_locations = []

        # Draw face rectangles
        for (top, right, bottom, left) in face_locations:
            cv2.rectangle(frame, (left, top), (right, bottom), (0, 255, 0), 2)

        if due and not any_cooldown and len(face_locations) > 0:
            # Use first (largest) face
            top, right, bottom, left = face_locations[0]
            current_face_bbox = (top, right, bottom, left)
            frames_since_detection = 0

            # Convert to x, y, w, h for expand_and_crop_face
            x, y, w, h = left, top, right - left, bottom - top

            # Anti-spoofing check with expanded crop (matches prepare_data.py)
            if ANTI_SPOOFING_ENABLED:
                face_crop = expand_and_crop_face(frame, x, y, w, h)
                if face_crop.size > 0:
                    spoof_result = check_anti_spoof(face_crop)
                    is_real = spoof_result.get("is_real", True)
                    antispoof_score = spoof_result.get("antispoof_score", 1.0)

                    if not is_real or antispoof_score < ANTI_SPOOF_THRESHOLD:
                        attack_type = "spoof" if not is_real else "low_confidence"
                        print(f"[WARN] Anti-spoofing REJECTED: is_real={is_real}, score={antispoof_score:.3f}")

                        if now_ts - last_spoof_response_at >= SPOOF_COOLDOWN_SECONDS:
                            play_sound("spoof_detected")
                            last_spoof_response_at = now_ts
                            last_global_cooldown = now_ts

                        show_status(f"GIA MAO: {attack_type} (score={antispoof_score:.2f})", (0, 0, 255))
                        face_embeddings_buffer.clear()
                        continue

            # Extract embedding using expanded crop (consistent with anti-spoof)
            embedding = extract_face_embedding(face_crop)

            if embedding is not None:
                face_embeddings_buffer.append(embedding)
                if len(face_embeddings_buffer) > NUM_FRAMES_AGGREGATE:
                    face_embeddings_buffer.pop(0)
                print(f"[INFO] Frame {len(face_embeddings_buffer)}/{NUM_FRAMES_AGGREGATE} captured")

            # Process when enough frames
            if len(face_embeddings_buffer) >= MIN_VALID_FRAMES:
                user_id, fullname, recognition_error = recognize_face_aggregated(
                    face_embeddings_buffer, employee_embeddings, employee_ids, employee_names
                )

                if user_id is not None:
                    last_response = last_response_at.get(user_id, 0.0)
                    if now_ts - last_response >= COOLDOWN_SECONDS:
                        now = datetime.datetime.now()
                        current_mode = MODES[current_mode_idx]
                        status = mark_attendance(user_id, fullname, now, mode=current_mode)

                        sound_key, label, color = STATUS_UI.get(status, (None, "LOI", (0, 0, 255)))
                        if sound_key:
                            play_sound(sound_key)
                            last_global_cooldown = now_ts

                        show_status(f"{fullname} - {label}", color)
                        last_response_at[user_id] = now_ts
                        last_response_ui[user_id] = (label, color)
                        face_embeddings_buffer.clear()
                    else:
                        label, color = last_response_ui.get(user_id, ("DANG XU LY", (255, 255, 255)))
                        show_status(f"{fullname} - {label}", color)
                else:
                    sound_for_error = "face_not_found" if recognition_error == "face_not_found" else "face_not_registered"
                    if now_ts - last_unrecognized_response_at >= COOLDOWN_SECONDS:
                        if play_sound(sound_for_error):
                            last_unrecognized_response_at = now_ts
                            last_global_cooldown = now_ts

                    if recognition_error == "face_not_found":
                        show_status("Khong nhan dien ro khuon mat", (0, 0, 255))
                    else:
                        show_status("Khong nhan dien (chua dang ky)", (0, 0, 255))
                    face_embeddings_buffer.clear()
        else:
            frames_since_detection += 1
            if frames_since_detection > 3:
                face_embeddings_buffer.clear()

        # Display status
        if status_text and runtime_clock() < status_until:
            cv2.putText(frame, status_text, (20, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.55, status_color, 2)

        # Buffer progress
        if face_embeddings_buffer:
            progress_text = f"Frames: {len(face_embeddings_buffer)}/{NUM_FRAMES_AGGREGATE}"
            cv2.putText(frame, progress_text, (20, 70),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 255, 0), 2)

        # Mode display
        mode_str = f"MODE: {MODES[current_mode_idx]} ('m' to change)"
        cv2.putText(frame, mode_str, (10, 460),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 255, 0), 1)

        # Model info
        model_str = f"Model: {DEEPFACE_MODEL} | Detector: YuNet | Anti-spoof: FP32 ONNX"
        cv2.putText(frame, model_str, (10, 440),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.4, (200, 200, 200), 1)

        cv2.imshow("Cham cong", frame)
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('m'):
            current_mode_idx = (current_mode_idx + 1) % len(MODES)
            print(f"[INFO] Đã chuyển chế độ sang: {MODES[current_mode_idx]}")

    cap.release()
    cv2.destroyAllWindows()
    cur.close()
    conn.close()
    print("[INFO] Đóng chương trình.")

def main(test_time=None):
    if test_time:
        try:
            from freezegun import freeze_time
            with freeze_time(test_time):
                run_attendance()
        except ImportError:
            print("[WARN] freezegun chưa được cài đặt. Chạy: pip install freezegun")
            sys.exit(1)
    else:
        run_attendance()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--test-time", help="Set time for testing (YYYY-MM-DD HH:MM:SS)")
    args = parser.parse_args()
    main(args.test_time)
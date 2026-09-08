# # import cv2
# # import face_recognition
# # import numpy as np
# # import datetime
# # import time
# # import psycopg2
# # import os
# # import json
# # import pygame
# # import argparse
# # import sys
# # from db_config import DB_CONFIG

# # # === CẤU HÌNH CHUNG ===
# # STANDARD_WORK_START = datetime.time(8, 0, 0)      # 8:00 AM
# # STANDARD_WORK_END = datetime.time(17, 30, 0)      # 5:30 PM
# # ALLOWED_CLOCK_IN_START = datetime.time(6, 0, 0)   # 6:00 AM
# # ALLOWED_CLOCK_IN_END = datetime.time(15, 30, 0)   # 3:30 PM
# # ALLOWED_CLOCK_OUT_START = datetime.time(10, 0, 0) # 10:00 AM
# # ALLOWED_CLOCK_OUT_END = datetime.time(22, 0, 0)   # 10:00 PM
# # WORKING_DAYS = [0, 1, 2, 3, 4]                   # Thứ 2 -> Thứ 6
# # MIN_WORK_MINUTES = 1

# # pygame.mixer.init()

# # BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# # AUDIO_DIR = os.path.join(BASE_DIR, "audios")

# # AUDIO_FILES = {
# #     "clock_in": os.path.join(AUDIO_DIR, "clock_in.mp3"),
# #     "clock_out": os.path.join(AUDIO_DIR, "clock_out.mp3"),
# #     "face_not_found": os.path.join(AUDIO_DIR, "face_not_found.mp3"),
# #     "face_not_registered": os.path.join(AUDIO_DIR, "face_not_registered.mp3"),
# #     "network_error": os.path.join(AUDIO_DIR, "network_error.mp3"),
# #     "system_error": os.path.join(AUDIO_DIR, "system_error.mp3"),
# #     "too_soon": os.path.join(AUDIO_DIR, "too_soon.mp3"),
# #     "already_done": os.path.join(AUDIO_DIR, "already_done.mp3"),
# #     "not_working_day": os.path.join(AUDIO_DIR, "not_working_day.mp3"),
# #     "invalid_time_in": os.path.join(AUDIO_DIR, "invalid_time_in.mp3"),
# #     "invalid_time_out": os.path.join(AUDIO_DIR, "invalid_time_out.mp3"),
# # }

# # AUDIO_PADDING_SECONDS = 0.5
# # _audio_busy_until = 0.0
# # _audio_windows = {}

# # def runtime_clock():
# #     return cv2.getTickCount() / cv2.getTickFrequency()

# # def get_audio_window(file_path):
# #     if file_path not in _audio_windows:
# #         try:
# #             _audio_windows[file_path] = pygame.mixer.Sound(file_path).get_length()
# #         except pygame.error as e:
# #             print(f"⚠️ Không đọc được thời lượng audio {file_path}: {e}")
# #             _audio_windows[file_path] = 4.0
# #     return _audio_windows[file_path] + AUDIO_PADDING_SECONDS

# # def play_sound(sound_type):
# #     global _audio_busy_until
# #     file_path = AUDIO_FILES.get(sound_type)
# #     if not file_path or not os.path.exists(file_path):
# #         print(f"⚠️ File âm thanh không tồn tại: {sound_type} ({file_path})")
# #         return False

# #     try:
# #         now = runtime_clock()
# #         if now < _audio_busy_until:
# #             return False

# #         audio_window = get_audio_window(file_path)
# #         pygame.mixer.music.stop()
# #         pygame.mixer.music.load(file_path)
# #         pygame.mixer.music.play()
# #         _audio_busy_until = now + audio_window
# #         print(f"🔊 Đã phát âm thanh: {sound_type}")
# #         return True
# #     except Exception as e:
# #         print(f"⚠️ Lỗi phát âm thanh {sound_type}: {e}")
# #         return False

# # def get_db_connection():
# #     return psycopg2.connect(**DB_CONFIG)

# # def load_employees(cur):
# #     cur.execute("""
# #         SELECT user_id, first_name, last_name, face_embedding
# #         FROM users
# #         WHERE face_embedding IS NOT NULL
# #     """)
# #     rows = cur.fetchall()

# #     employee_ids = []
# #     employee_names = []
# #     employee_encodings = []

# #     for user_id, first_name, last_name, embedding in rows:
# #         try:
# #             if isinstance(embedding, str):
# #                 emb_list = json.loads(embedding)
# #             elif hasattr(embedding, 'tolist'):
# #                 emb_list = embedding.tolist()
# #             else:
# #                 emb_list = list(embedding)
# #             emb_array = np.array(emb_list, dtype=np.float64)
# #             employee_ids.append(user_id)
# #             employee_names.append(f"{first_name} {last_name}")
# #             employee_encodings.append(emb_array)
# #         except Exception as e:
# #             print(f"❌ Lỗi chuyển đổi embedding của user {user_id}: {e}")
# #             continue
# #     return employee_ids, employee_names, employee_encodings

# # def recognize_face(rgb_frame, face_location, employee_encodings, employee_ids, employee_names):
# #     try:
# #         encodings = face_recognition.face_encodings(rgb_frame, [face_location])
# #         if not encodings:
# #             return None, None, "face_not_found"
# #         current_emb = encodings[0]
# #         matches = face_recognition.compare_faces(employee_encodings, current_emb, tolerance=0.6)
# #         if True in matches:
# #             idx = matches.index(True)
# #             return employee_ids[idx], employee_names[idx], None
# #         return None, None, "face_not_registered"
# #     except Exception as e:
# #         print(f"⚠️ Lỗi nhận diện: {e}")
# #         return None, None, "face_not_found"

# # def mark_attendance(user_id, fullname, cur, now, conn):
# #     today = now.date()
# #     current_time = now.time()
# #     current_weekday = today.weekday()

# #     if current_weekday not in WORKING_DAYS:
# #         return "not_working_day"

# #     cur.execute("""
# #         SELECT attendance_id, clock_in_time
# #         FROM attendances
# #         WHERE user_id = %s AND date = %s AND clock_out_time IS NULL
# #     """, (user_id, today))
# #     row = cur.fetchone()

# #     if row:
# #         attendance_id, clock_in_time = row
# #         clock_in_dt = datetime.datetime.combine(today, clock_in_time)
# #         diff_minutes = (now - clock_in_dt).total_seconds() / 60

# #         if current_time < ALLOWED_CLOCK_OUT_START or current_time > ALLOWED_CLOCK_OUT_END:
# #             return "invalid_time_out"

# #         if diff_minutes < MIN_WORK_MINUTES:
# #             return "too_soon"

# #         time_str = now.strftime("%H:%M:%S")
# #         clock_out_status = "early_leave" if current_time < STANDARD_WORK_END else "on_time"
# #         cur.execute("""
# #             UPDATE attendances
# #             SET clock_out_time = %s,
# #                 clock_out_status = %s
# #             WHERE attendance_id = %s
# #         """, (time_str, clock_out_status, attendance_id))
# #         conn.commit()
# #         print(f"✅ {fullname} chấm công ra lúc {time_str} (status: {clock_out_status})")
# #         return "out"
# #     else:
# #         if current_time < ALLOWED_CLOCK_IN_START or current_time > ALLOWED_CLOCK_IN_END:
# #             return "invalid_time_in"

# #         cur.execute("""
# #             SELECT 1 FROM attendances
# #             WHERE user_id = %s AND date = %s
# #         """, (user_id, today))
# #         if cur.fetchone():
# #             return "already_done"

# #         clock_in_status = "late" if current_time > STANDARD_WORK_START else "on_time"
# #         time_str = now.strftime("%H:%M:%S")
# #         cur.execute("""
# #             INSERT INTO attendances (attendance_id, user_id, date, clock_in_time, clock_in_status)
# #             VALUES (gen_random_uuid(), %s, %s, %s, %s)
# #         """, (user_id, today, time_str, clock_in_status))
# #         conn.commit()
# #         print(f"✅ {fullname} chấm công vào lúc {time_str} (status: {clock_in_status})")
# #         return "in"

# # def run_attendance():
# #     conn = get_db_connection()
# #     cur = conn.cursor()

# #     employee_ids, employee_names, employee_encodings = load_employees(cur)

# #     if not employee_encodings:
# #         print("⚠️ Không có user nào đăng ký khuôn mặt hợp lệ.")
# #         cur.close()
# #         conn.close()
# #         return

# #     print(f"✅ Đã tải {len(employee_encodings)} user đã đăng ký.")

# #     cap = cv2.VideoCapture(0)
# #     cap.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
# #     cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)

# #     print("🟢 Hệ thống chấm công (in/out tự động) đang chạy... Nhấn 'q' để thoát.")

# #     PROCESS_INTERVAL = 3
# #     STATUS_HOLD_SECONDS = 5.0
# #     COOLDOWN_SECONDS = 3

# #     next_process_time = 0.0
# #     last_user_id = None
# #     last_fullname = None

# #     # Bộ trừ nền để phát hiện "có người/vật trong khung hình" ngay cả khi không thấy rõ
# #     # khuôn mặt (bị che, mờ, tối...). Bổ sung cho face_locations() vì bản thân detector
# #     # khuôn mặt gần như luôn trả về rỗng trong các điều kiện đó - không có cách nào phân
# #     # biệt "không có ai" với "có người nhưng che mặt" nếu chỉ dựa vào face_locations().
# #     bg_subtractor = cv2.createBackgroundSubtractorMOG2(history=500, varThreshold=16, detectShadows=True)
# #     PRESENCE_FOREGROUND_RATIO = 0.03   # tỉ lệ pixel khác nền tối thiểu để coi là có người/vật
# #     BG_WARMUP_SECONDS = 2.0            # bỏ qua tín hiệu vài giây đầu để mô hình nền kịp ổn định
# #     start_time = runtime_clock()

# #     last_response_at = {}
# #     last_response_ui = {}
# #     last_unrecognized_response_at = 0.0

# #     status_text = None
# #     status_color = (255, 255, 255)
# #     status_until = 0.0

# #     def show_status(text, color):
# #         nonlocal status_text, status_color, status_until
# #         status_text = text
# #         status_color = color
# #         status_until = runtime_clock() + STATUS_HOLD_SECONDS

# #     STATUS_UI = {
# #         "in":               ("clock_in", "VAO", (0, 255, 0)),
# #         "out":              ("clock_out", "RA", (0, 255, 255)),
# #         "too_soon":         ("too_soon", "CHUA DU GIO", (0, 0, 255)),
# #         "already_done":     ("already_done", "DA HOAN TAT", (0, 255, 255)),
# #         "not_working_day":  ("not_working_day", "KHONG PHAI NGAY LAM VIEC", (0, 0, 255)),
# #         "invalid_time_in":  ("invalid_time_in", "CHUA DEN GIO CHAM CONG", (0, 0, 255)),
# #         "invalid_time_out": ("invalid_time_out", "KHONG DUOC CHAM CONG RA", (0, 0, 255)),
# #     }

# #     while True:
# #         ret, frame = cap.read()
# #         if not ret:
# #             break

# #         rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
# #         gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
# #         fg_mask = bg_subtractor.apply(gray)   # cập nhật mô hình nền ở MỌI frame, không riêng lúc "due"
# #         now_ts = runtime_clock()
# #         due = now_ts >= next_process_time

# #         if due:
# #             next_process_time = now_ts + PROCESS_INTERVAL
# #             face_locations = face_recognition.face_locations(rgb, model='hog', number_of_times_to_upsample=1)
# #         else:
# #             face_locations = []

# #         for (top, right, bottom, left) in face_locations:
# #             cv2.rectangle(frame, (left, top), (right, bottom), (0, 255, 0), 2)

# #         if due:
# #             if len(face_locations) > 0:
# #                 # CÓ KHUÔN MẶT
# #                 top, right, bottom, left = face_locations[0]
# #                 user_id, fullname, recognition_error = recognize_face(
# #                     rgb, (top, right, bottom, left),
# #                     employee_encodings, employee_ids, employee_names,
# #                 )

# #                 if user_id is not None:
# #                     # Nhận diện thành công
# #                     last_user_id, last_fullname = user_id, fullname

# #                     last_response = last_response_at.get(user_id, 0.0)
# #                     if now_ts - last_response >= COOLDOWN_SECONDS:
# #                         now = datetime.datetime.now()
# #                         status = mark_attendance(user_id, fullname, cur, now, conn)
# #                         sound_key, label, color = STATUS_UI.get(status, (None, "LOI", (0, 0, 255)))
# #                         if sound_key:
# #                             play_sound(sound_key)
# #                         show_status(f"{fullname} - {label}", color)
# #                         last_response_at[user_id] = now_ts
# #                         last_response_ui[user_id] = (label, color)
# #                     else:
# #                         label, color = last_response_ui.get(user_id, ("DANG XU LY", (255, 255, 255)))
# #                         show_status(f"{fullname} - {label}", color)
# #                 else:
# #                     # Có khuôn mặt nhưng chưa xác định được ai:
# #                     #  - recognition_error == "face_not_found": ảnh mờ/tối/bị che (khẩu
# #                     #    trang, kính râm...) -> không lấy được encoding -> phát
# #                     #    face_not_found, và LẶP LẠI mỗi COOLDOWN_SECONDS nếu tình trạng
# #                     #    này còn tiếp diễn.
# #                     #  - recognition_error == "face_not_registered": khuôn mặt rõ nhưng
# #                     #    không khớp ai đã đăng ký -> phát face_not_registered, không
# #                     #    dùng chung face_not_found.
# #                     sound_for_error = "face_not_found" if recognition_error == "face_not_found" else "face_not_registered"
# #                     if now_ts - last_unrecognized_response_at >= COOLDOWN_SECONDS:
# #                         if play_sound(sound_for_error):
# #                             last_unrecognized_response_at = now_ts

# #                     if recognition_error == "face_not_found":
# #                         show_status("Khong nhan dien ro khuon mat", (0, 0, 255))
# #                     else:
# #                         show_status("Khong nhan dien (chua dang ky)", (0, 0, 255))
# #             else:
# #                 warmed_up = (now_ts - start_time) > BG_WARMUP_SECONDS
# #                 foreground_ratio = np.count_nonzero(fg_mask == 255) / fg_mask.size
# #                 person_present = warmed_up and (foreground_ratio > PRESENCE_FOREGROUND_RATIO)

# #                 if person_present:
# #                     # Không bắt được vị trí khuôn mặt nào ở lượt này, NHƯNG bộ trừ nền
# #                     # phát hiện có vật thể/người khác biệt so với nền trong khung hình ->
# #                     # nhiều khả năng vẫn là người đó, chỉ đang che/mờ/tối -> coi là "không
# #                     # rõ", phát face_not_found và lặp lại nếu còn tiếp diễn. Không giới hạn
# #                     # theo thời gian - còn tín hiệu có người là còn nhắc.
# #                     if now_ts - last_unrecognized_response_at >= COOLDOWN_SECONDS:
# #                         if play_sound("face_not_found"):
# #                             last_unrecognized_response_at = now_ts
# #                     show_status("Khong nhan dien ro khuon mat", (0, 0, 255))
# #                 else:
# #                     # Không có tín hiệu người/vật nào khác biệt so với nền -> thực sự
# #                     # không có ai trước camera, không phát âm thanh, chỉ cập nhật chữ.
# #                     show_status("Khong tim thay khuon mat", (0, 0, 255))

# #         if status_text and runtime_clock() < status_until:
# #             cv2.putText(frame, status_text, (20, 50),
# #                         cv2.FONT_HERSHEY_SIMPLEX, 0.6, status_color, 2)

# #         cv2.imshow("Cham cong", frame)
# #         if cv2.waitKey(1) & 0xFF == ord('q'):
# #             break

# #     cap.release()
# #     cv2.destroyAllWindows()
# #     cur.close()
# #     conn.close()
# #     print("🔚 Đóng chương trình.")

# # def main(test_time=None):
# #     if test_time:
# #         try:
# #             from freezegun import freeze_time
# #             with freeze_time(test_time):
# #                 run_attendance()
# #         except ImportError:
# #             print("⚠️ freezegun chưa được cài đặt. Chạy: pip install freezegun")
# #             sys.exit(1)
# #     else:
# #         run_attendance()

# # if __name__ == "__main__":
# #     parser = argparse.ArgumentParser()
# #     parser.add_argument("--test-time", help="Set time for testing (YYYY-MM-DD HH:MM:SS)")
# #     args = parser.parse_args()
# #     main(args.test_time)

# import cv2
# import face_recognition
# import numpy as np
# import datetime
# import time
# import psycopg2
# import os
# import json
# import pygame
# import argparse
# import sys
# import requests
# from db_config import DB_CONFIG

# # === CẤU HÌNH API SPRING BOOT ===
# API_BASE_URL = "http://localhost:8080/api/attendances"

# # === CẤU HÌNH CHUNG ===
# WORKING_DAYS = [0, 1, 2, 3, 4]                   # Thứ 2 -> Thứ 6
# pygame.mixer.init()

# BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# AUDIO_DIR = os.path.join(BASE_DIR, "audios")

# AUDIO_FILES = {
#     "clock_in": os.path.join(AUDIO_DIR, "clock_in.mp3"),
#     "clock_out": os.path.join(AUDIO_DIR, "clock_out.mp3"),
#     "face_not_found": os.path.join(AUDIO_DIR, "face_not_found.mp3"),
#     "face_not_registered": os.path.join(AUDIO_DIR, "face_not_registered.mp3"),
#     "network_error": os.path.join(AUDIO_DIR, "network_error.mp3"),
#     "system_error": os.path.join(AUDIO_DIR, "system_error.mp3"),
#     "too_soon": os.path.join(AUDIO_DIR, "too_soon.mp3"),
#     "not_working_day": os.path.join(AUDIO_DIR, "not_working_day.mp3"),
# }

# AUDIO_PADDING_SECONDS = 0.5
# _audio_busy_until = 0.0
# _audio_windows = {}

# def runtime_clock():
#     return cv2.getTickCount() / cv2.getTickFrequency()

# def get_audio_window(file_path):
#     if file_path not in _audio_windows:
#         try:
#             _audio_windows[file_path] = pygame.mixer.Sound(file_path).get_length()
#         except pygame.error as e:
#             print(f"⚠️ Không đọc được thời lượng audio {file_path}: {e}")
#             _audio_windows[file_path] = 4.0
#     return _audio_windows[file_path] + AUDIO_PADDING_SECONDS

# def play_sound(sound_type):
#     global _audio_busy_until
#     file_path = AUDIO_FILES.get(sound_type)
#     if not file_path or not os.path.exists(file_path):
#         print(f"⚠️ File âm thanh không tồn tại: {sound_type} ({file_path})")
#         return False

#     try:
#         now = runtime_clock()
#         if now < _audio_busy_until:
#             return False

#         audio_window = get_audio_window(file_path)
#         pygame.mixer.music.stop()
#         pygame.mixer.music.load(file_path)
#         pygame.mixer.music.play()
#         _audio_busy_until = now + audio_window
#         print(f"🔊 Đã phát âm thanh: {sound_type}")
#         return True
#     except Exception as e:
#         print(f"⚠️ Lỗi phát âm thanh {sound_type}: {e}")
#         return False

# def get_db_connection():
#     return psycopg2.connect(**DB_CONFIG)

# def load_employees(cur):
#     cur.execute("""
#         SELECT user_id, first_name, last_name, face_embedding
#         FROM users
#         WHERE face_embedding IS NOT NULL
#     """)
#     rows = cur.fetchall()

#     employee_ids = []
#     employee_names = []
#     employee_encodings = []

#     for user_id, first_name, last_name, embedding in rows:
#         try:
#             if isinstance(embedding, str):
#                 emb_list = json.loads(embedding)
#             elif hasattr(embedding, 'tolist'):
#                 emb_list = embedding.tolist()
#             else:
#                 emb_list = list(embedding)
#             emb_array = np.array(emb_list, dtype=np.float64)
#             employee_ids.append(user_id)
#             employee_names.append(f"{first_name} {last_name}")
#             employee_encodings.append(emb_array)
#         except Exception as e:
#             print(f"❌ Lỗi chuyển đổi embedding của user {user_id}: {e}")
#             continue
#     return employee_ids, employee_names, employee_encodings

# def recognize_face(rgb_frame, face_location, employee_encodings, employee_ids, employee_names):
#     try:
#         encodings = face_recognition.face_encodings(rgb_frame, [face_location])
#         if not encodings:
#             return None, None, "face_not_found"
#         current_emb = encodings[0]
#         matches = face_recognition.compare_faces(employee_encodings, current_emb, tolerance=0.6)
#         if True in matches:
#             idx = matches.index(True)
#             return employee_ids[idx], employee_names[idx], None
#         return None, None, "face_not_registered"
#     except Exception as e:
#         print(f"⚠️ Lỗi nhận diện: {e}")
#         return None, None, "face_not_found"

# def mark_attendance(user_id, fullname, now):
#     """
#     Gọi API Spring Boot để xử lý logic Check-in / Check-out
#     """
#     api_url = f"{API_BASE_URL}/{user_id}"
    
#     try:
#         response = requests.put(api_url)
        
#         if response.status_code == 200:
#             data = response.json()
#             action = data.get("action")
#             time_str = now.strftime('%H:%M:%S')
            
#             if action == "CHECK_IN":
#                 print(f"✅ {fullname} chấm công VÀO lúc {time_str}")
#                 return "in"
#             elif action == "CHECK_OUT":
#                 print(f"✅ {fullname} chấm công RA lúc {time_str}")
#                 return "out"
#             else:
#                 return "system_error"
                
#         else:
#             error_data = response.json()
#             error_code = error_data.get("errorCode")
            
#             if error_code == "NOT_WORK_DAY":
#                 print(f"❌ {fullname}: Hôm nay không có lịch làm việc.")
#                 return "not_working_day"
#             elif error_code == "INSUFFICIENT_WORK_TIME":
#                 print(f"❌ {fullname}: Chưa đủ thời gian chờ (1 tiếng).")
#                 return "too_soon"
#             else:
#                 print(f"❌ {fullname}: Lỗi hệ thống ({error_code}).")
#                 return "system_error"
                
#     except requests.exceptions.RequestException as e:
#         print(f"⚠️ Lỗi kết nối API: {e}")
#         return "network_error"

# def run_attendance():
#     conn = get_db_connection()
#     cur = conn.cursor()

#     employee_ids, employee_names, employee_encodings = load_employees(cur)

#     if not employee_encodings:
#         print("⚠️ Không có user nào đăng ký khuôn mặt hợp lệ.")
#         cur.close()
#         conn.close()
#         return

#     print(f"✅ Đã tải {len(employee_encodings)} user đã đăng ký.")

#     cap = cv2.VideoCapture(0)
#     cap.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
#     cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)

#     print("🟢 Hệ thống chấm công đang chạy... Nhấn 'q' để thoát.")

#     PROCESS_INTERVAL = 3
#     STATUS_HOLD_SECONDS = 5.0
#     COOLDOWN_SECONDS = 3

#     next_process_time = 0.0

#     bg_subtractor = cv2.createBackgroundSubtractorMOG2(history=500, varThreshold=16, detectShadows=True)
#     PRESENCE_FOREGROUND_RATIO = 0.03
#     BG_WARMUP_SECONDS = 2.0
#     start_time = runtime_clock()

#     last_response_at = {}
#     last_response_ui = {}
#     last_unrecognized_response_at = 0.0

#     status_text = None
#     status_color = (255, 255, 255)
#     status_until = 0.0

#     def show_status(text, color):
#         nonlocal status_text, status_color, status_until
#         status_text = text
#         status_color = color
#         status_until = runtime_clock() + STATUS_HOLD_SECONDS

#     # Cập nhật Bảng màu và Âm thanh UI dựa trên API Response
#     STATUS_UI = {
#         "in":               ("clock_in", "VAO CA", (0, 255, 0)),
#         "out":              ("clock_out", "TAN CA", (0, 255, 255)),
#         "too_soon":         ("too_soon", "CHUA DU GIO (Can doi >1 tieng)", (0, 0, 255)),
#         "not_working_day":  ("not_working_day", "KHONG PHAI NGAY LAM VIEC", (0, 0, 255)),
#         "system_error":     ("system_error", "LOI DU LIEU HE THONG", (0, 0, 255)),
#         "network_error":    ("network_error", "MAT KET NOI SERVER", (0, 0, 255)),
#     }

#     while True:
#         ret, frame = cap.read()
#         if not ret:
#             break

#         rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
#         gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
#         fg_mask = bg_subtractor.apply(gray)
#         now_ts = runtime_clock()
#         due = now_ts >= next_process_time

#         if due:
#             next_process_time = now_ts + PROCESS_INTERVAL
#             face_locations = face_recognition.face_locations(rgb, model='hog', number_of_times_to_upsample=1)
#         else:
#             face_locations = []

#         for (top, right, bottom, left) in face_locations:
#             cv2.rectangle(frame, (left, top), (right, bottom), (0, 255, 0), 2)

#         if due:
#             if len(face_locations) > 0:
#                 top, right, bottom, left = face_locations[0]
#                 user_id, fullname, recognition_error = recognize_face(
#                     rgb, (top, right, bottom, left),
#                     employee_encodings, employee_ids, employee_names,
#                 )

#                 if user_id is not None:
#                     last_response = last_response_at.get(user_id, 0.0)
                    
#                     if now_ts - last_response >= COOLDOWN_SECONDS:
#                         now = datetime.datetime.now()
                        
#                         # Gọi API để xử lý chấm công
#                         status = mark_attendance(user_id, fullname, now)
                        
#                         sound_key, label, color = STATUS_UI.get(status, (None, "LOI", (0, 0, 255)))
#                         if sound_key:
#                             play_sound(sound_key)
                            
#                         show_status(f"{fullname} - {label}", color)
#                         last_response_at[user_id] = now_ts
#                         last_response_ui[user_id] = (label, color)
#                     else:
#                         label, color = last_response_ui.get(user_id, ("DANG XU LY", (255, 255, 255)))
#                         show_status(f"{fullname} - {label}", color)
#                 else:
#                     sound_for_error = "face_not_found" if recognition_error == "face_not_found" else "face_not_registered"
#                     if now_ts - last_unrecognized_response_at >= COOLDOWN_SECONDS:
#                         if play_sound(sound_for_error):
#                             last_unrecognized_response_at = now_ts

#                     if recognition_error == "face_not_found":
#                         show_status("Khong nhan dien ro khuon mat", (0, 0, 255))
#                     else:
#                         show_status("Khong nhan dien (chua dang ky)", (0, 0, 255))
#             else:
#                 warmed_up = (now_ts - start_time) > BG_WARMUP_SECONDS
#                 foreground_ratio = np.count_nonzero(fg_mask == 255) / fg_mask.size
#                 person_present = warmed_up and (foreground_ratio > PRESENCE_FOREGROUND_RATIO)

#                 if person_present:
#                     if now_ts - last_unrecognized_response_at >= COOLDOWN_SECONDS:
#                         if play_sound("face_not_found"):
#                             last_unrecognized_response_at = now_ts
#                     show_status("Khong nhan dien ro khuon mat", (0, 0, 255))
#                 else:
#                     show_status("Khong tim thay khuon mat", (0, 0, 255))

#         if status_text and runtime_clock() < status_until:
#             cv2.putText(frame, status_text, (20, 50),
#                         cv2.FONT_HERSHEY_SIMPLEX, 0.6, status_color, 2)

#         cv2.imshow("Cham cong", frame)
#         if cv2.waitKey(1) & 0xFF == ord('q'):
#             break

#     cap.release()
#     cv2.destroyAllWindows()
#     cur.close()
#     conn.close()
#     print("🔚 Đóng chương trình.")

# def main(test_time=None):
#     if test_time:
#         try:
#             from freezegun import freeze_time
#             with freeze_time(test_time):
#                 run_attendance()
#         except ImportError:
#             print("⚠️ freezegun chưa được cài đặt. Chạy: pip install freezegun")
#             sys.exit(1)
#     else:
#         run_attendance()

# if __name__ == "__main__":
#     parser = argparse.ArgumentParser()
#     parser.add_argument("--test-time", help="Set time for testing (YYYY-MM-DD HH:MM:SS)")
#     args = parser.parse_args()
#     main(args.test_time)

import cv2
import face_recognition
import numpy as np
import datetime
import time
import psycopg2
import os
import json
import pygame
import argparse
import sys
import requests
from db_config import DB_CONFIG

# === CẤU HÌNH API SPRING BOOT ===
ATTENDANCE_API_URL = "http://localhost:8080/api/attendances"
OVERTIME_API_URL = "http://localhost:8080/api/overtime"

# === CẤU HÌNH AUDIO & THƯ MỤC ===
pygame.mixer.init()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
AUDIO_DIR = os.path.join(BASE_DIR, "audios")

AUDIO_FILES = {
    # Audio Ca thường & Hệ thống
    "clock_in":             os.path.join(AUDIO_DIR, "clock_in.mp3"),
    "clock_out":            os.path.join(AUDIO_DIR, "clock_out.mp3"),
    "face_not_found":       os.path.join(AUDIO_DIR, "face_not_found.mp3"),
    "face_not_registered":  os.path.join(AUDIO_DIR, "face_not_registered.mp3"),
    "network_error":       os.path.join(AUDIO_DIR, "network_error.mp3"),
    "system_error":        os.path.join(AUDIO_DIR, "system_error.mp3"),
    "too_soon":            os.path.join(AUDIO_DIR, "too_soon.mp3"),
    "not_working_day":     os.path.join(AUDIO_DIR, "not_working_day.mp3"),

    # Audio Tăng ca (OT) mới
    "ot_clock_in":          os.path.join(AUDIO_DIR, "ot_clock_in.mp3"),
    "ot_clock_out":         os.path.join(AUDIO_DIR, "ot_clock_out.mp3"),
    "no_ot_record":         os.path.join(AUDIO_DIR, "no_ot_record.mp3"),
    "insufficient_ot_time": os.path.join(AUDIO_DIR, "insufficient_ot_time.mp3"),
}

AUDIO_PADDING_SECONDS = 0.5
_audio_busy_until = 0.0
_audio_windows = {}

def runtime_clock():
    return cv2.getTickCount() / cv2.getTickFrequency()

def get_audio_window(file_path):
    if file_path not in _audio_windows:
        try:
            _audio_windows[file_path] = pygame.mixer.Sound(file_path).get_length()
        except pygame.error as e:
            print(f"⚠️ Không đọc được thời lượng audio {file_path}: {e}")
            _audio_windows[file_path] = 4.0
    return _audio_windows[file_path] + AUDIO_PADDING_SECONDS

def play_sound(sound_type):
    global _audio_busy_until
    file_path = AUDIO_FILES.get(sound_type)
    if not file_path or not os.path.exists(file_path):
        print(f"⚠️ File âm thanh không tồn tại: {sound_type} ({file_path})")
        return False

    try:
        now = runtime_clock()
        if now < _audio_busy_until:
            return False

        audio_window = get_audio_window(file_path)
        pygame.mixer.music.stop()
        pygame.mixer.music.load(file_path)
        pygame.mixer.music.play()
        _audio_busy_until = now + audio_window
        print(f"🔊 Đã phát âm thanh: {sound_type}")
        return True
    except Exception as e:
        print(f"⚠️ Lỗi phát âm thanh {sound_type}: {e}")
        return False

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

def load_employees(cur):
    cur.execute("""
        SELECT user_id, first_name, last_name, face_embedding
        FROM users
        WHERE face_embedding IS NOT NULL
    """)
    rows = cur.fetchall()

    employee_ids = []
    employee_names = []
    employee_encodings = []

    for user_id, first_name, last_name, embedding in rows:
        try:
            if isinstance(embedding, str):
                emb_list = json.loads(embedding)
            elif hasattr(embedding, 'tolist'):
                emb_list = embedding.tolist()
            else:
                emb_list = list(embedding)
            emb_array = np.array(emb_list, dtype=np.float64)
            employee_ids.append(user_id)
            employee_names.append(f"{first_name} {last_name}")
            employee_encodings.append(emb_array)
        except Exception as e:
            print(f"❌ Lỗi chuyển đổi embedding của user {user_id}: {e}")
            continue
    return employee_ids, employee_names, employee_encodings

def recognize_face(rgb_frame, face_location, employee_encodings, employee_ids, employee_names):
    try:
        encodings = face_recognition.face_encodings(rgb_frame, [face_location])
        if not encodings:
            return None, None, "face_not_found"
        current_emb = encodings[0]
        matches = face_recognition.compare_faces(employee_encodings, current_emb, tolerance=0.6)
        if True in matches:
            idx = matches.index(True)
            return employee_ids[idx], employee_names[idx], None
        return None, None, "face_not_registered"
    except Exception as e:
        print(f"⚠️ Lỗi nhận diện: {e}")
        return None, None, "face_not_found"

def mark_regular_attendance(user_id, fullname, now):
    """Gọi API Ca thường"""
    api_url = f"{ATTENDANCE_API_URL}/{user_id}"
    try:
        response = requests.put(api_url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            action = data.get("action")
            time_str = now.strftime('%H:%M:%S')
            if action == "CHECK_IN":
                print(f"✅ {fullname} chấm công VÀO CA thường lúc {time_str}")
                return "in", None
            elif action == "CHECK_OUT":
                print(f"✅ {fullname} chấm công TÂN CA thường lúc {time_str}")
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
        print(f"⚠️ Lỗi kết nối API Ca thường: {e}")
        return "network_error", None

def mark_overtime_attendance(user_id, fullname, now):
    """Gọi API Tăng ca (OT)"""
    api_url = f"{OVERTIME_API_URL}/{user_id}"
    try:
        response = requests.put(api_url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            action = data.get("action")
            time_str = now.strftime('%H:%M:%S')
            if action == "CLOCK_IN":
                print(f"✅ {fullname} chấm công OT VÀO CA lúc {time_str}")
                return "ot_in"
            elif action == "CLOCK_OUT":
                print(f"✅ {fullname} chấm công OT TÂN CA lúc {time_str}")
                return "ot_out"
            else:
                return "system_error"
        else:
            try:
                error_data = response.json()
                error_code = error_data.get("errorCode")
                if error_code == "RECORD_NOT_FOUND":
                    print(f"❌ {fullname}: Không có lịch OT nào được phê duyệt hôm nay.")
                    return "no_ot_record"
                elif error_code == "INSUFFICIENT_OT_TIME":
                    print(f"❌ {fullname}: Chưa đủ thời gian OT (tối thiểu 1 tiếng).")
                    return "insufficient_ot_time"
                else:
                    print(f"❌ {fullname}: Lỗi OT ({error_code}).")
                    return "system_error"
            except Exception:
                return "system_error"
    except requests.exceptions.RequestException as e:
        print(f"⚠️ Lỗi kết nối API OT: {e}")
        return "network_error"

def mark_attendance(user_id, fullname, now, mode="AUTO"):
    """
    Xử lý chấm công thông minh:
    - Mode AUTO: Gọi ca thường ngầm -> Nếu không thuộc ca thường -> Gọi API OT ngầm.
    - Mode REGULAR: Chỉ gọi ca thường.
    - Mode OVERTIME: Chỉ gọi OT.
    """
    if mode == "OVERTIME":
        return mark_overtime_attendance(user_id, fullname, now)

    # 1. Thử gọi API Ca thường
    status, error_code = mark_regular_attendance(user_id, fullname, now)

    if status is not None:
        return status

    # 2. Xử lý khi API Ca thường trả về lỗi (Kiểm tra OT ngầm)
    if mode == "AUTO" and error_code in ["NOT_WORK_DAY", "ATTENDANCE_NOT_FOUND"]:
        print(f"ℹ️ {fullname}: Không thuộc ca thường ({error_code}). Đang kiểm tra lịch Tăng ca (OT)...")
        ot_status = mark_overtime_attendance(user_id, fullname, now)
        if ot_status == "no_ot_record":
            return "not_working_day" # Cả 2 đều không có lịch -> Phát sound not_working_day
        return ot_status

    if error_code == "NOT_WORK_DAY":
        return "not_working_day"
    elif error_code == "INSUFFICIENT_WORK_TIME":
        return "too_soon"
    else:
        return "system_error"

def run_attendance():
    conn = get_db_connection()
    cur = conn.cursor()

    employee_ids, employee_names, employee_encodings = load_employees(cur)

    if not employee_encodings:
        print("⚠️ Không có user nào đăng ký khuôn mặt hợp lệ.")
        cur.close()
        conn.close()
        return

    print(f"✅ Đã tải {len(employee_encodings)} user đã đăng ký.")

    cap = cv2.VideoCapture(0)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)

    MODES = ["AUTO", "REGULAR", "OVERTIME"]
    current_mode_idx = 0

    print("🟢 Hệ thống chấm công đang chạy...")
    print("👉 Nhấn 'm' để chuyển đổi chế độ chấm công (AUTO / REGULAR / OVERTIME)")
    print("👉 Nhấn 'q' để thoát.")

    PROCESS_INTERVAL = 3
    STATUS_HOLD_SECONDS = 5.0
    COOLDOWN_SECONDS = 3

    next_process_time = 0.0

    bg_subtractor = cv2.createBackgroundSubtractorMOG2(history=500, varThreshold=16, detectShadows=True)
    PRESENCE_FOREGROUND_RATIO = 0.03
    BG_WARMUP_SECONDS = 2.0
    start_time = runtime_clock()

    last_response_at = {}
    last_response_ui = {}
    last_unrecognized_response_at = 0.0

    status_text = None
    status_color = (255, 255, 255)
    status_until = 0.0

    def show_status(text, color):
        nonlocal status_text, status_color, status_until
        status_text = text
        status_color = color
        status_until = runtime_clock() + STATUS_HOLD_SECONDS

    # Cập nhật Bảng màu và Âm thanh UI tương ứng với tệp audio thực tế
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

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        fg_mask = bg_subtractor.apply(gray)
        now_ts = runtime_clock()
        due = now_ts >= next_process_time

        if due:
            next_process_time = now_ts + PROCESS_INTERVAL
            face_locations = face_recognition.face_locations(rgb, model='hog', number_of_times_to_upsample=1)
        else:
            face_locations = []

        for (top, right, bottom, left) in face_locations:
            cv2.rectangle(frame, (left, top), (right, bottom), (0, 255, 0), 2)

        if due:
            if len(face_locations) > 0:
                top, right, bottom, left = face_locations[0]
                user_id, fullname, recognition_error = recognize_face(
                    rgb, (top, right, bottom, left),
                    employee_encodings, employee_ids, employee_names,
                )

                if user_id is not None:
                    last_response = last_response_at.get(user_id, 0.0)
                    
                    if now_ts - last_response >= COOLDOWN_SECONDS:
                        now = datetime.datetime.now()
                        current_mode = MODES[current_mode_idx]
                        
                        # Gọi xử lý chấm công
                        status = mark_attendance(user_id, fullname, now, mode=current_mode)
                        
                        sound_key, label, color = STATUS_UI.get(status, (None, "LOI", (0, 0, 255)))
                        if sound_key:
                            play_sound(sound_key)
                            
                        show_status(f"{fullname} - {label}", color)
                        last_response_at[user_id] = now_ts
                        last_response_ui[user_id] = (label, color)
                    else:
                        label, color = last_response_ui.get(user_id, ("DANG XU LY", (255, 255, 255)))
                        show_status(f"{fullname} - {label}", color)
                else:
                    sound_for_error = "face_not_found" if recognition_error == "face_not_found" else "face_not_registered"
                    if now_ts - last_unrecognized_response_at >= COOLDOWN_SECONDS:
                        if play_sound(sound_for_error):
                            last_unrecognized_response_at = now_ts

                    if recognition_error == "face_not_found":
                        show_status("Khong nhan dien ro khuon mat", (0, 0, 255))
                    else:
                        show_status("Khong nhan dien (chua dang ky)", (0, 0, 255))
            else:
                warmed_up = (now_ts - start_time) > BG_WARMUP_SECONDS
                foreground_ratio = np.count_nonzero(fg_mask == 255) / fg_mask.size
                person_present = warmed_up and (foreground_ratio > PRESENCE_FOREGROUND_RATIO)

                if person_present:
                    if now_ts - last_unrecognized_response_at >= COOLDOWN_SECONDS:
                        if play_sound("face_not_found"):
                            last_unrecognized_response_at = now_ts
                    show_status("Khong nhan dien ro khuon mat", (0, 0, 255))
                else:
                    show_status("Khong tim thay khuon mat", (0, 0, 255))

        # Hiển thị trạng thái chấm công
        if status_text and runtime_clock() < status_until:
            cv2.putText(frame, status_text, (20, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.55, status_color, 2)

        # Hiển thị Chế độ (MODE) ở góc dưới
        mode_str = f"MODE: {MODES[current_mode_idx]} ('m' to change)"
        cv2.putText(frame, mode_str, (10, 220),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 255, 0), 1)

        cv2.imshow("Cham cong", frame)
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('m'):
            current_mode_idx = (current_mode_idx + 1) % len(MODES)
            print(f"🔄 Đã chuyển chế độ sang: {MODES[current_mode_idx]}")

    cap.release()
    cv2.destroyAllWindows()
    cur.close()
    conn.close()
    print("🔚 Đóng chương trình.")

def main(test_time=None):
    if test_time:
        try:
            from freezegun import freeze_time
            with freeze_time(test_time):
                run_attendance()
        except ImportError:
            print("⚠️ freezegun chưa được cài đặt. Chạy: pip install freezegun")
            sys.exit(1)
    else:
        run_attendance()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--test-time", help="Set time for testing (YYYY-MM-DD HH:MM:SS)")
    args = parser.parse_args()
    main(args.test_time)

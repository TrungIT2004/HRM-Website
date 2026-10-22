# 📊 BÁO CÁO THỰC NGHIỆM ĐỘ CHÍNH XÁC HỆ THỐNG CHẤM CÔNG (FACE RECOGNITION)

Tài liệu này tổng hợp kết quả kiểm thử thực nghiệm, phân tích số liệu thực tế về độ chính xác của hệ thống nhận diện khuôn mặt phục vụ chấm công, dựa trên tập dữ liệu chuẩn quốc tế **LFW (Labeled Faces in the Wild)**.

---

## 📖 I. Ý NGHĨA CÁC CHỈ SỐ ĐO LƯỜNG (METRICS)

Trong công nghệ nhận diện sinh trắc học và hệ thống chấm công tự động, 3 chỉ số quan trọng nhất để đánh giá chất lượng hệ thống gồm: **Accuracy**, **FAR** và **FRR**.

```
                           KẾT QUẢ QUÉT KHUÔN MẶT
                                    │
         ┌──────────────────────────┴──────────────────────────┐
         ▼                                                     ▼
   QUYẾT ĐỊNH ĐÚNG                                       QUYẾT ĐỊNH SAI
   ├── Nhận đúng nhân viên (True Positive)                ├── Nhận nhầm người khác (False Accept - FAR)
   └── Từ chối đúng người lạ (True Negative)              └── Từ chối nhầm nhân viên (False Reject - FRR)
```

---

### 1. Accuracy (Độ chính xác tổng thể)

* **Ý nghĩa**: Tỷ lệ phần trăm các lần hệ thống đưa ra quyết định đúng (bao gồm cả việc nhận diện đúng nhân viên lẫn việc từ chối đúng người lạ) trên tổng số lượt quét kiểm tra.
* **Ý nghĩa thực tế**: Phản ánh năng lực tổng quan của mô hình trên toàn bộ tập dữ liệu.
* **Công thức toán học**:
  $$\text{Accuracy} = \frac{\text{Số lượt quyết định đúng}}{\text{Tổng số lượt quét kiểm tra}} \times 100\%$$
  $$\text{Accuracy} = \frac{TP + TN}{TP + TN + FP + FN} \times 100\%$$
  * *Trong đó:*
    * $TP$ *(True Positive)*: Nhân viên hợp lệ được nhận diện đúng tên.
    * $TN$ *(True Negative)*: Người lạ được từ chối chính xác (máy báo Unknown).
    * $FP$ *(False Positive)*: Nhận nhầm người lạ thành nhân viên, hoặc nhân viên A bị nhận thành B.
    * $FN$ *(False Negative)*: Nhân viên thật nhưng máy báo không nhận ra.

---

### 2. FAR (False Acceptance Rate - Tỷ lệ nhận nhầm / Chấp nhận sai)

* **Ý nghĩa**: Tỷ lệ phần trăm các trường hợp người lạ (chưa đăng ký) hoặc người khác bị hệ thống nhận vơ thành một nhân viên hợp lệ của công ty.
* **Ý nghĩa trong chấm công**: 
  * Đại diện cho **MỨC ĐỘ BẢO MẬT VÀ NGUY CƠ GIAN LẬN**.
  * FAR cao đồng nghĩa với việc nhân viên rất dễ **chấm công hộ nhau** hoặc **người ngoài đột nhập** mà hệ thống vẫn ghi nhận thành công.
* **Mục tiêu**: **FAR càng thấp càng tốt** (lý tưởng là $0.00\%$).
* **Công thức toán học**:
  $$\text{FAR} = \frac{\text{Số lần nhận nhầm (False Accepts)}}{\text{Tổng số lượt người lạ thử chấm công (Impostor Attempts)}} \times 100\%$$

---

### 3. FRR (False Rejection Rate - Tỷ lệ từ chối sai)

* **Ý nghĩa**: Tỷ lệ phần trăm các trường hợp nhân viên thật của công ty đứng trước camera nhưng hệ thống không nhận diện được (báo "Người lạ" hoặc bắt quét lại).
* **Ý nghĩa trong chấm công**: 
  * Đại diện cho **TRẢI NGHIỆM NGƯỜI DÙNG (UX / Sự tiện lợi)**.
  * FRR cao sẽ gây phiền toái, ùn tắc vào giờ cao điểm đi làm vì nhân viên phải đứng nghiêng qua nghiêng lại nhiều lần máy mới chịu nhận.
* **Mục tiêu**: **FRR càng thấp càng tốt**.
* **Công thức toán học**:
  $$\text{FRR} = \frac{\text{Số lần nhân viên thật bị từ chối (False Rejects)}}{\text{Tổng số lượt nhân viên thật chấm công (Genuine Attempts)}} \times 100\%$$

---

### 4. Mối quan hệ đánh đổi (Trade-off) qua ngưỡng Tolerance

Ngưỡng so khớp khoảng cách Euclidean (**Tolerance**) là tham số quyết định sự đánh đổi giữa FAR và FRR:
* **Hạ Tolerance ($\le 0.45$)**: Siết chặt bảo mật $\rightarrow$ **FAR giảm về 0%** (chống chấm hộ tuyệt đối), nhưng **FRR tăng vọt** (nhân viên khó chấm công).
* **Tăng Tolerance ($\ge 0.60$)**: Nới lỏng nhận diện $\rightarrow$ **FRR giảm** (nhân viên dễ quét), nhưng **FAR tăng cao** (nguy cơ nhận nhầm lớn).
* **Điểm cân bằng tối ưu**: Rơi vào khoảng **`0.50 – 0.55`**.

---

## 🔬 II. MÔI TRƯỜNG & THIẾT LẬP THỰC NGHIỆM

* **Mô hình cốt lõi**: `dlib` ResNet-34 Face Recognition (128-dimensional embedding space).
* **Phát hiện khuôn mặt**: HOG (Histogram of Oriented Gradients).
* **Tập dữ liệu chuẩn**: **LFW (Labeled Faces in the Wild - Deep Funneled)** gồm 5,749 người và 13,233 bức ảnh chân dung.
* **Kịch bản mô phỏng chấm công**:
  * Mỗi nhân viên đăng ký 1 ảnh chân dung gốc (`0001.jpg`) vào cơ sở dữ liệu đặc trưng.
  * Các ảnh độc lập khác (`0002.jpg`, ...) của nhân viên được dùng làm ảnh chấm công đi làm hàng ngày.
  * Nhóm người lạ (hoàn toàn chưa từng đăng ký) được đưa vào để kiểm tra khả năng phòng chống gian lận (FAR).

---

## 📊 III. BẢNG KẾT QUẢ THỰC NGHIỆM CHI TIẾT

### 1. Bảng 1: Quy mô Nhỏ — 10 Nhân viên (20 lượt quét kiểm thử)
* **Quy mô**: 10 nhân viên đăng ký + 10 người lạ kiểm tra.
* **Tốc độ xử lý**: ~345.9 ms / khuôn mặt.

| Ngưỡng (Tolerance) | Độ chính xác (Accuracy) | Tỷ lệ nhận nhầm (FAR) | Tỷ lệ từ chối sai (FRR) | Nhận xét thực tế |
| :---: | :---: | :---: | :---: | :--- |
| **0.40** | 65.00% | **0.00%** | 70.00% | Quá nghiêm ngặt, nhân viên khó quét |
| **0.45** | 80.00% | **0.00%** | 40.00% | Bảo mật cao, chống chấm hộ tuyệt đối |
| **0.50** | **95.00%** | **0.00%** | **10.00%** | Cân bằng tối ưu cho doanh nghiệp nhỏ |
| **0.55** | **100.00%** | **0.00%** | **0.00%** | Tuyệt đối (nhận đúng 100%, 0% nhận nhầm) |
| **0.60** | **100.00%** | **0.00%** | **0.00%** | Nhận diện cực nhạy, không có lỗi |

---

### 2. Bảng 2: Quy mô Vừa — 50 Nhân viên (100 lượt quét kiểm thử)
* **Quy mô**: 50 nhân viên đăng ký + 50 người lạ kiểm tra.
* **Tốc độ xử lý**: ~460.6 ms / khuôn mặt.

| Ngưỡng (Tolerance) | Độ chính xác (Accuracy) | Tỷ lệ nhận nhầm (FAR) | Tỷ lệ từ chối sai (FRR) | Nhận xét thực tế |
| :---: | :---: | :---: | :---: | :--- |
| **0.40** | 63.00% | **0.00%** | 74.00% | Quá nghiêm ngặt, FRR cao |
| **0.45** | 79.00% | **0.00%** | 42.00% | Bảo mật cao, 0% nhận nhầm |
| **0.50** | **92.00%** | **0.00%** | **16.00%** | Rất tốt cho môi trường công sở |
| **0.55** | **97.00%** | **0.00%** | **6.00%** | **Điểm ngọt (Sweet Spot): Độ chính xác đỉnh cao** |
| **0.60** | **89.00%** | **18.00%** | **4.00%** | Bắt đầu lọt 18% người lạ do nới lỏng ngưỡng |

---

### 3. Bảng 3: Quy mô Lớn — 500 (Thực tế 498) Nhân viên (598 lượt quét kiểm thử)
* **Quy mô**: 498 nhân viên đăng ký + 100 người lạ kiểm tra (tổng 598 ảnh test).
* **Tốc độ xử lý**: ~371.4 ms / khuôn mặt.

| Ngưỡng (Tolerance) | Độ chính xác (Accuracy) | Tỷ lệ nhận nhầm (FAR) | Tỷ lệ từ chối sai (FRR) | Nhận xét thực tế |
| :---: | :---: | :---: | :---: | :--- |
| **0.40** | 45.82% | **0.00%** | 65.06% | Quá khắt khe, nhân viên rất khó chấm công |
| **0.45** | 63.38% | **4.00%** | 43.17% | Bảo mật cao, nhận nhầm rất thấp |
| **0.50** | **80.60%** | **9.00%** | **21.49%** | **Ngưỡng khuyến nghị tối ưu cho doanh nghiệp lớn** |
| **0.55** | **87.63%** | **43.00%** | **6.22%** | Độ chính xác cao nhưng nguy cơ chấm hộ tăng |
| **0.60** | **81.44%** | **> 100%** | **0.60%** | **Vỡ trận: Người lạ & nhân viên bị nhận nhầm chéo** |

---

## 💡 IV. PHÂN TÍCH & KẾT LUẬN QUAN TRỌNG

```
        QUY MÔ CÀNG LỚN  ──►  KHÔNG GIAN ĐẶC TRƯNG CÀNG DÀY ĐẶC
                                          │
       ┌──────────────────────────────────┴──────────────────────────────────┐
       ▼                                                                     ▼
Ở quy mô nhỏ (10 - 20 người):                               Ở quy mô lớn (500 người):
Ngưỡng 0.60 hoạt động hoàn hảo (Acc 100%)                   Ngưỡng 0.60 gây nhận nhầm chéo
                                                            BẮT BUỘC siết về Tolerance: 0.50
```

1. **Hiện tượng thay đổi theo quy mô**:
   * Khi quy mô chỉ có **10 người**: Ngưỡng `0.60` đạt hoàn hảo $100\%$ vì khoảng cách giữa các người rất xa nhau.
   * Khi lên **50 người**: Ngưỡng `0.60` bắt đầu lọt $18\%$ nhận nhầm, trong khi `0.55` đạt đỉnh cao nhất ($97\%$).
   * Khi lên **500 người**: Ngưỡng `0.60` bị phá vỡ hoàn toàn (FAR vượt ngưỡng an toàn). Ngưỡng chuẩn mực bắt buộc phải đặt ở **`0.50`**.
2. **Khuyến nghị cấu hình cho hệ thống chấm công**:
   * **Doanh nghiệp vừa và nhỏ (< 50 nhân viên)**: Đặt Tolerance = **`0.55`** (vừa nhạy vừa không lo nhận nhầm).
   * **Doanh nghiệp lớn ($\ge 100$ nhân viên)**: Đặt Tolerance = **`0.50`** (ưu tiên an toàn chống chấm hộ).

---

## 🚀 V. HƯỚNG DẪN CHẠY SCRIPT TRONG DỰ ÁN

### 1. Chạy hệ thống chấm công độc lập (Offline - Không cần Spring Boot / DB):
```powershell
# 1. Đăng ký nhân viên qua webcam:
.\venv\Scripts\python src/register_standalone.py

# 2. Chạy camera quét chấm công (ngưỡng mặc định 0.5):
.\venv\Scripts\python src/attendance_standalone.py

# Hoặc tùy chỉnh ngưỡng tolerance tùy ý (ví dụ 0.55):
.\venv\Scripts\python src/attendance_standalone.py --tolerance 0.55
```

### 2. Tự chạy lại Benchmark đo lường trên tập LFW:
```powershell
# Test quy mô 10 người:
.\venv\Scripts\python src/evaluate_lfw.py --employees 10 --impostors 10

# Test quy mô 50 người:
.\venv\Scripts\python src/evaluate_lfw.py --employees 50 --impostors 50

# Test quy mô 500 người:
.\venv\Scripts\python src/evaluate_lfw.py --employees 500 --impostors 100
```

# HRM Backend – Tài liệu API Endpoint

> **Spring Boot · Java 17 · Spring Security (JWT + Cookie) · Spring Data JPA**

---

## Quy ước chung

| Ký hiệu | Ý nghĩa |
|---|---|
| 🔓 Public | Không cần xác thực |
| 🔒 Authenticated | Bất kỳ user đã đăng nhập |
| 🟡 HR | Chỉ nhân viên phòng **Human Resources** |
| 🟠 HR Head | Trưởng phòng HR (`job` chứa `"Head"` & `department = "Human Resources"`) |
| 🔵 Manager | Trưởng phòng bất kỳ (`job` bắt đầu bằng `"Department Head"`) |
| 🔴 Executive | Phòng **Executive Leadership** (Ban Giám Đốc) |
| 💰 Accounting | Phòng `Accounting / Finance / Kế toán / Tài chính` hoặc job chứa `accountant` |
| 💰💰 Chief Accountant | Kế toán trưởng (`job` chứa `head/manager/lead` & phòng Kế toán/Tài chính) |

> **Lưu ý authentication:** Tất cả các endpoint bên dưới (trừ nhóm `/auth` được đánh dấu 🔓) đều yêu cầu `Bearer <accessToken>` trong header `Authorization`. Token được cấp khi đăng nhập thành công.

---

## 1. Authentication – `/auth`

### `POST /auth/register` 🔓
Tạo tài khoản người dùng mới.

| | |
|---|---|
| **Request Body** | `SignUpRequest` (`email`, `password`, `firstName`, `lastName`) |
| **Response** | `{ "message": "User created" }` · HTTP 201 |
| **Quyền truy cập** | Công khai (không cần đăng nhập) |

---

### `POST /auth/login` 🔓
Đăng nhập, nhận Access Token + Refresh Token (cookie httpOnly).

| | |
|---|---|
| **Request Body** | `SignInRequest` (`email`, `password`) |
| **Cookie đọc** | `deviceId` (UUID – tự tạo nếu chưa có) |
| **Response Body** | `SignInResponse` |
| **Response Cookie** | `refreshToken` (7 ngày) · `deviceId` (1 năm) |
| **Quyền truy cập** | Công khai |

**`SignInResponse`** – các trường trả về:

| Trường | Kiểu | Mô tả |
|---|---|---|
| `accessToken` | `String` | JWT ngắn hạn dùng để gọi API |
| `userId` | `UUID` | ID của người dùng |
| `email` | `String` | Email đăng nhập |
| `fullName` | `String` | Họ và tên |
| `profilePicUrl` | `String` | URL ảnh đại diện |
| `department` | `String` | Tên phòng ban |
| `job` | `String` | Chức danh |

---

### `POST /auth/auto-login` 🔓
Tự động đăng nhập lại bằng `refreshToken` cookie (dành cho F5/reload trang).

| | |
|---|---|
| **Cookie đọc** | `refreshToken`, `deviceId` |
| **Response Body** | `SignInResponse` (như trên) |
| **Response Cookie** | `refreshToken` mới (7 ngày) |
| **Quyền truy cập** | Công khai (nhưng cần cookie hợp lệ) |

---

### `POST /auth/logout` 🔒
Đăng xuất, thu hồi refresh token.

| | |
|---|---|
| **Cookie đọc** | `refreshToken` |
| **Response** | `{ "message": "Logged out successfully" }` · HTTP 200 |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

### `PUT /auth/change-password` 🔒
Đổi mật khẩu tài khoản đang đăng nhập.

| | |
|---|---|
| **Request Body** | `ChangePasswordRequest` (`oldPassword`, `newPassword`) |
| **Response** | `{ "message": "Đổi mật khẩu thành công" }` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

## 2. Nhân viên – `/api/employees`

### `GET /api/employees` 🔒
Lấy danh sách danh bạ nhân viên (tìm kiếm đa năng, lọc theo phòng ban, phân trang).

| | |
|---|---|
| **Query Params** | `keyword` (tên/mã NV), `department` (tên phòng ban), `page`, `size`, `sort` |
| **Response** | `Page<EmployeeDirectoryItemResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`EmployeeDirectoryItemResponse`**:

| Trường | Kiểu |
|---|---|
| `userId` | `UUID` |
| `employeeCode` | `String` |
| `fullName` | `String` |
| `profilePicUrl` | `String` |
| `departmentName` | `String` |
| `jobTitle` | `String` |
| `isActive` | `boolean` |

---

### `GET /api/employees/{userId}/public-profile` 🔒
Xem hồ sơ công khai của một nhân viên (dùng cho trang danh bạ / trang cá nhân).

| | |
|---|---|
| **Path Param** | `userId` (UUID) |
| **Response** | `EmployeePublicProfile` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`EmployeePublicProfile`**:

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `userId` | `UUID` | |
| `employeeCode` | `String` | |
| `firstName`, `lastName`, `fullName` | `String` | |
| `profilePicUrl` | `String` | |
| `gender` | `String` | |
| `birthDate` | `LocalDate` | |
| `joinedDate` | `LocalDate` | |
| `jobTitle` | `String` | |
| `departmentName` | `String` | |
| `workEmail` | `String` | |
| `phoneNumber` | `String` | |
| `todayStatus` | `String` | Trạng thái chấm công hôm nay |
| `shiftName` | `String` | Tên ca làm việc |
| `weeklySchedule` | `List<WorkShiftScheduleDto>` | Lịch làm việc 7 ngày |
| `isActive` | `boolean` | Tài khoản đang hoạt động? |

---

### `GET /api/employees/{userId}/detailed` 🔒
Xem hồ sơ chi tiết đầy đủ của một nhân viên. **Tự động phân quyền theo vai trò:**

| | |
|---|---|
| **Path Param** | `userId` (UUID) |
| **Response** | `EmployeeDetailResponse` |
| **Quyền truy cập** | Tất cả user đã đăng nhập (nội dung trả về khác nhau theo vai trò) |

**`EmployeeDetailResponse`** – Cấu trúc phân quyền:

| Tab | Trường | Ai xem được |
|---|---|---|
| Hồ sơ công khai | `publicProfile` (`EmployeePublicProfile`) | Tất cả |
| Tab 1 – Pháp lý | `legalProfile` (`LegalProfileDto`) | Chính mình + 🟡 HR + 🔴 Executive |
| Tab 2 – Hợp đồng | `contract` (`ContractDto`) | Chính mình + 🔵 Trưởng phòng cùng team + 🟡 HR + 🔴 Executive |
| Tab 3 – Lương & Ngân hàng | `payroll` (`PayrollDto`) | Chính mình + 🟡 HR + 🔴 Executive |

> Nếu không có quyền, trường đó trả về `null`.

---

### `GET /api/employees/me/detailed` 🔒
Xem hồ sơ chi tiết đầy đủ của chính người đang đăng nhập.

| | |
|---|---|
| **Response** | `EmployeeDetailResponse` (như trên, luôn trả đầy đủ dữ liệu của bản thân) |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

### `PUT /api/employees/{userId}/basic-info` 🟡 HR
Cập nhật thông tin cơ bản (họ tên, giới tính, ngày sinh, ảnh đại diện, số điện thoại).

| | |
|---|---|
| **Request Body** | `UpdateBasicInfoRequest` |
| **Response** | `EmployeeDetailResponse` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `PUT /api/employees/{userId}/legal-profile` 🟡 HR
Cập nhật hồ sơ pháp lý & nhân thân (CCCD, MST, BHXH, địa chỉ, liên hệ khẩn cấp...).

| | |
|---|---|
| **Request Body** | `UpdateLegalProfileRequest` |
| **Response** | `EmployeeDetailResponse` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `PUT /api/employees/{userId}/profile` 🟡 HR
Cập nhật thông tin cơ bản & pháp lý gộp chung (endpoint tương thích ngược).

| | |
|---|---|
| **Request Body** | `UpdateProfileRequest` |
| **Response** | `EmployeeDetailResponse` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `PUT /api/employees/{userId}/contract` 🟡 HR
Cập nhật / tái ký hợp đồng lao động.

| | |
|---|---|
| **Request Body** | `UpdateContractRequest` (loại hợp đồng, ngày bắt đầu, ngày kết thúc) |
| **Response** | `EmployeeDetailResponse` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `PUT /api/employees/{userId}/payroll` 🟡 HR
Điều chỉnh lương & tài khoản ngân hàng của nhân viên.

| | |
|---|---|
| **Request Body** | `UpdatePayrollRequest` (lương cơ sở, tần suất, số ngày công, ngân hàng...) |
| **Response** | `EmployeeDetailResponse` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `PUT /api/employees/{userId}/assignment` 🟡 HR
Điều chuyển công tác (phòng ban, chức vụ, ca làm việc).

| | |
|---|---|
| **Request Body** | `UpdateAssignmentRequest` (`departmentId`, `jobId`, `shiftId`) |
| **Response** | `EmployeeDetailResponse` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `POST /api/employees` 🟡 HR
Tạo nhân viên mới trọn gói (tạo user + hồ sơ + hợp đồng + lương trong một request).

| | |
|---|---|
| **Request Body** | `CreateEmployeeRequest` |
| **Response** | `EmployeeDetailResponse` · HTTP 201 |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `PATCH /api/employees/{userId}/status` 🟡 HR
Khóa hoặc mở khóa tài khoản nhân viên (khi thôi việc). Khi khóa → thu hồi toàn bộ session ngay lập tức.

| | |
|---|---|
| **Request Body** | `UpdateEmployeeStatusRequest` (`isActive`: boolean, `reason`: String) |
| **Response** | `EmployeeDetailResponse` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `POST /api/employees/me/avatar` 🔒
Nhân viên tự upload / cập nhật ảnh đại diện của chính mình.

| | |
|---|---|
| **Request** | `multipart/form-data` · field `file` (ảnh) |
| **Response** | `AvatarUploadResponse` (`profilePicUrl`, `message`) |
| **Quyền truy cập** | Tất cả user đã đăng nhập (chỉ được đổi của chính mình) |

---

### `POST /api/employees/{userId}/avatar` 🟡 HR / 🔴 Executive
Upload ảnh đại diện cho nhân viên bất kỳ.

| | |
|---|---|
| **Request** | `multipart/form-data` · field `file` (ảnh) |
| **Response** | `AvatarUploadResponse` (`profilePicUrl`, `message`) |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Executive |

---

## 3. Phòng ban – `/api/departments`

### `GET /api/departments` 🔒
Lấy danh sách toàn bộ phòng ban kèm cơ cấu chức danh và số lượng nhân sự.

| | |
|---|---|
| **Response** | `List<DepartmentResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`DepartmentResponse`**:

| Trường | Kiểu |
|---|---|
| `departmentId` | `UUID` |
| `name` | `String` |
| `totalEmployees` | `int` |
| `jobs` | `List<JobItemDto>` (`jobId`, `title`) |

---

### `POST /api/departments` 🟠 HR Head / 🔴 Executive
Tạo phòng ban mới.

| | |
|---|---|
| **Request Body** | `CreateDepartmentRequest` (`name`) |
| **Response** | `DepartmentResponse` · HTTP 201 |
| **Quyền truy cập** | 🟠 Trưởng phòng HR (`job` chứa `"Head"`) hoặc 🔴 Ban Giám Đốc |

---

## 4. Chức vụ – `/api/jobs`

### `GET /api/jobs` 🔒
Lấy danh sách chức danh/vị trí công việc (có thể lọc theo phòng ban).

| | |
|---|---|
| **Query Params** | `departmentId` (UUID – tuỳ chọn) |
| **Response** | `List<JobResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`JobResponse`**:

| Trường | Kiểu |
|---|---|
| `jobId` | `UUID` |
| `title` | `String` |
| `departmentId` | `UUID` |
| `departmentName` | `String` |

---

### `POST /api/jobs` 🟠 HR Head / 🔴 Executive
Tạo chức vụ mới thuộc phòng ban.

| | |
|---|---|
| **Request Body** | `CreateJobRequest` (`title`, `departmentId`) |
| **Response** | `JobResponse` · HTTP 201 |
| **Quyền truy cập** | 🟠 Trưởng phòng HR hoặc 🔴 Ban Giám Đốc |

---

## 5. Ca làm việc – `/api/work-shifts`

### `GET /api/work-shifts` 🔒
Lấy toàn bộ danh sách ca làm việc cùng lịch 7 ngày trong tuần (dùng cho dropdown chọn ca & hiển thị lịch).

| | |
|---|---|
| **Response** | `List<WorkShiftResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`WorkShiftResponse`**:

| Trường | Kiểu |
|---|---|
| `shiftId` | `UUID` |
| `name` | `String` |
| `schedules` | `List<WorkShiftScheduleItemDto>` |

**`WorkShiftScheduleItemDto`**: `scheduleId`, `dayOfWeek`, `dayName`, `isWorking`, `startTime`, `endTime`, `restStartTime`, `restEndTime`

---

### `POST /api/work-shifts` 🟠 HR Head / 🔴 Executive
Tạo ca làm việc mới kèm lịch trình 7 ngày. Kiểm tra giới hạn lao động: ≤ 8h/ngày, ≤ 48h/tuần.

| | |
|---|---|
| **Request Body** | `CreateWorkShiftRequest` (`name`, `schedules[]`) |
| **Response** | `WorkShiftResponse` · HTTP 201 |
| **Quyền truy cập** | 🟠 Trưởng phòng HR hoặc 🔴 Ban Giám Đốc |

---

## 6. Chấm công – `/api/attendances`

### `GET /api/attendances/my-attendances` 🔒
Xem lịch sử chấm công cá nhân của người đang đăng nhập.

| | |
|---|---|
| **Query Params** | `AttendanceFilterRequest` (`fromDate`, `toDate`, `status`…) + phân trang |
| **Response** | `Page<StaffAttendanceResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`StaffAttendanceResponse`**:

| Trường | Kiểu |
|---|---|
| `workDate` | `LocalDate` |
| `clockInTime` | `LocalTime` |
| `clockOutTime` | `LocalTime` |
| `status` | `AttendanceStatus` (SUFFICIENT, LATE, EARLY, LATE_AND_EARLY, MISSING, UNEXCUSED_ABSENCE, PAID_LEAVE, UNPAID_LEAVE, BUSINESS_TRIP, ADJUSTED, WORKING) |
| `isEdited` | `boolean` |
| `editedReason` | `String` |

---

### `GET /api/attendances/department` 🔵 Manager / 🔴 Executive
Trưởng phòng / Ban Giám Đốc xem chấm công nhân viên cấp dưới.

| | |
|---|---|
| **Query Params** | `AttendanceFilterRequest` + phân trang |
| **Response** | `Page<ManagerAttendanceResponse>` |
| **Quyền truy cập** | 🔵 Trưởng phòng (`job` bắt đầu bằng `"Department Head"`) hoặc 🔴 Ban Giám Đốc |

**`ManagerAttendanceResponse`** (bổ sung thêm so với Staff):

| Trường | Kiểu |
|---|---|
| `employeeCode` | `String` |
| `fullName` | `String` |
| `job` | `String` |
| + Các trường của `StaffAttendanceResponse` | |

---

### `GET /api/attendances/company` 🟡 HR
Xem chấm công toàn bộ công ty.

| | |
|---|---|
| **Query Params** | `AttendanceFilterRequest` + phân trang |
| **Response** | `Page<HrAttendanceResponse>` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

**`HrAttendanceResponse`** (đầy đủ nhất):

| Trường | Kiểu |
|---|---|
| `attendanceId` | `UUID` |
| `userId` | `UUID` |
| `employeeCode` | `String` |
| `fullName` | `String` |
| `department` | `String` |
| `job` | `String` |
| `workDate` | `LocalDate` |
| `clockInTime` | `LocalTime` |
| `clockOutTime` | `LocalTime` |
| `status` | `AttendanceStatus` |
| `isEdited` | `boolean` |
| `editedReason` | `String` |
| `editorName` | `String` |
| `editorEmpCode` | `String` |

---

### `PUT /api/attendances/{userId}` 🔒
Chấm công (clock in / clock out) cho user theo `userId`. Tự động xác định lượt vào hay ra.

| | |
|---|---|
| **Path Param** | `userId` (UUID) |
| **Response** | `{ "action": "CHECK_IN" / "CHECK_OUT", "msg": "..." }` |
| **Quyền truy cập** | Tất cả user đã đăng nhập (thường gọi bởi thiết bị chấm công) |

---

### `PUT /api/attendances/edit/{attendanceId}` 🟡 HR / 🔴 Executive
Chỉnh sửa bản ghi chấm công (chỉ khi tháng đó chưa bị **LOCKED**).

| | |
|---|---|
| **Path Param** | `attendanceId` (UUID) |
| **Request Body** | `EditAttendanceRequest` (`editedClockInTime`, `editedClockOutTime`, `editedStatus`, `editedReason`) |
| **Response** | `{ "msg": "...", "attendanceId": UUID, "status": AttendanceStatus }` |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Ban Giám Đốc |

---

### `DELETE /api/attendances/{attendanceId}` 🟡 HR / 🔴 Executive
Xóa bản ghi chấm công (chỉ khi tháng đó chưa bị **LOCKED**).

| | |
|---|---|
| **Response** | `"Attendance Record deleted"` |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Ban Giám Đốc |

---

### `GET /api/attendances/export` 🟡 HR
Xuất báo cáo chấm công toàn công ty ra file Excel (`.xlsx`).

| | |
|---|---|
| **Query Params** | `AttendanceFilterRequest` |
| **Response** | `byte[]` · `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `GET /api/attendances/summary/me` 🔒
Nhân viên xem bảng công tháng của chính mình.

| | |
|---|---|
| **Query Params** | `StaffTimesheetFilterRequest` (`month`, `year`) + phân trang |
| **Response** | `Page<StaffMonthlyTimesheetResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`StaffMonthlyTimesheetResponse`**:

| Trường | Kiểu |
|---|---|
| `periodMonth`, `periodYear` | `int` |
| `standardWorkingDays` | `int` |
| `actualWorkedDays` | `BigDecimal` |
| `actualWorkHours` | `BigDecimal` |
| `lateCount` | `int` |
| `totalLateMinutes` | `int` |
| `earlyDepartureCount` | `int` |
| `absentDays` | `BigDecimal` |
| `paidLeaveDays` | `BigDecimal` |
| `unpaidLeaveDays` | `BigDecimal` |
| `totalActualOtHours` | `BigDecimal` |
| `totalPaidOtHours` | `BigDecimal` |
| `otDetails` | `List<OvertimeDetailDto>` (type, label, multiplier, hours, paidHours) |
| `status` | `TimesheetStatus` (DRAFT / LOCKED) |

---

### `GET /api/attendances/summary/me/export` 🔒
Xuất Excel bảng công tháng cá nhân.

| | |
|---|---|
| **Response** | `byte[]` Excel |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

### `GET /api/attendances/summary/department` 🔵 Manager / 🔴 Executive
Trưởng phòng xem bảng công tháng của nhân viên trong phòng ban (loại trừ chính mình).

| | |
|---|---|
| **Query Params** | `ManagerTimesheetFilterRequest` + phân trang |
| **Response** | `Page<CompanyMonthlyTimesheetResponse>` |
| **Quyền truy cập** | 🔵 Trưởng phòng bất kỳ hoặc 🔴 Ban Giám Đốc |

**`CompanyMonthlyTimesheetResponse`** (bổ sung thêm so với Staff):

| Trường | Kiểu |
|---|---|
| `userId` | `UUID` |
| `employeeCode` | `String` |
| `fullName` | `String` |
| `department` | `String` |
| `job` | `String` |
| + Tất cả trường của `StaffMonthlyTimesheetResponse` | |

---

### `GET /api/attendances/summary/department/export` 🔵 Manager / 🔴 Executive
Xuất Excel bảng công phòng ban.

| | |
|---|---|
| **Response** | `byte[]` Excel |
| **Quyền truy cập** | 🔵 Trưởng phòng hoặc 🔴 Ban Giám Đốc |

---

### `GET /api/attendances/summary/company` 🟡 HR / 🔴 Executive
HR / Ban Giám Đốc xem bảng công tháng toàn công ty (loại trừ chính mình).

| | |
|---|---|
| **Query Params** | `CompanyTimesheetFilterRequest` + phân trang |
| **Response** | `Page<CompanyMonthlyTimesheetResponse>` |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Ban Giám Đốc |

---

### `GET /api/attendances/summary/company/export` 🟡 HR / 🔴 Executive
Xuất Excel bảng công toàn công ty.

| | |
|---|---|
| **Response** | `byte[]` Excel |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Ban Giám Đốc |

---

### `POST /api/attendances/summary/generate` 🟡 HR / 🔴 Executive
Kích hoạt tính toán / tái tính bảng chấm công tháng cho toàn bộ nhân viên (chỉ khi trạng thái là **DRAFT**).

| | |
|---|---|
| **Query Params** | `month` (int), `year` (int) |
| **Response** | `{ "msg": "...", "calculatedCount": int, "status": "DRAFT" }` |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Ban Giám Đốc |

---

### `PUT /api/attendances/summary/{timesheetId}` 🟡 HR / 🔴 Executive
Điều chỉnh chi tiết bảng công cá nhân khi đang ở trạng thái **DRAFT**.

| | |
|---|---|
| **Path Param** | `timesheetId` (UUID) |
| **Request Body** | `MonthlyTimesheetEditRequest` (ngày công, giờ công, OT, ngày nghỉ, …) |
| **Response** | `CompanyMonthlyTimesheetResponse` |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Ban Giám Đốc |

---

### `PUT /api/attendances/summary/lock` 🟠 HR Head / 🔴 Executive
Chốt sổ (khóa) bảng chấm công tháng → trạng thái **LOCKED**. Sau khi khóa, không thể sửa/xóa bản ghi chấm công tháng đó.

| | |
|---|---|
| **Query Params** | `month`, `year` |
| **Response** | `{ "msg": "...", "lockedCount": int, "status": "LOCKED" }` |
| **Quyền truy cập** | 🟠 Trưởng phòng HR hoặc 🔴 Ban Giám Đốc |

---

## 7. Nghỉ phép – `/api/leave`

### `GET /api/leave/preview` 🔒
Xem trước tính toán ngày nghỉ trước khi tạo đơn (trừ ngày lễ, ngày nghỉ ca, kiểm tra phép năm còn lại).

| | |
|---|---|
| **Query Params** | `fromDate` (LocalDate), `toDate` (LocalDate) |
| **Response** | `LeavePreviewResponse` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`LeavePreviewResponse`**:

| Trường | Kiểu |
|---|---|
| `requestedLeaveDays` | `long` |
| `workDays` | `int` |
| `restDays` | `int` |
| `holidayDays` | `int` |
| `annualLeaveDays` | `int` |
| `usedLeaveDays` | `int` |
| `remainingAnnualLeaveDays` | `int` |
| `remainingAfterThisRequest` | `int` |
| `isSufficientAnnualLeave` | `boolean` |

---

### `POST /api/leave` 🔒
Tạo đơn xin nghỉ phép. Tối đa 14 ngày lịch / đơn. Không cho phép trùng lặp với đơn đang pending/accepted.

| | |
|---|---|
| **Request Body** | `CreateLeaveReqRequest` (`fromDate`, `toDate`, `reason`, `paidLeaveDays`) |
| **Response** | Entity `LeaveRequest` · HTTP 201 |
| **Quyền truy cập** | Tất cả user đã đăng nhập (trừ **Chairman** – không thể tạo đơn) |

---

### `GET /api/leave/my-requests` 🔒
Xem danh sách đơn nghỉ phép của chính mình.

| | |
|---|---|
| **Query Params** | `LeaveFilterRequest` + phân trang |
| **Response** | `Page<StaffLeaveResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`StaffLeaveResponse`**:

| Trường | Kiểu |
|---|---|
| `requestId` | `UUID` |
| `fromDate`, `toDate` | `LocalDate` |
| `reason` | `String` |
| `rejectionReason` | `String` |
| `paidLeaveDays` | `int` |
| `status` | `LeaveRequestStatus` (pending / accepted / rejected) |
| `createdAt` | `LocalDateTime` |
| `approverId` | `UUID` |
| `approverName` | `String` |
| `approverJob` | `String` |

---

### `GET /api/leave/approvals` 🔵 Manager / 🔴 Executive
Xem danh sách đơn nghỉ phép cần duyệt (dành cho Trưởng phòng & Ban Giám Đốc).

| | |
|---|---|
| **Query Params** | `LeaveFilterRequest` + phân trang |
| **Response** | `Page<ManagerLeaveResponse>` |
| **Quyền truy cập** | 🔵 Trưởng phòng (xem đơn của nhân viên cùng phòng) hoặc 🔴 Ban Giám Đốc |

**`ManagerLeaveResponse`** (bổ sung thêm so với Staff):

| Trường | Kiểu |
|---|---|
| `requestorId`, `requestorCode` | UUID, String |
| `requestorName` | `String` |
| `requestorDepartment`, `requestorJob` | `String` |
| `requestorProfilePicUrl` | `String` |

---

### `GET /api/leave/company` 🟡 HR
Xem toàn bộ đơn nghỉ phép công ty (dành riêng cho HR để theo dõi / chấm công).

| | |
|---|---|
| **Query Params** | `LeaveFilterRequest` + phân trang |
| **Response** | `Page<HrLeaveResponse>` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

**`HrLeaveResponse`** (đầy đủ nhất, bổ sung thêm so với Manager):

| Trường | Kiểu |
|---|---|
| `totalAnnualLeaveDays` | `Integer` |
| `usedLeaveDays` | `Integer` |
| `remainingAnnualLeaveDays` | `Integer` |
| `requestorEmail` | `String` |
| `requestorPhoneNumber` | `String` |

---

### `PATCH /api/leave/{requestId}/handle` 🔵 Manager / 🔴 Executive
Phê duyệt hoặc từ chối đơn nghỉ phép. Khi approved → tự động cập nhật chấm công và trừ phép năm.

| | |
|---|---|
| **Path Param** | `requestId` (UUID) |
| **Request Body** | `HandleLeaveReqApiRequest` (`status`: accepted/rejected, `rejectionReason`) |
| **Response** | Entity `LeaveRequest` |
| **Quyền truy cập** | 🔵 Trưởng phòng cùng phòng với người xin nghỉ **hoặc** 🔴 Ban Giám Đốc. Không được tự duyệt đơn mình. |

---

### `DELETE /api/leave/{requestId}` 🔒
Hủy / xóa đơn nghỉ phép của chính mình (chỉ khi đang ở trạng thái **pending**).

| | |
|---|---|
| **Response** | `{ "message": "Đơn xin nghỉ phép đã được hủy thành công" }` |
| **Quyền truy cập** | Chỉ người tạo đơn, chỉ khi còn **pending** |

---

### `GET /api/leave/export` 🟡 HR
Xuất báo cáo nghỉ phép toàn công ty ra file Excel.

| | |
|---|---|
| **Response** | `byte[]` Excel |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

## 8. Tăng ca (Overtime) – `/api/overtime`

### `PUT /api/overtime/{userId}` 🔒
Chấm công tăng ca (clock in / clock out OT) cho user.

| | |
|---|---|
| **Path Param** | `userId` (UUID) |
| **Response** | `{ "action": "CLOCK_IN" / "CLOCK_OUT", "msg": "..." }` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

### `POST /api/overtime` 🔒
Tạo đơn đăng ký làm thêm giờ. Hệ thống kiểm tra chặt chẽ: ≥ 1h/đơn, ≤ 12h/đơn, ≤ 40h/tháng, ≤ 200h/năm, đủ 12h nghỉ giữa các ca, không trùng giờ làm chính.

| | |
|---|---|
| **Request Body** | `OvertimeWorkTimeRequest` (`approvedStartTime`, `approvedEndTime`, `reason`) |
| **Response** | Entity `OvertimeRecord` · HTTP 201 |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

### `DELETE /api/overtime/{overtimeRecordId}` 🔒
Hủy đơn tăng ca của chính mình (chỉ khi đang **pending**).

| | |
|---|---|
| **Response** | `{ "msg": "Đã hủy đơn làm thêm giờ thành công" }` |
| **Quyền truy cập** | Chỉ người tạo đơn, chỉ khi còn **pending** |

---

### `GET /api/overtime/my-records` 🔒
Xem danh sách đơn tăng ca của chính mình.

| | |
|---|---|
| **Query Params** | `OvertimeFilterRequest` + phân trang |
| **Response** | `Page<StaffOvertimeResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`StaffOvertimeResponse`**:

| Trường | Kiểu |
|---|---|
| `overtimeRecordId` | `UUID` |
| `approvedDate` | `LocalDate` |
| `approvedStartTime`, `approvedEndTime` | `LocalDateTime` |
| `clockInTime`, `clockOutTime` | `LocalDateTime` |
| `isHoliday`, `isWeekend`, `isNightTime` | `boolean` |
| `status` | `OvertimeRecordStatus` (pending / accepted / rejected) |
| `reason`, `rejectionReason` | `String` |
| `approverId`, `approverName`, `approverJob` | UUID, String, String |

---

### `GET /api/overtime/approvals` 🔵 Manager / 🔴 Executive
Xem danh sách đơn tăng ca cần duyệt.

| | |
|---|---|
| **Response** | `Page<ManagerOvertimeResponse>` |
| **Quyền truy cập** | 🔵 Trưởng phòng (xem đơn nhân viên cùng phòng) hoặc 🔴 Ban Giám Đốc |

**`ManagerOvertimeResponse`** (bổ sung so với Staff): `requestorId`, `requestorCode`, `requestorName`, `requestorDepartment`, `requestorJob`, `requestorProfilePicUrl`

---

### `GET /api/overtime/company` 🟡 HR
Xem toàn bộ đơn tăng ca của công ty.

| | |
|---|---|
| **Response** | `Page<HrOvertimeResponse>` |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

**`HrOvertimeResponse`** (bổ sung so với Manager):

| Trường | Kiểu |
|---|---|
| `requestorEmail` | `String` |
| `requestorPhoneNumber` | `String` |
| `totalApprovedHours` | `Double` |
| `totalActualHours` | `Double` |

---

### `GET /api/overtime/export` 🟡 HR
Xuất báo cáo tăng ca toàn công ty ra file Excel.

| | |
|---|---|
| **Response** | `byte[]` Excel |
| **Quyền truy cập** | 🟡 Chỉ phòng **Human Resources** |

---

### `PATCH /api/overtime/{overtimeRecordId}/handle` 🔵 Manager / 🔴 Executive
Phê duyệt hoặc từ chối đơn tăng ca.

| | |
|---|---|
| **Path Param** | `overtimeRecordId` (UUID) |
| **Request Body** | `HandleOvertimeReqApiRequest` (`status`, `rejectionReason`) |
| **Response** | Entity `OvertimeRecord` |
| **Quyền truy cập** | 🔵 Trưởng phòng cùng phòng với người đăng ký **hoặc** 🔴 Ban Giám Đốc. Không được tự duyệt. |

---

## 9. Lương – `/api/payrolls`

### `GET /api/payrolls/me` 🔒
Xem danh sách phiếu lương của chính mình (bao gồm cả DRAFT để đối soát).

| | |
|---|---|
| **Query Params** | `StaffPayrollFilterRequest` (`month`, `year`, `status`) + phân trang |
| **Response** | `Page<StaffPayrollResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

**`StaffPayrollResponse`**:

| Trường | Kiểu |
|---|---|
| `payrollId` | `UUID` |
| `periodMonth`, `periodYear` | `int` |
| `baseSalary`, `hourlyRate` | `BigDecimal` |
| `standardWorkingDays` | `int` |
| `actualWorkedDays`, `actualWorkHours` | `BigDecimal` |
| `paidOvertimeHours` | `BigDecimal` |
| `basicPay`, `overtimePay`, `allowancePay`, `bonusPay` | `BigDecimal` |
| `grossPay` | `BigDecimal` |
| `insuranceDeduction` (10.5% lương cơ sở) | `BigDecimal` |
| `taxDeduction` (Thuế TNCN lũy tiến 7 bậc) | `BigDecimal` |
| `otherDeduction`, `totalDeduction` | `BigDecimal` |
| `netPay` | `BigDecimal` |
| `status` | `PayrollStatus` (DRAFT / APPROVED / PAID) |
| `note` | `String` |
| `calculatedAt`, `paidAt` | `LocalDateTime` |

---

### `GET /api/payrolls/me/export` 🔒
Xuất Excel phiếu lương cá nhân.

| | |
|---|---|
| **Response** | `byte[]` Excel |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

### `GET /api/payrolls/company` 💰 Accounting / 🔴 Executive
Xem bảng lương toàn bộ nhân viên (loại trừ chính mình).

| | |
|---|---|
| **Query Params** | `CompanyPayrollFilterRequest` + phân trang |
| **Response** | `Page<CompanyPayrollResponse>` |
| **Quyền truy cập** | 💰 Nhân viên Kế toán/Tài chính hoặc 🔴 Ban Giám Đốc |

**`CompanyPayrollResponse`** (bổ sung so với Staff): `userId`, `employeeCode`, `fullName`, `department`, `job`, `approvedAt`

---

### `GET /api/payrolls/company/export` 💰 Accounting / 🔴 Executive
Xuất Excel bảng lương toàn công ty.

| | |
|---|---|
| **Response** | `byte[]` Excel |
| **Quyền truy cập** | 💰 Kế toán/Tài chính hoặc 🔴 Ban Giám Đốc |

---

### `GET /api/payrolls/summary` 💰 Accounting / 🔴 Executive
Xem tổng hợp chi phí lương và bảo hiểm toàn công ty cho một tháng cụ thể.

| | |
|---|---|
| **Query Params** | `month`, `year` |
| **Response** | `MonthlyPayrollSummaryResponse` |
| **Quyền truy cập** | 💰 Kế toán/Tài chính hoặc 🔴 Ban Giám Đốc |

**`MonthlyPayrollSummaryResponse`**:

| Trường | Kiểu |
|---|---|
| `summaryId` | `UUID` |
| `periodMonth`, `periodYear` | `int` |
| `totalEmployees` | `int` |
| `totalGrossPay`, `totalNetPay` | `BigDecimal` |
| `totalBasicPay`, `totalOvertimePay` | `BigDecimal` |
| `totalBonusPay`, `totalAllowancePay` | `BigDecimal` |
| `totalPersonalIncomeTax` | `BigDecimal` |
| `totalEmployeeInsurance` | `BigDecimal` (10.5% NLĐ đóng) |
| `totalCompanyInsurance` | `BigDecimal` (21.5% công ty đóng) |
| `totalUnionFee` | `BigDecimal` (2% công đoàn) |
| `totalCompanyCost` | `BigDecimal` (Tổng chi phí công ty) |
| `status` | `PayrollStatus` |
| `approvedBy` | `UUID` |
| `approvedAt`, `createdAt` | `LocalDateTime` |

---

### `POST /api/payrolls/generate` 💰 Accounting / 🔴 Executive
Kế toán kích hoạt tính toán bảng lương tự động từ `MonthlyTimesheet` **LOCKED**. Cho phép tính lại nếu đang **DRAFT**.

| | |
|---|---|
| **Query Params** | `month`, `year` |
| **Response** | `{ "msg": "...", "calculatedCount": int, "status": "DRAFT" }` |
| **Quyền truy cập** | 💰 Kế toán/Tài chính hoặc 🔴 Ban Giám Đốc |

---

### `PUT /api/payrolls/{payrollId}` 💰 Accounting / 🔴 Executive
Điều chỉnh phụ cấp, thưởng, khấu trừ khác khi bảng lương đang **DRAFT**.

| | |
|---|---|
| **Request Body** | `EditPayrollRequest` (`allowancePay`, `bonusPay`, `otherDeduction`, `taxDeduction`, `note`) |
| **Response** | `CompanyPayrollResponse` |
| **Quyền truy cập** | 💰 Kế toán/Tài chính hoặc 🔴 Ban Giám Đốc |

---

### `PUT /api/payrolls/approve` 💰💰 Chief Accountant / 🔴 Executive
Kế toán trưởng phê duyệt bảng lương tháng → trạng thái **APPROVED**.

| | |
|---|---|
| **Query Params** | `month`, `year` |
| **Response** | `{ "msg": "...", "approvedCount": int, "status": "APPROVED" }` |
| **Quyền truy cập** | 💰💰 Kế toán trưởng (`job` chứa head/manager/lead + phòng Kế toán/Tài chính) hoặc 🔴 Ban Giám Đốc |

---

### `PUT /api/payrolls/pay` 💰 Accounting / 🔴 Executive
Xác nhận hoàn tất chi trả bảng lương tháng → trạng thái **PAID** (bảng lương phải đã **APPROVED**).

| | |
|---|---|
| **Query Params** | `month`, `year` |
| **Response** | `{ "msg": "...", "paidCount": int, "status": "PAID" }` |
| **Quyền truy cập** | 💰 Kế toán/Tài chính hoặc 🔴 Ban Giám Đốc |

---

## 10. Thôi việc – `/api/resignations`

### `POST /api/resignations` 🔒
Nhân viên nộp đơn xin thôi việc. Kiểm tra thời hạn báo trước: Indefinite ≥ 45 ngày, Fixed-term ≥ 30 ngày, Probation ≥ 3 ngày.

| | |
|---|---|
| **Request Body** | `CreateResignationRequest` (`lastWorkingDate`, `reason`) |
| **Response** | `ResignationResponse` · HTTP 201 |
| **Quyền truy cập** | Tất cả user đã đăng nhập (chỉ tạo cho chính mình, không trùng đơn cũ đang xử lý) |

**`ResignationResponse`**:

| Trường | Kiểu |
|---|---|
| `resignationId` | `UUID` |
| `userId`, `employeeCode`, `employeeName` | UUID, String, String |
| `departmentName`, `jobTitle` | `String` |
| `profilePicUrl` | `String` |
| `joinedDate` | `LocalDate` |
| `contractType` | `String` |
| `submittedTime` | `LocalDateTime` |
| `lastWorkingDate` | `LocalDate` |
| `reason` | `String` |
| `status` | `ResignationStatus` (PENDING / MANAGER_APPROVED / MANAGER_REJECTED / APPROVED / REJECTED / CANCELLED / COMPLETED) |
| `managerId`, `managerName`, `managerComment`, `managerApprovedAt` | UUID, String, String, LocalDateTime |
| `executiveId`, `executiveName`, `executiveComment`, `executiveApprovedAt` | UUID, String, String, LocalDateTime |
| `createdAt`, `updatedAt` | `LocalDateTime` |

---

### `PUT /api/resignations/transfer` 🔵 Manager (cùng phòng) / 🔴 Executive
**Cấp 1:** Trưởng phòng ban phê duyệt kế hoạch bàn giao hoặc từ chối đơn thôi việc.

| | |
|---|---|
| **Request Body** | `TransferRequest` (`resignationId`, `status`: MANAGER_APPROVED/MANAGER_REJECTED, `managerComment`) |
| **Response** | `{ "message": "..." }` |
| **Quyền truy cập** | 🔵 Trưởng phòng cùng phòng với người xin thôi việc hoặc 🔴 Ban Giám Đốc. Không được tự duyệt. |

---

### `PUT /api/resignations/approve` 🟡 HR / 🔴 Executive
**Cấp 2:** Ban Giám Đốc hoặc HR phê duyệt chính thức đơn thôi việc (sau khi Trưởng phòng đã duyệt Cấp 1). Nếu ngày làm việc cuối đã qua → tài khoản bị khóa ngay.

| | |
|---|---|
| **Request Body** | `ApproveResignationRequest` (`resignationId`, `status`: APPROVED/REJECTED, `executiveComment`) |
| **Response** | `{ "message": "..." }` |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Ban Giám Đốc. Không được tự duyệt. |

---

### `GET /api/resignations/my-requests` 🔒
Xem danh sách đơn thôi việc của chính mình.

| | |
|---|---|
| **Response** | `Page<ResignationResponse>` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

### `GET /api/resignations/approvals` 🔵 Manager / 🟡 HR / 🔴 Executive
Xem danh sách đơn thôi việc cần duyệt theo cấp của mình.

- **Trưởng phòng:** Xem đơn **PENDING** của nhân viên trong phòng ban
- **HR / BGĐ:** Xem đơn **MANAGER_APPROVED** (hoặc PENDING của chính các Trưởng phòng)

| | |
|---|---|
| **Response** | `Page<ResignationResponse>` |
| **Quyền truy cập** | 🔵 Trưởng phòng, 🟡 HR, hoặc 🔴 Ban Giám Đốc |

---

### `GET /api/resignations/company` 🟡 HR / 🔴 Executive
Xem toàn bộ đơn thôi việc của công ty (có thể lọc theo trạng thái).

| | |
|---|---|
| **Query Params** | `status` (ResignationStatus – tuỳ chọn) + phân trang |
| **Response** | `Page<ResignationResponse>` |
| **Quyền truy cập** | 🟡 HR hoặc 🔴 Ban Giám Đốc |

---

### `PATCH /api/resignations/{resignationId}/cancel` 🔒
Hủy đơn xin thôi việc của chính mình (chỉ khi đang **PENDING**).

| | |
|---|---|
| **Response** | `{ "message": "Đã hủy đơn xin thôi việc thành công" }` |
| **Quyền truy cập** | Chỉ người tạo đơn, chỉ khi còn **PENDING** |

---

## 11. Dashboard – `/api/dashboard`

### `GET /api/dashboard/summary` 🔒
Lấy toàn bộ thông tin tổng quan trang Dashboard cá nhân. Tự động điều chỉnh nội dung theo vai trò (Nhân viên / Quản lý / HR / Ban Giám Đốc).

| | |
|---|---|
| **Response** | `DashboardSummaryResponse` |
| **Quyền truy cập** | Tất cả user đã đăng nhập |

---

## 12. Data Seeder – `/api/seeder` *(Dev/Test only)*

### `POST /api/seeder/mock-data`
Tạo dữ liệu mẫu cho môi trường dev/test.

| | |
|---|---|
| **Query Params** | `year` (default 2026), `fromMonth` (default 1), `toMonth` (default 8), `clearExisting` (default true), `autoGenerateTimesheets` (default true) |
| **Response** | `Map<String, Object>` (thống kê kết quả) |
| **Quyền truy cập** | Không kiểm tra (chỉ dùng nội bộ / dev) |

---

## Sơ đồ phân quyền tổng hợp

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        PHÂN CẤP QUYỀN HẠN                              │
├──────────────────────┬──────────────────────────────────────────────────┤
│ Vai trò              │ Định nghĩa                                        │
├──────────────────────┼──────────────────────────────────────────────────┤
│ 🔒 Authenticated     │ Mọi user đã đăng nhập                             │
│ 🟡 HR                │ department = "Human Resources"                    │
│ 🟠 HR Head           │ department = HR + job contains "Head"             │
│ 🔵 Manager           │ job starts with "Department Head"                 │
│ 🔴 Executive         │ department = "Executive Leadership"               │
│ 💰 Accounting        │ dept contains accounting/finance/kế toán OR       │
│                      │   job contains "accountant/kế toán"               │
│ 💰💰 Chief Accountant │ (head/manager/lead + dept Accounting/Finance) OR │
│                      │   department = Executive Leadership               │
└──────────────────────┴──────────────────────────────────────────────────┘
```

### Luồng phê duyệt đơn thôi việc (2 cấp)

```
Nhân viên nộp đơn (PENDING)
         │
         ▼
Trưởng phòng duyệt Cấp 1
   ├─ MANAGER_APPROVED ──────────────────────────────────────┐
   └─ MANAGER_REJECTED → kết thúc                           │
                                                             ▼
                                          HR / Ban Giám Đốc phê duyệt Cấp 2
                                            ├─ APPROVED → (nếu lastWorkingDate đã qua
                                            │              → COMPLETED + khóa tài khoản)
                                            └─ REJECTED → kết thúc
```

### Luồng tính lương hàng tháng

```
[HR / BGĐ]     Tổng hợp bảng công   →  MonthlyTimesheet: DRAFT
[HR / BGĐ]     Điều chỉnh chi tiết  →  MonthlyTimesheet: DRAFT
[HR Head/BGĐ]  Chốt sổ bảng công    →  MonthlyTimesheet: LOCKED
[Kế toán]      Tính lương tự động   →  Payroll: DRAFT
[Kế toán]      Điều chỉnh lương     →  Payroll: DRAFT
[KT trưởng]    Phê duyệt bảng lương →  Payroll: APPROVED
[Kế toán]      Xác nhận chi trả     →  Payroll: PAID
```

### Luồng xử lý đơn nghỉ phép / tăng ca

```
Nhân viên tạo đơn (PENDING)
         │
         ▼
Trưởng phòng cùng phòng hoặc Ban Giám Đốc xử lý
   ├─ accepted → Cập nhật chấm công + trừ phép năm (nghỉ phép)
   └─ rejected → Kết thúc
```

# HRM Backend – API Documentation

> **Spring Boot · Java 17 · Spring Data JPA · PostgreSQL · JWT Authentication**

---

## Thông tin chung

| Mục | Giá trị |
|---|---|
| **Base URL** | `http://localhost:8080` |
| **Content-Type** | `application/json` |
| **Authentication** | `Authorization: Bearer <accessToken>` |
| **Date format** | `yyyy-MM-dd` |
| **DateTime format** | `yyyy-MM-dd'T'HH:mm` |
| **Time format** | `HH:mm:ss` |
| **Pagination** | Query params: `page` (0-indexed), `size`, `sort` |

---

## Định dạng Response

### ✅ Thành công
Response thành công trả về trực tiếp dữ liệu theo từng endpoint (object, array, hoặc Page).

**Pagination** (`Page<T>`) – Spring Data format:
```json
{
  "content": [ ... ],
  "pageable": { "pageNumber": 0, "pageSize": 10 },
  "totalElements": 50,
  "totalPages": 5,
  "last": false,
  "first": true
}
```

### ❌ Lỗi nghiệp vụ
```json
{
  "errorCode": "INSUFFICIENT_PERMISSION",
  "msg": "Chỉ phòng Nhân sự (HR) hoặc Ban Giám Đốc mới có quyền thao tác dữ liệu chấm công toàn công ty"
}
```

### ❌ Lỗi validation (400 Bad Request)
```json
{
  "errorCode": "VALIDATION_FAILED",
  "msg": "Email không đúng định dạng",
  "errors": {
    "email": "Email không đúng định dạng",
    "password": "Mật khẩu phải có tối thiểu 6 ký tự"
  }
}
```

### ❌ Lỗi server (500)
```json
"Internal Server Error"
```

---

## HTTP Status Codes

| Code | Ý nghĩa |
|---|---|
| `200 OK` | Thành công |
| `201 Created` | Tạo mới thành công |
| `400 Bad Request` | Dữ liệu đầu vào không hợp lệ / vi phạm quy tắc nghiệp vụ |
| `401 Unauthorized` | Chưa đăng nhập / Token hết hạn / Session không hợp lệ |
| `403 Forbidden` | Đã đăng nhập nhưng không có quyền thực hiện thao tác |
| `404 Not Found` | Không tìm thấy resource |
| `500 Internal Server Error` | Lỗi server không xác định |

---

## Quy ước phân quyền

| Ký hiệu | Điều kiện kiểm tra trong Service |
|---|---|
| 🔓 **Public** | Không cần xác thực |
| 🔒 **Authenticated** | Bất kỳ user đã đăng nhập |
| 🟡 **HR** | `department == "Human Resources"` |
| 🟠 **HR Head** | `department == "Human Resources"` + `job.contains("Head")` |
| 🔵 **Manager** | `job.startsWith("Department Head")` |
| 🔴 **Executive** | `department == "Executive Leadership"` |
| 💰 **Accounting** | `dept` chứa `accounting/finance/kế toán/tài chính` **HOẶC** `job` chứa `accountant/kế toán` |
| 💰💰 **Chief Accountant** | `job` chứa `head/manager/lead` + phòng Kế toán/Tài chính **HOẶC** 🔴 Executive |

---

## Enum Values

### `AttendanceStatus`
| Giá trị | Mô tả |
|---|---|
| `NOT_CHECKED` | Chưa chấm công |
| `WORKING` | Đang làm việc (đã vào, chưa ra) |
| `SUFFICIENT` | Đủ giờ |
| `LATE` | Đi muộn |
| `EARLY` | Về sớm |
| `LATE_AND_EARLY` | Vừa đi muộn vừa về sớm |
| `MISSING` | Thiếu lượt (chỉ vào hoặc chỉ ra) |
| `UNEXCUSED_ABSENCE` | Vắng mặt không phép |
| `PAID_LEAVE` | Nghỉ phép có lương |
| `UNPAID_LEAVE` | Nghỉ phép không lương |
| `HOLIDAY` | Ngày lễ |
| `BUSINESS_TRIP` | Công tác |
| `ADJUSTED` | Đã được điều chỉnh thủ công |

### `TimesheetStatus`
| Giá trị | Mô tả |
|---|---|
| `DRAFT` | Bảng công đang tổng hợp, có thể chỉnh sửa |
| `LOCKED` | Đã chốt sổ, không thể sửa bản ghi chấm công |

### `LeaveRequestStatus`
| Giá trị | Mô tả |
|---|---|
| `pending` | Chờ duyệt |
| `accepted` | Đã phê duyệt |
| `rejected` | Đã từ chối |

### `OvertimeRecordStatus`
| Giá trị | Mô tả |
|---|---|
| `pending` | Chờ duyệt |
| `accepted` | Đã phê duyệt |
| `rejected` | Đã từ chối |

### `PayrollStatus`
| Giá trị | Mô tả |
|---|---|
| `DRAFT` | Bản nháp, kế toán đang xem xét |
| `APPROVED` | Kế toán trưởng đã phê duyệt |
| `PAID` | Đã chi trả |

### `ResignationStatus`
| Giá trị | Mô tả |
|---|---|
| `PENDING` | Chờ trưởng phòng duyệt bàn giao |
| `MANAGER_APPROVED` | Trưởng phòng đã duyệt, chờ HR/BGĐ phê duyệt chính thức |
| `MANAGER_REJECTED` | Trưởng phòng từ chối |
| `APPROVED` | HR/BGĐ đã phê duyệt chính thức |
| `REJECTED` | HR/BGĐ từ chối |
| `CANCELLED` | Nhân viên tự hủy |
| `COMPLETED` | Hoàn tất thôi việc (tài khoản đã bị khóa) |

---

## 1. Authentication – `/auth`

### `POST /auth/register` 🔓

**Request Body:**
```json
{
  "departmentId": "uuid (bắt buộc)",
  "jobId": "uuid (bắt buộc)",
  "email": "user@company.com (bắt buộc, định dạng email)",
  "password": "secret123 (bắt buộc, tối thiểu 6 ký tự)",
  "firstName": "Nguyễn Văn (bắt buộc)",
  "lastName": "An (bắt buộc)",
  "employeeCode": "NV001 (tuỳ chọn)",
  "gender": "Male | Female | Other (tuỳ chọn)",
  "birthDate": "1995-05-20 (tuỳ chọn)",
  "joinedDate": "2024-01-01 (tuỳ chọn)",
  "annualLeaveDays": 12,
  "usedLeaveDays": 0
}
```

**Response** `201`:
```json
{ "message": "User created" }
```

| Error | HTTP | errorCode |
|---|---|---|
| Validation thất bại | `400` | `VALIDATION_FAILED` |

---

### `POST /auth/login` 🔓

**Request Body:**
```json
{
  "email": "user@company.com (bắt buộc)",
  "password": "secret123 (bắt buộc)"
}
```

**Response** `200`:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@company.com",
  "fullName": "Nguyễn Văn An",
  "profilePicUrl": "https://...",
  "department": "Human Resources",
  "job": "Department Head of HR"
}
```

> 🍪 **Set-Cookie**: `refreshToken` (HttpOnly, 7 ngày) · `deviceId` (1 năm)

| Error | HTTP | errorCode |
|---|---|---|
| Email/password sai | `401` | `USER_CREDENTIALS_INVALID` |
| Tài khoản bị khóa | `403` | `ACCOUNT_DISABLED` |
| Email không tồn tại | `404` | `USER_NOT_FOUND` |

---

### `POST /auth/auto-login` 🔓

> **Cookie yêu cầu:** `refreshToken`, `deviceId`

**Response** `200`: Giống `SignInResponse` + set `refreshToken` cookie mới.

| Error | HTTP | errorCode |
|---|---|---|
| Session hết hạn / không hợp lệ | `401` | `SESSION_NOT_FOUND` / `SESSION_REVOKED` / `SESSION_MISMATCH` |
| Phiên bị xâm nhập | `401` | `SESSION_COMPROMISED` |
| Thiết bị không khớp | `403` | `DEVICE_MISMATCH` |

---

### `POST /auth/logout` 🔒

> **Cookie yêu cầu:** `refreshToken`

**Response** `200`:
```json
{ "message": "Logged out successfully" }
```

---

### `PUT /auth/change-password` 🔒

**Request Body:**
```json
{
  "oldPassword": "current_pass (bắt buộc)",
  "newPassword": "new_pass (bắt buộc)"
}
```

**Response** `200`:
```json
{ "message": "Đổi mật khẩu thành công" }
```

| Error | HTTP | errorCode |
|---|---|---|
| Mật khẩu cũ sai | `401` | `USER_CREDENTIALS_INVALID` |

---

## 2. Nhân viên – `/api/employees`

### `GET /api/employees` 🔒

**Query Params:**

| Param | Kiểu | Mô tả |
|---|---|---|
| `keyword` | `String` | Tìm theo tên hoặc mã nhân viên |
| `department` | `String` | Lọc theo tên phòng ban |
| `page` | `int` | Trang (0-indexed, default 0) |
| `size` | `int` | Kích thước trang (default 10) |
| `sort` | `String` | Sắp xếp (default `employeeCode,asc`) |

**Response** `200` – `Page<EmployeeDirectoryItemResponse>`:
```json
{
  "content": [
    {
      "userId": "uuid",
      "employeeCode": "NV001",
      "fullName": "Nguyễn Văn An",
      "profilePicUrl": "https://...",
      "departmentName": "Human Resources",
      "jobTitle": "HR Specialist",
      "isActive": true
    }
  ],
  "totalElements": 50,
  "totalPages": 5
}
```

---

### `GET /api/employees/{userId}/public-profile` 🔒

**Response** `200` – `EmployeePublicProfile`:
```json
{
  "userId": "uuid",
  "employeeCode": "NV001",
  "firstName": "Văn An",
  "lastName": "Nguyễn",
  "fullName": "Nguyễn Văn An",
  "profilePicUrl": "https://...",
  "gender": "Male",
  "birthDate": "1995-05-20",
  "joinedDate": "2022-01-01",
  "jobTitle": "HR Specialist",
  "departmentName": "Human Resources",
  "workEmail": "an.nv@company.com",
  "phoneNumber": "0901234567",
  "todayStatus": "SUFFICIENT",
  "shiftName": "Ca Hành Chính",
  "weeklySchedule": [
    {
      "dayOfWeek": 1,
      "dayName": "Thứ 2",
      "isWorking": true,
      "startTime": "08:00:00",
      "endTime": "17:00:00",
      "restStartTime": "12:00:00",
      "restEndTime": "13:00:00"
    }
  ],
  "isActive": true
}
```

| Error | HTTP | Mô tả |
|---|---|---|
| Không tìm thấy | `400` | `BAD_REQUEST` |

---

### `GET /api/employees/{userId}/detailed` 🔒
### `GET /api/employees/me/detailed` 🔒

**Response** `200` – `EmployeeDetailResponse` (nội dung phụ thuộc vào quyền của người gọi):
```json
{
  "publicProfile": { "...": "Luôn trả về – xem cấu trúc trên" },
  "legalProfile": {
    "citizenIdNumber": "012345678901",
    "taxIdentificationNumber": "1234567890",
    "socialInsuranceNumber": "SN123456",
    "socialInsuranceStartDate": "2022-01-01",
    "personalEmail": "an@gmail.com",
    "placeOfBirth": "Hà Nội",
    "maritalStatus": "Single",
    "nationality": "Vietnamese",
    "emergencyContactName": "Nguyễn Văn B",
    "emergencyContactPhone": "0987654321"
  },
  "contract": {
    "contractType": "Indefinite",
    "contractStartDate": "2022-01-01",
    "contractEndDate": null
  },
  "payroll": {
    "baseSalary": 15000000,
    "payFrequency": "MONTHLY",
    "workDays": 22,
    "startDate": "2022-01-01",
    "endDate": null,
    "isActive": true,
    "bankName": "Vietcombank",
    "bankAccountNumber": "1234567890"
  }
}
```

> `legalProfile`, `contract`, `payroll` trả về `null` nếu người gọi không có quyền xem.

---

### `PUT /api/employees/{userId}/basic-info` 🟡 HR

**Request Body:**
```json
{
  "firstName": "Văn An",
  "lastName": "Nguyễn",
  "gender": "Male",
  "birthDate": "1995-05-20",
  "profilePicUrl": "https://...",
  "phoneNumber": "0901234567"
}
```

**Response** `200` – `EmployeeDetailResponse`

| Error | HTTP | errorCode |
|---|---|---|
| Không phải HR | `403` | `FORBIDDEN` |

---

### `PUT /api/employees/{userId}/legal-profile` 🟡 HR

**Request Body:**
```json
{
  "citizenIdNumber": "012345678901",
  "taxIdentificationNumber": "1234567890",
  "socialInsuranceNumber": "SN123456",
  "socialInsuranceStartDate": "2022-01-01",
  "personalEmail": "an@gmail.com",
  "placeOfBirth": "Hà Nội",
  "maritalStatus": "Single",
  "nationality": "Vietnamese",
  "emergencyContactName": "Nguyễn Văn B",
  "emergencyContactPhone": "0987654321"
}
```

**Response** `200` – `EmployeeDetailResponse`

---

### `PUT /api/employees/{userId}/contract` 🟡 HR

**Request Body:**
```json
{
  "contractType": "Indefinite | Fixed-term | Probation",
  "contractStartDate": "2022-01-01",
  "contractEndDate": "2025-01-01"
}
```

**Response** `200` – `EmployeeDetailResponse`

---

### `PUT /api/employees/{userId}/payroll` 🟡 HR

**Request Body:**
```json
{
  "baseSalary": 15000000.00,
  "payFrequency": "MONTHLY | WEEKLY | BIWEEKLY",
  "workDays": 22,
  "startDate": "2024-01-01",
  "bankName": "Vietcombank",
  "bankAccountNumber": "1234567890"
}
```

**Response** `200` – `EmployeeDetailResponse`

---

### `PUT /api/employees/{userId}/assignment` 🟡 HR

**Request Body:**
```json
{
  "departmentId": "uuid (bắt buộc)",
  "jobId": "uuid (bắt buộc)",
  "shiftId": "uuid (tuỳ chọn)"
}
```

**Response** `200` – `EmployeeDetailResponse`

---

### `POST /api/employees` 🟡 HR

**Request Body:**
```json
{
  "email": "newstaff@company.com (bắt buộc)",
  "password": "Pass@1234 (bắt buộc, tối thiểu 8 ký tự)",
  "firstName": "Văn Bình (bắt buộc)",
  "lastName": "Trần (bắt buộc)",
  "gender": "Male",
  "birthDate": "1998-03-15",
  "joinedDate": "2024-09-01",
  "departmentId": "uuid (bắt buộc)",
  "jobId": "uuid (bắt buộc)",
  "shiftId": "uuid (bắt buộc)",
  "employeeCode": "NV010",
  "phoneNumber": "0901111222",
  "citizenId": "012345678901",
  "address": "123 Lê Lợi, Q.1, TP.HCM",
  "baseSalary": 12000000.00
}
```

**Response** `201` – `EmployeeDetailResponse`

---

### `PATCH /api/employees/{userId}/status` 🟡 HR

**Request Body:**
```json
{
  "isActive": false,
  "reason": "Nhân viên đã nghỉ việc ngày 01/09/2024"
}
```

**Response** `200` – `EmployeeDetailResponse`

> Khi `isActive = false`: Thu hồi toàn bộ session ngay lập tức.

---

### `POST /api/employees/me/avatar` 🔒
### `POST /api/employees/{userId}/avatar` 🟡 HR / 🔴 Executive

**Request:** `multipart/form-data`, field `file` (ảnh JPG/PNG)

**Response** `200`:
```json
{
  "profilePicUrl": "https://storage.../avatar/uuid.jpg",
  "message": "Cập nhật ảnh đại diện thành công!"
}
```

---

## 3. Phòng ban – `/api/departments`

### `GET /api/departments` 🔒

**Response** `200` – `List<DepartmentResponse>`:
```json
[
  {
    "departmentId": "uuid",
    "name": "Human Resources",
    "totalEmployees": 5,
    "jobs": [
      { "jobId": "uuid", "title": "Department Head of HR" },
      { "jobId": "uuid", "title": "HR Specialist" }
    ]
  }
]
```

---

### `POST /api/departments` 🟠 HR Head / 🔴 Executive

**Request Body:**
```json
{
  "name": "Marketing (bắt buộc)"
}
```

**Response** `201` – `DepartmentResponse`

| Error | HTTP | Mô tả |
|---|---|---|
| Tên phòng ban đã tồn tại | `400` | `BAD_REQUEST` |
| Không đủ quyền | `403` | `FORBIDDEN` |

---

## 4. Chức vụ – `/api/jobs`

### `GET /api/jobs` 🔒

**Query Params:**

| Param | Kiểu | Mô tả |
|---|---|---|
| `departmentId` | `UUID` | Lọc theo phòng ban (tuỳ chọn) |

**Response** `200` – `List<JobResponse>`:
```json
[
  {
    "jobId": "uuid",
    "title": "HR Specialist",
    "departmentId": "uuid",
    "departmentName": "Human Resources"
  }
]
```

---

### `POST /api/jobs` 🟠 HR Head / 🔴 Executive

**Request Body:**
```json
{
  "title": "Senior Developer (bắt buộc)",
  "departmentId": "uuid (bắt buộc)"
}
```

**Response** `201` – `JobResponse`

| Error | HTTP | Mô tả |
|---|---|---|
| Chức danh đã tồn tại trong phòng ban | `400` | `BAD_REQUEST` |
| Không đủ quyền | `403` | `FORBIDDEN` |

---

## 5. Ca làm việc – `/api/work-shifts`

### `GET /api/work-shifts` 🔒

**Response** `200` – `List<WorkShiftResponse>`:
```json
[
  {
    "shiftId": "uuid",
    "name": "Ca Hành Chính",
    "schedules": [
      {
        "scheduleId": "uuid",
        "dayOfWeek": 1,
        "dayName": "Thứ 2",
        "isWorking": true,
        "startTime": "08:00:00",
        "endTime": "17:00:00",
        "restStartTime": "12:00:00",
        "restEndTime": "13:00:00"
      },
      {
        "dayOfWeek": 7,
        "dayName": "Chủ Nhật",
        "isWorking": false
      }
    ]
  }
]
```

---

### `POST /api/work-shifts` 🟠 HR Head / 🔴 Executive

**Request Body:**
```json
{
  "name": "Ca Sáng (bắt buộc)",
  "schedules": [
    {
      "dayOfWeek": 1,
      "isWorking": true,
      "startTime": "07:00:00",
      "endTime": "15:00:00",
      "restStartTime": "11:30:00",
      "restEndTime": "12:00:00"
    },
    {
      "dayOfWeek": 7,
      "isWorking": false
    }
  ]
}
```

> `dayOfWeek`: 1 = Thứ 2, ..., 7 = Chủ Nhật. Phải cung cấp đủ 7 ngày.
> Giới hạn: ≤ 8h/ngày, ≤ 48h/tuần.

**Response** `201` – `WorkShiftResponse`

| Error | HTTP | errorCode |
|---|---|---|
| Vượt 8h/ngày | `400` | `WORK_SHIFT_DAILY_HOURS_EXCEEDED` |
| Vượt 48h/tuần | `400` | `WORK_SHIFT_WEEKLY_HOURS_EXCEEDED` |
| Thời gian không hợp lệ | `400` | `WORK_SHIFT_INVALID_TIME` |

---

## 6. Chấm công – `/api/attendances`

### `GET /api/attendances/my-attendances` 🔒

**Query Params:**

| Param | Kiểu | Mô tả |
|---|---|---|
| `startDate` | `LocalDate` | Từ ngày |
| `endDate` | `LocalDate` | Đến ngày |
| `status` | `AttendanceStatus` | Lọc theo trạng thái |
| `page`, `size` | `int` | Phân trang |

**Response** `200` – `Page<StaffAttendanceResponse>`:
```json
{
  "content": [
    {
      "workDate": "2024-09-01",
      "clockInTime": "07:58:00",
      "clockOutTime": "17:05:00",
      "status": "SUFFICIENT",
      "isEdited": false,
      "editedReason": null
    }
  ]
}
```

---

### `GET /api/attendances/department` 🔵 Manager / 🔴 Executive

**Query Params:** Giống `my-attendances` + `keyword` (tên/mã NV), `departmentNames[]`

**Response** `200` – `Page<ManagerAttendanceResponse>`:
```json
{
  "content": [
    {
      "employeeCode": "NV002",
      "fullName": "Trần Thị B",
      "job": "Software Engineer",
      "workDate": "2024-09-01",
      "clockInTime": "08:15:00",
      "clockOutTime": "17:00:00",
      "status": "LATE",
      "isEdited": false,
      "editedReason": null
    }
  ]
}
```

---

### `GET /api/attendances/company` 🟡 HR

**Response** `200` – `Page<HrAttendanceResponse>` (đầy đủ nhất):
```json
{
  "content": [
    {
      "attendanceId": "uuid",
      "userId": "uuid",
      "employeeCode": "NV003",
      "fullName": "Lê Văn C",
      "department": "Engineering",
      "job": "Tech Lead",
      "workDate": "2024-09-01",
      "clockInTime": "08:00:00",
      "clockOutTime": "17:00:00",
      "status": "SUFFICIENT",
      "isEdited": true,
      "editedReason": "Quên bấm thẻ lúc ra về",
      "editorName": "Nguyễn HR",
      "editorEmpCode": "NV001"
    }
  ]
}
```

---

### `PUT /api/attendances/{userId}` 🔒

> Tự động xác định CLOCK_IN hoặc CLOCK_OUT dựa trên trạng thái hiện tại.

**Response** `200`:
```json
{
  "action": "CHECK_IN",
  "msg": "Chấm công vào thành công lúc 07:58:23"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Hôm nay không phải ngày làm việc của ca | `403` | `NOT_WORK_DAY` |
| Thời gian chấm công không hợp lệ | `403` | `INVALID_CLOCK_TIME` |

---

### `PUT /api/attendances/edit/{attendanceId}` 🟡 HR / 🔴 Executive

**Request Body:**
```json
{
  "editedClockInTime": "08:00:00",
  "editedClockOutTime": "17:00:00",
  "editedStatus": "SUFFICIENT",
  "editedReason": "Quên bấm thẻ lúc vào ca (tối đa 500 ký tự)"
}
```

> `editedStatus` **bắt buộc**. `editedClockInTime`, `editedClockOutTime` tuỳ chọn.

**Response** `200`:
```json
{
  "msg": "Cập nhật bản ghi chấm công thành công",
  "attendanceId": "uuid",
  "status": "SUFFICIENT"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Tháng đã bị LOCKED | `400` | `TIMESHEET_ALREADY_LOCKED` |
| Không đủ quyền | `403` | `INSUFFICIENT_PERMISSION` |

---

### `DELETE /api/attendances/{attendanceId}` 🟡 HR / 🔴 Executive

**Response** `200`: `"Attendance Record deleted"`

| Error | HTTP | errorCode |
|---|---|---|
| Tháng đã bị LOCKED | `400` | `TIMESHEET_ALREADY_LOCKED` |

---

### `GET /api/attendances/export` 🟡 HR

**Query Params:** Giống `company` filter

**Response** `200` – File Excel (`.xlsx`)
> Header: `Content-Disposition: attachment; filename="attendance_export.xlsx"`

---

### `GET /api/attendances/summary/me` 🔒

**Query Params:**

| Param | Kiểu | Mô tả |
|---|---|---|
| `month` | `int` | Tháng (1-12) |
| `year` | `int` | Năm |
| `page`, `size` | `int` | Phân trang |

**Response** `200` – `Page<StaffMonthlyTimesheetResponse>`:
```json
{
  "content": [
    {
      "periodMonth": 9,
      "periodYear": 2024,
      "standardWorkingDays": 22,
      "actualWorkedDays": 20.5,
      "actualWorkHours": 164.0,
      "lateCount": 2,
      "totalLateMinutes": 35,
      "earlyDepartureCount": 1,
      "absentDays": 0.5,
      "paidLeaveDays": 1.0,
      "unpaidLeaveDays": 0.0,
      "totalActualOtHours": 8.0,
      "totalPaidOtHours": 10.0,
      "otDetails": [
        {
          "type": "WEEKDAY",
          "label": "Ngày thường",
          "multiplier": 1.5,
          "hours": 5.0,
          "paidHours": 7.5
        }
      ],
      "status": "LOCKED"
    }
  ]
}
```

---

### `GET /api/attendances/summary/me/export` 🔒
### `GET /api/attendances/summary/department/export` 🔵 Manager / 🔴 Executive
### `GET /api/attendances/summary/company/export` 🟡 HR / 🔴 Executive

**Response** `200` – File Excel (`.xlsx`)

---

### `GET /api/attendances/summary/department` 🔵 Manager / 🔴 Executive
### `GET /api/attendances/summary/company` 🟡 HR / 🔴 Executive

**Query Params:** `month`, `year`, `keyword`, `departmentNames[]`, `page`, `size`

**Response** `200` – `Page<CompanyMonthlyTimesheetResponse>`:
```json
{
  "content": [
    {
      "userId": "uuid",
      "employeeCode": "NV002",
      "fullName": "Trần Thị B",
      "department": "Engineering",
      "job": "Senior Developer",
      "periodMonth": 9,
      "periodYear": 2024,
      "...": "Tất cả trường của StaffMonthlyTimesheetResponse"
    }
  ]
}
```

---

### `POST /api/attendances/summary/generate` 🟡 HR / 🔴 Executive

**Query Params:** `month` (int, bắt buộc), `year` (int, bắt buộc)

**Response** `200`:
```json
{
  "msg": "Tổng hợp bảng công tháng 9/2024 thành công",
  "calculatedCount": 45,
  "status": "DRAFT"
}
```

---

### `PUT /api/attendances/summary/{timesheetId}` 🟡 HR / 🔴 Executive

**Request Body:**
```json
{
  "actualWorkedDays": 21.0,
  "actualWorkHours": 168.0,
  "totalActualOtHours": 10.0,
  "totalPaidOtHours": 12.0,
  "paidLeaveDays": 1.0,
  "unpaidLeaveDays": 0.0,
  "lateCount": 1,
  "totalLateMinutes": 15,
  "earlyDepartureCount": 0,
  "absentDays": 0.0,
  "note": "Điều chỉnh do lỗi hệ thống (tối đa 500 ký tự)"
}
```

> Tất cả trường đều tuỳ chọn – chỉ truyền trường cần cập nhật.

**Response** `200` – `CompanyMonthlyTimesheetResponse`

| Error | HTTP | errorCode |
|---|---|---|
| Bảng công đã LOCKED | `400` | `TIMESHEET_ALREADY_LOCKED` |

---

### `PUT /api/attendances/summary/lock` 🟠 HR Head / 🔴 Executive

**Query Params:** `month` (int), `year` (int)

**Response** `200`:
```json
{
  "msg": "Khóa sổ bảng công tháng 9/2024 thành công",
  "lockedCount": 45,
  "status": "LOCKED"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Không đủ quyền | `403` | `INSUFFICIENT_PERMISSION` |

---

## 7. Nghỉ phép – `/api/leave`

### `GET /api/leave/preview` 🔒

**Query Params:** `fromDate` (`yyyy-MM-dd`), `toDate` (`yyyy-MM-dd`)

**Response** `200` – `LeavePreviewResponse`:
```json
{
  "requestedLeaveDays": 5,
  "workDays": 3,
  "restDays": 2,
  "holidayDays": 0,
  "annualLeaveDays": 12,
  "usedLeaveDays": 3,
  "remainingAnnualLeaveDays": 9,
  "remainingAfterThisRequest": 6,
  "isSufficientAnnualLeave": true
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Ngày bắt đầu sau ngày kết thúc | `400` | `INVALID_LEAVE_DATE` |
| Vượt quá 14 ngày | `400` | `MAXIMUM_LEAVE_DAYS` |
| Toàn bộ là ngày nghỉ trong ca | `400` | `ALL_REST_DAYS` |

---

### `POST /api/leave` 🔒

**Request Body:**
```json
{
  "requestorId": "uuid (ID của người xin nghỉ)",
  "fromDate": "2024-09-10 (bắt buộc)",
  "toDate": "2024-09-12 (bắt buộc)",
  "reason": "Việc gia đình (bắt buộc, tối đa 500 ký tự)",
  "paidLeaveDays": 3
}
```

**Response** `201` – Entity `LeaveRequest` (bao gồm `requestId`, `status: pending`, ...)

| Error | HTTP | errorCode |
|---|---|---|
| Chairman không được xin nghỉ | `400` | `CHAIRMAN_CANNOT_LEAVE` |
| Vượt quá phép năm còn lại | `400` | `OUT_OF_ANNUAL_LEAVE_DAYS` |
| Trùng lặp với đơn khác | `400` | `OVERLAPPING_LEAVE_REQUEST` |

---

### `GET /api/leave/my-requests` 🔒

**Query Params:**

| Param | Kiểu | Mô tả |
|---|---|---|
| `status` | `LeaveRequestStatus` | Lọc theo trạng thái |
| `fromDate`, `toDate` | `LocalDate` | Lọc theo khoảng ngày |
| `keyword` | `String` | Tìm kiếm |
| `page`, `size` | `int` | Phân trang |

**Response** `200` – `Page<StaffLeaveResponse>`:
```json
{
  "content": [
    {
      "requestId": "uuid",
      "fromDate": "2024-09-10",
      "toDate": "2024-09-12",
      "reason": "Việc gia đình",
      "rejectionReason": null,
      "paidLeaveDays": 3,
      "status": "accepted",
      "createdAt": "2024-09-05T10:30:00",
      "approverId": "uuid",
      "approverName": "Nguyễn Trưởng Phòng",
      "approverJob": "Department Head of Engineering"
    }
  ]
}
```

---

### `GET /api/leave/approvals` 🔵 Manager / 🔴 Executive

**Response** `200` – `Page<ManagerLeaveResponse>`:
```json
{
  "content": [
    {
      "requestId": "uuid",
      "fromDate": "2024-09-10",
      "toDate": "2024-09-12",
      "reason": "Ốm",
      "paidLeaveDays": 2,
      "status": "pending",
      "createdAt": "2024-09-05T08:00:00",
      "requestorId": "uuid",
      "requestorCode": "NV005",
      "requestorName": "Phạm Thị D",
      "requestorDepartment": "Engineering",
      "requestorJob": "Developer",
      "requestorProfilePicUrl": "https://..."
    }
  ]
}
```

---

### `GET /api/leave/company` 🟡 HR

**Response** `200` – `Page<HrLeaveResponse>`:
```json
{
  "content": [
    {
      "...": "Tất cả trường của ManagerLeaveResponse",
      "totalAnnualLeaveDays": 12,
      "usedLeaveDays": 5,
      "remainingAnnualLeaveDays": 7,
      "requestorEmail": "d.pt@company.com",
      "requestorPhoneNumber": "0901234567"
    }
  ]
}
```

---

### `PATCH /api/leave/{requestId}/handle` 🔵 Manager / 🔴 Executive

**Request Body:**
```json
{
  "status": "accepted | rejected (bắt buộc)",
  "rejectionReason": "Lý do từ chối (tuỳ chọn, bắt buộc nếu rejected)"
}
```

**Response** `200` – Entity `LeaveRequest`

| Error | HTTP | errorCode |
|---|---|---|
| Đơn đã được xử lý | `400` | `ALREADY_PROCESSED_REQUEST` |
| Tự duyệt đơn mình | `403` | `INSUFFICIENT_PERMISSION` |
| Không đủ quyền duyệt | `403` | `INSUFFICIENT_PERMISSION` |
| Không tìm thấy đơn | `404` | `REQUEST_NOT_FOUND` |

---

### `DELETE /api/leave/{requestId}` 🔒

**Response** `200`:
```json
{ "message": "Đơn xin nghỉ phép đã được hủy thành công" }
```

| Error | HTTP | errorCode |
|---|---|---|
| Đơn không phải của mình | `403` | `INSUFFICIENT_PERMISSION` |
| Đơn không còn ở trạng thái pending | `400` | `ALREADY_PROCESSED_REQUEST` |

---

### `GET /api/leave/export` 🟡 HR

**Query Params:** Giống `company` filter

**Response** `200` – File Excel (`.xlsx`)

---

## 8. Tăng ca – `/api/overtime`

### `PUT /api/overtime/{userId}` 🔒

> Chấm công OT (clock in / clock out). Tự động xác định lượt.

**Response** `200`:
```json
{
  "action": "CLOCK_IN",
  "msg": "OT Clock-in thành công lúc 17:30"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Không có OT được duyệt hôm nay | `404` | `RECORD_NOT_FOUND` |
| OT chưa đủ 1 giờ khi clock-out | `400` | `INSUFFICIENT_OT_TIME` |

---

### `POST /api/overtime` 🔒

**Request Body:**
```json
{
  "approvedStartTime": "2024-09-10T17:30 (bắt buộc)",
  "approvedEndTime": "2024-09-10T21:00 (bắt buộc)",
  "reason": "Hoàn thành sprint deadline"
}
```

> Format DateTime: `yyyy-MM-dd'T'HH:mm`

**Response** `201` – Entity `OvertimeRecord`

| Error | HTTP | errorCode |
|---|---|---|
| Thời gian đã qua | `400` | `INVALID_TIME` |
| Dưới 1 giờ | `400` | `INSUFFICIENT_TIME` |
| Vượt 12h/đơn | `400` | `EXCEED_MAXIMUM_OVERTIME` |
| Không đủ 12h nghỉ giữa ca | `400` | `INSUFFICIENT_REST` |
| Trùng giờ làm chính | `400` | `OVERLAP_WORK_HOURS` |
| Vượt 40h/tháng | `400` | `EXCEED_MONTHLY_OVERTIME` |
| Vượt 200h/năm | `400` | `EXCEED_YEARLY_OVERTIME` |
| Nhân viên chưa có ca làm việc | `400` | `USER_NO_SHIFT` |

---

### `GET /api/overtime/my-records` 🔒

**Query Params:**

| Param | Kiểu | Mô tả |
|---|---|---|
| `status` | `String` | Lọc theo trạng thái |
| `fromDate`, `toDate` | `LocalDate` | Khoảng ngày |
| `keyword` | `String` | Tìm kiếm |
| `page`, `size` | `int` | Phân trang |

**Response** `200` – `Page<StaffOvertimeResponse>`:
```json
{
  "content": [
    {
      "overtimeRecordId": "uuid",
      "approvedDate": "2024-09-10",
      "approvedStartTime": "2024-09-10T17:30:00",
      "approvedEndTime": "2024-09-10T21:00:00",
      "clockInTime": "2024-09-10T17:32:00",
      "clockOutTime": "2024-09-10T20:58:00",
      "isHoliday": false,
      "isWeekend": false,
      "isNightTime": false,
      "status": "accepted",
      "reason": "Sprint deadline",
      "rejectionReason": null,
      "approverId": "uuid",
      "approverName": "Nguyễn Trưởng Phòng",
      "approverJob": "Department Head of Engineering"
    }
  ]
}
```

---

### `GET /api/overtime/approvals` 🔵 Manager / 🔴 Executive

**Response** `200` – `Page<ManagerOvertimeResponse>`:
```json
{
  "content": [
    {
      "...": "Tất cả trường StaffOvertimeResponse",
      "requestorId": "uuid",
      "requestorCode": "NV003",
      "requestorName": "Lê Văn C",
      "requestorDepartment": "Engineering",
      "requestorJob": "Developer",
      "requestorProfilePicUrl": "https://..."
    }
  ]
}
```

---

### `GET /api/overtime/company` 🟡 HR

**Response** `200` – `Page<HrOvertimeResponse>`:
```json
{
  "content": [
    {
      "...": "Tất cả trường ManagerOvertimeResponse",
      "requestorEmail": "c.lv@company.com",
      "requestorPhoneNumber": "0901234567",
      "totalApprovedHours": 3.5,
      "totalActualHours": 3.43
    }
  ]
}
```

---

### `GET /api/overtime/export` 🟡 HR

**Response** `200` – File Excel (`.xlsx`)

---

### `PATCH /api/overtime/{overtimeRecordId}/handle` 🔵 Manager / 🔴 Executive

**Request Body:**
```json
{
  "status": "accepted | rejected (bắt buộc)",
  "rejectionReason": "Lý do từ chối (tuỳ chọn)"
}
```

**Response** `200` – Entity `OvertimeRecord`

| Error | HTTP | errorCode |
|---|---|---|
| Đơn đã xử lý | `400` | `ALREADY_PROCESSED_REQUEST` |
| Tự duyệt | `403` | `INSUFFICIENT_PERMISSION` |
| Không đủ quyền | `403` | `INSUFFICIENT_PERMISSION` |
| Không tìm thấy | `404` | `RECORD_NOT_FOUND` |

---

## 9. Lương – `/api/payrolls`

### `GET /api/payrolls/me` 🔒

**Query Params:**

| Param | Kiểu | Mô tả |
|---|---|---|
| `month` | `Integer` | Tháng |
| `year` | `Integer` | Năm |
| `status` | `PayrollStatus` | Lọc theo trạng thái |
| `page`, `size` | `int` | Phân trang |

**Response** `200` – `Page<StaffPayrollResponse>`:
```json
{
  "content": [
    {
      "payrollId": "uuid",
      "periodMonth": 9,
      "periodYear": 2024,
      "baseSalary": 15000000.00,
      "hourlyRate": 85227.27,
      "standardWorkingDays": 22,
      "actualWorkedDays": 21.0,
      "actualWorkHours": 168.0,
      "paidOvertimeHours": 5.25,
      "basicPay": 14318181.82,
      "overtimePay": 447443.18,
      "allowancePay": 500000.00,
      "bonusPay": 0.00,
      "grossPay": 15265625.00,
      "insuranceDeduction": 1575000.00,
      "taxDeduction": 527031.25,
      "otherDeduction": 0.00,
      "totalDeduction": 2102031.25,
      "netPay": 13163593.75,
      "status": "APPROVED",
      "note": null,
      "calculatedAt": "2024-10-01T09:00:00",
      "paidAt": null
    }
  ]
}
```

---

### `GET /api/payrolls/me/export` 🔒

**Response** `200` – File Excel (`.xlsx`)

---

### `GET /api/payrolls/company` 💰 Accounting / 🔴 Executive

**Query Params:**

| Param | Kiểu | Mô tả |
|---|---|---|
| `periodMonth` | `Integer` | Tháng |
| `periodYear` | `Integer` | Năm |
| `status` | `PayrollStatus` | Lọc theo trạng thái |
| `keyword` | `String` | Tìm kiếm tên/mã NV |
| `departmentNames` | `List<String>` | Lọc theo phòng ban |
| `page`, `size` | `int` | Phân trang |

**Response** `200` – `Page<CompanyPayrollResponse>`:
```json
{
  "content": [
    {
      "...": "Tất cả trường StaffPayrollResponse",
      "userId": "uuid",
      "employeeCode": "NV002",
      "fullName": "Trần Thị B",
      "department": "Engineering",
      "job": "Senior Developer",
      "approvedAt": "2024-10-05T14:00:00"
    }
  ]
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Không đủ quyền | `403` | `INSUFFICIENT_PERMISSION` |

---

### `GET /api/payrolls/company/export` 💰 Accounting / 🔴 Executive

**Response** `200` – File Excel (`.xlsx`)

---

### `GET /api/payrolls/summary` 💰 Accounting / 🔴 Executive

**Query Params:** `month` (int, bắt buộc), `year` (int, bắt buộc)

**Response** `200` – `MonthlyPayrollSummaryResponse`:
```json
{
  "summaryId": "uuid",
  "periodMonth": 9,
  "periodYear": 2024,
  "totalEmployees": 45,
  "totalGrossPay": 687453125.00,
  "totalNetPay": 592678906.25,
  "totalBasicPay": 641818181.82,
  "totalOvertimePay": 20134943.18,
  "totalBonusPay": 0.00,
  "totalAllowancePay": 25500000.00,
  "totalPersonalIncomeTax": 23723906.25,
  "totalEmployeeInsurance": 71050312.50,
  "totalCompanyInsurance": 147932421.88,
  "totalUnionFee": 13749062.50,
  "totalCompanyCost": 849134609.38,
  "status": "APPROVED",
  "approvedBy": "uuid",
  "approvedAt": "2024-10-05T14:00:00",
  "createdAt": "2024-10-01T09:00:00"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Chưa có dữ liệu tháng đó | `404` | `SUMMARY_NOT_FOUND` |

---

### `POST /api/payrolls/generate` 💰 Accounting / 🔴 Executive

**Query Params:** `month` (int), `year` (int)

**Response** `200`:
```json
{
  "msg": "Tính toán bảng lương tháng 9/2024 thành công",
  "calculatedCount": 45,
  "status": "DRAFT"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Bảng công chưa LOCKED | `400` | `TIMESHEET_NOT_LOCKED` |
| Đã APPROVED hoặc PAID | `400` | `PAYROLL_ALREADY_APPROVED` |

---

### `PUT /api/payrolls/{payrollId}` 💰 Accounting / 🔴 Executive

**Request Body:**
```json
{
  "allowancePay": 500000.00,
  "bonusPay": 1000000.00,
  "otherDeduction": 0.00,
  "taxDeduction": null,
  "note": "Thưởng dự án Q3"
}
```

> `taxDeduction = null` → hệ thống tự tính lại thuế TNCN. Truyền giá trị > 0 để ghi đè thủ công.

**Response** `200` – `CompanyPayrollResponse`

| Error | HTTP | errorCode |
|---|---|---|
| Không ở trạng thái DRAFT | `400` | `PAYROLL_ALREADY_APPROVED` |
| Không đủ quyền | `403` | `INSUFFICIENT_PERMISSION` |

---

### `PUT /api/payrolls/approve` 💰💰 Chief Accountant / 🔴 Executive

**Query Params:** `month` (int), `year` (int)

**Response** `200`:
```json
{
  "msg": "Phê duyệt bảng lương tháng 9/2024 thành công",
  "approvedCount": 45,
  "status": "APPROVED"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Đã chi trả rồi | `400` | `PAYROLL_ALREADY_PAID` |
| Không đủ quyền | `403` | `INSUFFICIENT_PERMISSION` |

---

### `PUT /api/payrolls/pay` 💰 Accounting / 🔴 Executive

**Query Params:** `month` (int), `year` (int)

**Response** `200`:
```json
{
  "msg": "Xác nhận chi trả bảng lương tháng 9/2024 thành công",
  "paidCount": 45,
  "status": "PAID"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Chưa được APPROVED | `400` | `INSUFFICIENT_PERMISSION` |

---

## 10. Thôi việc – `/api/resignations`

### `POST /api/resignations` 🔒

**Request Body:**
```json
{
  "lastWorkingDate": "2024-11-15 (bắt buộc, phải là ngày tương lai)",
  "reason": "Tìm kiếm cơ hội mới (bắt buộc, tối đa 500 ký tự)"
}
```

> Thời hạn báo trước tối thiểu: Indefinite ≥ **45 ngày** · Fixed-term ≥ **30 ngày** · Probation ≥ **3 ngày**

**Response** `201` – `ResignationResponse`:
```json
{
  "resignationId": "uuid",
  "userId": "uuid",
  "employeeCode": "NV005",
  "employeeName": "Phạm Thị D",
  "departmentName": "Engineering",
  "jobTitle": "Developer",
  "profilePicUrl": "https://...",
  "joinedDate": "2022-03-01",
  "contractType": "Indefinite",
  "submittedTime": "2024-09-12T10:00:00",
  "lastWorkingDate": "2024-11-15",
  "reason": "Tìm kiếm cơ hội mới",
  "status": "PENDING",
  "managerId": null,
  "managerName": null,
  "managerComment": null,
  "managerApprovedAt": null,
  "executiveId": null,
  "executiveName": null,
  "executiveComment": null,
  "executiveApprovedAt": null,
  "createdAt": "2024-09-12T10:00:00",
  "updatedAt": "2024-09-12T10:00:00"
}
```

| Error | HTTP | errorCode |
|---|---|---|
| Đang có đơn chưa hoàn tất | `400` | `ACTIVE_REQUEST_EXISTS` |
| Không đủ thời hạn báo trước | `400` | `INVALID_NOTICE_PERIOD` |
| `lastWorkingDate` là quá khứ | `400` | `VALIDATION_FAILED` |
| Không tìm thấy hợp đồng | `404` | `CONTRACT_NOT_FOUND` |

---

### `PUT /api/resignations/transfer` 🔵 Manager (cùng phòng) / 🔴 Executive

**Request Body:**
```json
{
  "resignationId": "uuid (bắt buộc)",
  "status": "MANAGER_APPROVED | MANAGER_REJECTED (bắt buộc)",
  "managerComment": "Đã sắp xếp bàn giao xong (tuỳ chọn, tối đa 500 ký tự)"
}
```

**Response** `200`:
```json
{ "message": "Duyệt bàn giao đơn thôi việc thành công" }
```

| Error | HTTP | errorCode |
|---|---|---|
| Đơn không ở trạng thái PENDING | `400` | `INVALID_STATUS_TRANSITION` |
| Tự duyệt | `403` | `SELF_APPROVAL_NOT_ALLOWED` |
| Không phải trưởng phòng của người nộp | `403` | `UNAUTHORIZED_ACTION` |

---

### `PUT /api/resignations/approve` 🟡 HR / 🔴 Executive

**Request Body:**
```json
{
  "resignationId": "uuid (bắt buộc)",
  "status": "APPROVED | REJECTED (bắt buộc)",
  "executiveComment": "Chấp thuận đơn thôi việc (tuỳ chọn, tối đa 500 ký tự)"
}
```

**Response** `200`:
```json
{ "message": "Phê duyệt chính thức đơn thôi việc thành công" }
```

> Nếu `APPROVED` và `lastWorkingDate` đã qua → status tự chuyển thành `COMPLETED` và tài khoản bị khóa ngay.

| Error | HTTP | errorCode |
|---|---|---|
| Chưa qua bước Cấp 1 | `400` | `INVALID_STATUS_TRANSITION` |
| Tự duyệt | `403` | `SELF_APPROVAL_NOT_ALLOWED` |
| Không phải HR/BGĐ | `403` | `UNAUTHORIZED_ACTION` |

---

### `GET /api/resignations/my-requests` 🔒

**Query Params:** `page`, `size`

**Response** `200` – `Page<ResignationResponse>`

---

### `GET /api/resignations/approvals` 🔵 Manager / 🟡 HR / 🔴 Executive

**Query Params:** `page`, `size`

**Response** `200` – `Page<ResignationResponse>`

> Trưởng phòng thấy đơn **PENDING** của nhân viên trong phòng. HR/BGĐ thấy đơn **MANAGER_APPROVED** (hoặc PENDING của các Trưởng phòng).

---

### `GET /api/resignations/company` 🟡 HR / 🔴 Executive

**Query Params:** `status` (ResignationStatus, tuỳ chọn), `page`, `size`

**Response** `200` – `Page<ResignationResponse>`

| Error | HTTP | errorCode |
|---|---|---|
| Không phải HR/BGĐ | `403` | `UNAUTHORIZED_ACTION` |

---

### `PATCH /api/resignations/{resignationId}/cancel` 🔒

**Response** `200`:
```json
{ "message": "Đã hủy đơn xin thôi việc thành công" }
```

| Error | HTTP | errorCode |
|---|---|---|
| Đơn không phải của mình | `403` | `UNAUTHORIZED_ACTION` |
| Đơn không còn ở PENDING | `400` | `INVALID_STATUS_TRANSITION` |

---

## 11. Dashboard – `/api/dashboard`

### `GET /api/dashboard/summary` 🔒

**Response** `200` – `DashboardSummaryResponse`

> Nội dung tự động điều chỉnh theo vai trò: nhân viên thường thấy dữ liệu cá nhân, Manager thấy thêm số liệu phòng ban, HR/BGĐ thấy tổng quan toàn công ty.

---

## 12. Data Seeder – `/api/seeder` ⚠️ Dev only

### `POST /api/seeder/mock-data`

**Query Params:**

| Param | Kiểu | Default | Mô tả |
|---|---|---|---|
| `year` | `int` | `2026` | Năm tạo dữ liệu |
| `fromMonth` | `int` | `1` | Tháng bắt đầu |
| `toMonth` | `int` | `8` | Tháng kết thúc |
| `clearExisting` | `boolean` | `true` | Xóa dữ liệu cũ trước |
| `autoGenerateTimesheets` | `boolean` | `true` | Tự tổng hợp bảng công |

**Response** `200`:
```json
{
  "status": "success",
  "employeesCreated": 50,
  "attendancesCreated": 8500,
  "timesheetsGenerated": 400
}
```

---

## Sơ đồ các luồng nghiệp vụ chính

### Luồng phê duyệt đơn thôi việc (2 cấp)

```
Nhân viên nộp đơn (PENDING)
         │
         ▼
Trưởng phòng duyệt Cấp 1
   ├─ MANAGER_APPROVED ─────────────────────────────────────┐
   └─ MANAGER_REJECTED → kết thúc                          │
                                                            ▼
                                         HR / Ban Giám Đốc phê duyệt Cấp 2
                                           ├─ APPROVED → COMPLETED + khóa TK (nếu ngày đã qua)
                                           └─ REJECTED → kết thúc
```

### Luồng tính lương hàng tháng

```
[HR / BGĐ]         Tổng hợp bảng công    → MonthlyTimesheet: DRAFT
[HR / BGĐ]         Điều chỉnh chi tiết   → MonthlyTimesheet: DRAFT  (chỉnh sửa tuỳ ý)
[HR Head / BGĐ]    Chốt sổ bảng công     → MonthlyTimesheet: LOCKED (không sửa được nữa)
[Kế toán]          Tính lương tự động    → Payroll: DRAFT
[Kế toán]          Điều chỉnh phụ cấp   → Payroll: DRAFT
[KT Trưởng / BGĐ]  Phê duyệt bảng lương → Payroll: APPROVED
[Kế toán]          Xác nhận chi trả     → Payroll: PAID
```

### Luồng xử lý đơn nghỉ phép / tăng ca

```
Nhân viên tạo đơn (pending)
         │
         ▼
Trưởng phòng cùng phòng hoặc Ban Giám Đốc xử lý
   ├─ accepted → Tự động cập nhật chấm công + trừ phép năm (nghỉ phép)
   └─ rejected → Kết thúc
```

---

## 13. Request Body – HR Employee Update Endpoints

> Tất cả trường trong các endpoint cập nhật hồ sơ đều là **tuỳ chọn** (partial update). Chỉ cần gửi những trường muốn thay đổi.

### `PUT /api/employees/{userId}/basic-info` – `UpdateBasicInfoRequest`

```json
{
  "firstName": "Văn An",
  "lastName": "Nguyễn",
  "gender": "Male | Female | Other",
  "birthDate": "1995-05-20",
  "profilePicUrl": "https://...",
  "phoneNumber": "0901234567"
}
```

---

### `PUT /api/employees/{userId}/legal-profile` – `UpdateLegalProfileRequest`

```json
{
  "citizenIdNumber": "012345678901",
  "taxIdentificationNumber": "1234567890",
  "socialInsuranceNumber": "SN123456",
  "socialInsuranceStartDate": "2022-01-01",
  "personalEmail": "an@gmail.com",
  "placeOfBirth": "Hà Nội",
  "maritalStatus": "Single | Married | Divorced | Widowed",
  "nationality": "Vietnamese",
  "emergencyContactName": "Nguyễn Văn B",
  "emergencyContactPhone": "0987654321"
}
```

---

### `PUT /api/employees/{userId}/profile` – `UpdateProfileRequest`

> Endpoint gộp, cập nhật cả thông tin cơ bản lẫn pháp lý trong một request.

```json
{
  "firstName": "Văn An",
  "lastName": "Nguyễn",
  "gender": "Male",
  "birthDate": "1995-05-20",
  "profilePicUrl": "https://...",
  "phoneNumber": "0901234567",
  "personalEmail": "an@gmail.com",
  "placeOfBirth": "Hà Nội",
  "maritalStatus": "Single",
  "nationality": "Vietnamese",
  "citizenIdNumber": "012345678901",
  "socialInsuranceNumber": "SN123456",
  "socialInsuranceStartDate": "2022-01-01",
  "taxIdentificationNumber": "1234567890",
  "emergencyContactName": "Nguyễn Văn B",
  "emergencyContactPhone": "0987654321"
}
```

---

### `PUT /api/employees/{userId}/contract` – `UpdateContractRequest`

```json
{
  "contractType": "Indefinite | Fixed-term | Probation",
  "contractStartDate": "2024-01-01",
  "contractEndDate": "2026-01-01"
}
```

> `contractEndDate` có thể là `null` nếu là hợp đồng không xác định thời hạn (`Indefinite`).

---

### `PUT /api/employees/{userId}/payroll` – `UpdatePayrollRequest`

```json
{
  "baseSalary": 15000000,
  "payFrequency": "MONTHLY | WEEKLY | HOURLY",
  "workDays": 22.0,
  "startDate": "2024-01-01",
  "endDate": null,
  "isActive": true,
  "bankName": "Vietcombank",
  "bankAccountNumber": "1234567890123"
}
```

---

### `PUT /api/employees/{userId}/assignment` – `UpdateAssignmentRequest`

```json
{
  "departmentId": "uuid",
  "jobId": "uuid",
  "shiftId": "uuid"
}
```

---

### `PATCH /api/employees/{userId}/status` – `UpdateEmployeeStatusRequest`

```json
{
  "isActive": false,
  "reason": "Nhân viên đã nghỉ việc chính thức ngày 01/10/2024"
}
```

> `isActive` **bắt buộc**. `reason` tuỳ chọn.

---

## 14. Hạ tầng & Bảo mật

### Authentication Flow

```
Client                              Server
  │                                   │
  │──── POST /auth/login ─────────────▶│
  │                                   │ Xác thực email + password
  │◀─── accessToken (15 phút) ────────│
  │◀─── refreshToken cookie (7 ngày) ─│
  │                                   │
  │── API call với Bearer accessToken ▶│
  │◀── Data ──────────────────────────│
  │                                   │
  │  (accessToken hết hạn sau 15 phút)│
  │                                   │
  │──── POST /auth/auto-login ────────▶│  (cookie refreshToken tự gửi)
  │◀─── accessToken mới (15 phút) ────│
  │◀─── refreshToken cookie mới ──────│
```

### JWT Token

| Loại | Thời hạn | Lưu trữ | Ghi chú |
|---|---|---|---|
| **Access Token** | **15 phút** | Memory / `Authorization` header | Dùng để gọi API |
| **Refresh Token** | **7 ngày** | Cookie `HttpOnly` | Dùng để làm mới Access Token |

**Access Token payload** (JWT claims):
```json
{
  "sub": "userId (UUID)",
  "sessionId": "UUID",
  "deviceId": "UUID",
  "email": "user@company.com",
  "fullName": "Nguyễn Văn An",
  "profilePicUrl": "https://...",
  "department": "Human Resources",
  "job": "HR Specialist",
  "iat": 1726123456,
  "exp": 1726124356
}
```

**Thuật toán ký:** `HS256`

---

### CORS

| Mục | Giá trị |
|---|---|
| **Allowed Origins** | `http://localhost:*` · `http://127.0.0.1:*` · `https://*.trycloudflare.com` |
| **Allowed Methods** | `GET, POST, PUT, DELETE, PATCH, OPTIONS` |
| **Allowed Headers** | `*` (tất cả) |
| **Allow Credentials** | `true` (bắt buộc để gửi cookie) |
| **Exposed Headers** | `Set-Cookie, Retry-After, X-RateLimit-Limit, X-RateLimit-Remaining` |
| **Max Age (preflight)** | 3600 giây |

> ⚠️ Khi gọi API từ browser, phải set `credentials: "include"` (fetch) hoặc `withCredentials: true` (axios) để cookie `refreshToken` được gửi kèm.

---

### Rate Limiting

Hệ thống sử dụng Redis để giới hạn tần suất request theo IP.

| Nhóm endpoint | Giới hạn | Cửa sổ thời gian |
|---|---|---|
| `/auth/*` | **30 request** | 60 giây |
| Tất cả các route khác | Không giới hạn thực tế | — |

**Response khi bị rate limit** (`HTTP 429 Too Many Requests`):
```json
{
  "errorCode": "TOO_MANY_REQUESTS",
  "message": "Quá nhiều yêu cầu. Vui lòng thử lại sau 45 giây.",
  "retryAfterSeconds": 45
}
```

**Response headers kèm theo mọi request:**
```
X-RateLimit-Limit: 30
X-RateLimit-Remaining: 27
Retry-After: 45   (chỉ xuất hiện khi bị block)
```

---

### File Upload (Avatar)

| Mục | Giá trị |
|---|---|
| **Endpoint** | `POST /api/employees/me/avatar` · `POST /api/employees/{id}/avatar` |
| **Content-Type** | `multipart/form-data` |
| **Field name** | `file` |
| **Định dạng cho phép** | JPG, PNG, WebP, GIF và các định dạng ảnh phổ biến |
| **Xử lý server-side** | Tự động nén & chuyển đổi sang **WebP 500×500px** |
| **Đường dẫn lưu trữ** | `./uploads/avatars/<uuid>.webp` |
| **URL trả về** | `/uploads/avatars/<uuid>.webp` (serve tĩnh) |

---

### Hạ tầng phụ trợ

| Thành phần | Vai trò |
|---|---|
| **PostgreSQL** | Database chính |
| **Redis** | Session blacklist + Rate limiting |
| **File system** | Lưu trữ avatar (`./uploads/`) |

---

## 15. Tổng hợp Business Rules

### Chấm công & Ca làm việc

| Rule | Giá trị |
|---|---|
| Giờ tối đa / ngày (work shift) | ≤ **8 giờ** |
| Giờ tối đa / tuần (work shift) | ≤ **48 giờ** |
| Bảng công có thể sửa khi | `TimesheetStatus = DRAFT` |
| Bảng công bị khoá khi | `TimesheetStatus = LOCKED` – không thể thêm/sửa/xóa bản ghi chấm công |

### Tăng ca (Overtime)

| Rule | Giá trị |
|---|---|
| OT tối thiểu / đơn | ≥ **1 giờ** |
| OT tối đa / đơn | ≤ **12 giờ** |
| OT tối đa / tháng | ≤ **40 giờ** |
| OT tối đa / năm | ≤ **200 giờ** |
| Thời gian nghỉ tối thiểu giữa 2 ca (kể cả OT) | ≥ **12 giờ** |
| OT không được trùng giờ làm chính | ✅ Kiểm tra tự động |

### Nghỉ phép

| Rule | Giá trị |
|---|---|
| Số ngày nghỉ tối đa / đơn | ≤ **14 ngày lịch** |
| Phép năm mặc định | Theo cấu hình khi tạo tài khoản (`annualLeaveDays`) |
| Chairman không được xin nghỉ | ✅ Bị chặn bởi `CHAIRMAN_CANNOT_LEAVE` |
| Không được xin nghỉ trùng đơn đang active | ✅ Kiểm tra `OVERLAPPING_LEAVE_REQUEST` |
| Phạm vi ngày cho phép | Từ 1 đến tối đa 14 ngày lịch |

### Thôi việc – Thời hạn báo trước tối thiểu

| Loại hợp đồng | Thời hạn tối thiểu |
|---|---|
| `Indefinite` (Không xác định thời hạn) | ≥ **45 ngày** |
| `Fixed-term` (Xác định thời hạn) | ≥ **30 ngày** |
| `Probation` (Thử việc) | ≥ **3 ngày** |

### Lương – Tỷ lệ bảo hiểm & thuế

| Khoản mục | Tỷ lệ | Bên chịu |
|---|---|---|
| Bảo hiểm xã hội (BHXH) | 8% | Người lao động |
| Bảo hiểm y tế (BHYT) | 1.5% | Người lao động |
| Bảo hiểm thất nghiệp (BHTN) | 1% | Người lao động |
| **Tổng khấu trừ NLĐ** | **10.5%** | Người lao động |
| BHXH (công ty đóng) | 17.5% | Công ty |
| BHYT (công ty đóng) | 3% | Công ty |
| BHTN (công ty đóng) | 1% | Công ty |
| **Tổng công ty đóng** | **21.5%** | Công ty |
| Kinh phí công đoàn | 2% | Công ty |
| Thuế TNCN | Lũy tiến 7 bậc | Người lao động |

**7 bậc thuế TNCN (tính trên thu nhập tính thuế):**

| Bậc | Thu nhập / tháng | Thuế suất |
|---|---|---|
| 1 | ≤ 5 triệu | 5% |
| 2 | 5 – 10 triệu | 10% |
| 3 | 10 – 18 triệu | 15% |
| 4 | 18 – 32 triệu | 20% |
| 5 | 32 – 52 triệu | 25% |
| 6 | 52 – 80 triệu | 30% |
| 7 | > 80 triệu | 35% |

> Thu nhập tính thuế = Gross Pay − Bảo hiểm NLĐ − Giảm trừ gia cảnh (11 triệu/tháng cá nhân + 4.4 triệu/người phụ thuộc)

### Quy trình phê duyệt & trạng thái đơn

| Loại đơn | Người duyệt Cấp 1 | Người duyệt Cấp 2 | Ghi chú |
|---|---|---|---|
| Nghỉ phép | Trưởng phòng cùng phòng hoặc BGĐ | — | 1 cấp duyệt |
| Tăng ca | Trưởng phòng cùng phòng hoặc BGĐ | — | 1 cấp duyệt |
| Thôi việc | Trưởng phòng cùng phòng hoặc BGĐ | HR hoặc BGĐ | 2 cấp duyệt |
| Bảng lương | Kế toán (tính toán + điều chỉnh) | KT Trưởng hoặc BGĐ (approve) | 2 bước xử lý |

> **Quy tắc chung:** Không ai được tự phê duyệt đơn của chính mình (`SELF_APPROVAL_NOT_ALLOWED`).

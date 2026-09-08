import { AttendanceRecord, MonthlyTimesheetSummary } from '@/types';
import { MOCK_USERS } from './users';

export const MOCK_ATTENDANCES: AttendanceRecord[] = [
  // Hôm nay (2026-09-04)
  {
    attendanceId: 'att-today-001',
    userId: '11111111-1111-1111-1111-111111111111',
    userName: 'Nguyễn Minh Đức',
    employeeCode: 'EXEC001',
    department: 'Executive Leadership',
    job: 'Chairman',
    workDate: '2026-09-04',
    clockInTime: '08:15:20',
    clockOutTime: '17:35:10',
    status: 'SUFFICIENT',
    faceRecognitionVerified: true,
    faceConfidence: 99.4,
    deviceLocation: 'Cổng VIP - AI FaceCam 01'
  },
  {
    attendanceId: 'att-today-002',
    userId: '66666666-6666-6666-6666-666666666666',
    userName: 'Phạm Thị Cúc',
    employeeCode: 'HR001',
    department: 'Human Resources',
    job: 'Department Head of Human Resources',
    workDate: '2026-09-04',
    clockInTime: '08:24:12',
    clockOutTime: '17:40:00',
    status: 'SUFFICIENT',
    faceRecognitionVerified: true,
    faceConfidence: 98.7,
    deviceLocation: 'Cửa chính Tầng 3 - AI FaceCam 02'
  },
  {
    attendanceId: 'att-today-003',
    userId: '99999999-9999-9999-9999-999999999999',
    userName: 'Đỗ Văn Hùng',
    employeeCode: 'IT001',
    department: 'Information Technology',
    job: 'Department Head of IT',
    workDate: '2026-09-04',
    clockInTime: '08:55:40',
    clockOutTime: undefined,
    status: 'WORKING',
    faceRecognitionVerified: true,
    faceConfidence: 97.9,
    deviceLocation: 'Khu Kỹ Thuật IT - AI FaceCam 04'
  },
  {
    attendanceId: 'att-today-004',
    userId: '00000000-0000-0000-0000-000000000001',
    userName: 'Nguyễn Hoàng',
    employeeCode: 'IT002',
    department: 'Information Technology',
    job: 'Software Engineer',
    workDate: '2026-09-04',
    clockInTime: '09:12:05', // Đi trễ 12 phút
    clockOutTime: undefined,
    status: 'LATE',
    faceRecognitionVerified: true,
    faceConfidence: 99.1,
    deviceLocation: 'Khu Kỹ Thuật IT - AI FaceCam 04'
  },
  {
    attendanceId: 'att-today-005',
    userId: '44444444-4444-4444-4444-444444444444',
    userName: 'Trần Văn An',
    employeeCode: 'SALES001',
    department: 'Sales & Marketing',
    job: 'Department Head of Sales',
    workDate: '2026-09-04',
    clockInTime: '08:20:00',
    clockOutTime: undefined,
    status: 'WORKING',
    faceRecognitionVerified: true,
    faceConfidence: 98.2,
    deviceLocation: 'Sảnh Kinh Doanh - AI FaceCam 03'
  },
  {
    attendanceId: 'att-today-006',
    userId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    userName: 'Lê Tuấn',
    employeeCode: 'SALES002',
    department: 'Sales & Marketing',
    job: 'Sales Executive Staff',
    workDate: '2026-09-04',
    clockInTime: '08:28:10',
    clockOutTime: '16:45:00', // Về sớm
    status: 'EARLY',
    faceRecognitionVerified: true,
    faceConfidence: 98.0,
    deviceLocation: 'Sảnh Kinh Doanh - AI FaceCam 03'
  },
  {
    attendanceId: 'att-today-007',
    userId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
    userName: 'Phan Minh Tuấn',
    employeeCode: 'HR003',
    department: 'Human Resources',
    job: 'HR Generalist',
    workDate: '2026-09-04',
    clockInTime: '08:30:00',
    clockOutTime: '17:30:00',
    status: 'ADJUSTED',
    isEdited: true,
    editedReason: 'Lỗi nhận diện góc tối máy quét khuôn mặt, Trưởng phòng xác nhận bổ sung',
    editorName: 'Phạm Thị Cúc',
    editorEmpCode: 'HR001',
    deviceLocation: 'Cửa chính Tầng 3 - AI FaceCam 02'
  },

  // Hôm qua (2026-09-03 - Ngày nghỉ liền kề Quốc Khánh)
  {
    attendanceId: 'att-yesterday-001',
    userId: '00000000-0000-0000-0000-000000000001',
    userName: 'Nguyễn Hoàng',
    employeeCode: 'IT002',
    department: 'Information Technology',
    job: 'Software Engineer',
    workDate: '2026-09-03',
    clockInTime: undefined,
    clockOutTime: undefined,
    status: 'HOLIDAY'
  },
  {
    attendanceId: 'att-yesterday-002',
    userId: '66666666-6666-6666-6666-666666666666',
    userName: 'Phạm Thị Cúc',
    employeeCode: 'HR001',
    department: 'Human Resources',
    job: 'Department Head of Human Resources',
    workDate: '2026-09-03',
    clockInTime: undefined,
    clockOutTime: undefined,
    status: 'HOLIDAY'
  },

  // Ngày 2026-09-01 (Ngày làm việc bình thường)
  {
    attendanceId: 'att-sep01-001',
    userId: '00000000-0000-0000-0000-000000000001',
    userName: 'Nguyễn Hoàng',
    employeeCode: 'IT002',
    department: 'Information Technology',
    job: 'Software Engineer',
    workDate: '2026-09-01',
    clockInTime: '08:58:30',
    clockOutTime: '18:02:15',
    status: 'SUFFICIENT',
    faceRecognitionVerified: true,
    faceConfidence: 99.3,
    deviceLocation: 'Khu Kỹ Thuật IT - AI FaceCam 04'
  },
  {
    attendanceId: 'att-sep01-002',
    userId: '66666666-6666-6666-6666-666666666666',
    userName: 'Phạm Thị Cúc',
    employeeCode: 'HR001',
    department: 'Human Resources',
    job: 'Department Head of Human Resources',
    workDate: '2026-09-01',
    clockInTime: '08:26:00',
    clockOutTime: '17:35:00',
    status: 'SUFFICIENT',
    faceRecognitionVerified: true,
    faceConfidence: 98.9,
    deviceLocation: 'Cửa chính Tầng 3 - AI FaceCam 02'
  }
];

// Bảng tổng hợp công tháng (Monthly Timesheet Summary)
export const MOCK_MONTHLY_SUMMARIES: MonthlyTimesheetSummary[] = MOCK_USERS.map((user, idx) => ({
  userId: user.userId,
  employeeCode: user.employeeCode,
  fullName: user.fullName,
  department: user.department,
  job: user.job,
  month: 9,
  year: 2026,
  standardWorkingDays: 22,
  actualWorkedDays: 4 - (idx % 2 === 0 ? 0 : 1),
  lateCount: idx % 3 === 0 ? 1 : 0,
  totalLateMinutes: idx % 3 === 0 ? 12 : 0,
  earlyDepartureCount: idx % 4 === 0 ? 1 : 0,
  absentDays: 0,
  paidLeaveDays: user.usedLeaveDays,
  unpaidLeaveDays: 0,
  remainingAnnualLeaveDays: user.annualLeaveDays - user.usedLeaveDays,
  totalActualHours: 32 + (idx * 1.5),
  totalPaidHours: 32 + (idx * 1.5),
  overtimeHours: (idx % 2 === 0 ? 4 : 0)
}));

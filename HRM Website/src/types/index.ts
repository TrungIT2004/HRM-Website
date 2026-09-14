// ACT HRM Types - Based on Spring Boot DTOs and Database Entities

export type DepartmentName = 
  | 'Executive Leadership'
  | 'Human Resources'
  | 'Information Technology'
  | 'Finance & Accounting'
  | 'Sales & Marketing'
  | 'Customer Support';

export type JobTitle = 
  | 'Chairman'
  | 'Director'
  | 'Deputy Director'
  | 'Department Head of Sales'
  | 'Sales Executive Staff'
  | 'Department Head of Marketing'
  | 'Marketing Specialist'
  | 'Department Head of Human Resources'
  | 'HR Specialist'
  | 'HR Generalist'
  | 'Department Head of Finance'
  | 'Accountant'
  | 'Department Head of Support'
  | 'Support Representative'
  | 'Department Head of IT'
  | 'Software Engineer';

export type RoleLevel = 'EXECUTIVE' | 'HR' | 'MANAGER' | 'STAFF';

export type TodayAttendanceStatus = 'WORKING' | 'ON_LEAVE' | 'NOT_CHECKED' | 'ABSENT';

export interface User {
  userId: string;
  employeeCode: string;
  email: string;
  firstName: string;
  lastName: string;
  fullName: string;
  department: DepartmentName;
  job: JobTitle;
  profilePicUrl?: string;
  todayStatus: TodayAttendanceStatus;
  isActive?: boolean;
  gender?: 'Nam' | 'Nữ' | 'Khác';
  birthDate?: string;
  joinedDate?: string;
  phoneNumber?: string;
  annualLeaveDays: number;
  usedLeaveDays: number;
  shiftName: string;
  shiftStartTime: string;
  shiftEndTime: string;
  restDays: number[]; // 6 = T7, 7 = CN
}

// Attendance Statuses matching Spring Boot AttendanceStatus enum
export type AttendanceStatus = 
  | 'NOT_CHECKED'
  | 'WORKING'
  | 'SUFFICIENT'
  | 'LATE'
  | 'EARLY'
  | 'LATE_AND_EARLY'
  | 'MISSING'
  | 'UNEXCUSED_ABSENCE'
  | 'PAID_LEAVE'
  | 'UNPAID_LEAVE'
  | 'HOLIDAY'
  | 'BUSINESS_TRIP'
  | 'ADJUSTED';

export interface AttendanceRecord {
  attendanceId: string;
  userId: string;
  userName: string;
  fullName?: string;
  employeeCode: string;
  department: DepartmentName;
  job: JobTitle;
  workDate: string; // YYYY-MM-DD
  clockInTime?: string; // HH:mm:ss
  clockOutTime?: string; // HH:mm:ss
  status: AttendanceStatus;
  isEdited?: boolean;
  editedReason?: string;
  editorName?: string;
  editorEmpCode?: string;
  faceRecognitionVerified?: boolean;
  faceConfidence?: number; // e.g. 98.6%
  deviceLocation?: string; // "Cổng chính - AI Camera 01"
}

// Leave Request Status matching Spring Boot LeaveRequestStatus
export type LeaveRequestStatus = 'pending' | 'accepted' | 'rejected';

export interface LeaveRequest {
  requestId: string;
  requestorId: string;
  requestorName: string;
  requestorCode: string;
  requestorDepartment: DepartmentName;
  requestorJob: JobTitle;
  requestorEmail?: string;
  requestorPhone?: string;
  requestorPhoneNumber?: string;
  totalAnnualLeaveDays?: number;
  usedLeaveDays?: number;
  remainingAnnualLeaveDays?: number;
  fromDate: string; // YYYY-MM-DD
  toDate: string; // YYYY-MM-DD
  paidLeaveDays: number;
  totalWorkingDays: number;
  reason: string;
  status: LeaveRequestStatus;
  approverId?: string;
  approverName?: string;
  approverJob?: string;
  rejectionReason?: string;
  createdAt: string;
}

export interface LeavePreviewResult {
  requestedLeaveDays: number;       // Tổng số ngày lịch
  workDays: number;                 // Số ngày làm việc thực tế
  restDays: number;                 // Số ngày nghỉ cuối tuần/ca
  holidayDays: number;              // Số ngày lễ
  annualLeaveDays: number;          // Quỹ phép năm
  usedLeaveDays: number;            // Đã dùng
  remainingAnnualLeaveDays: number; // Còn lại
  remainingAfterThisRequest: number;// Sau khi nghỉ còn
  isSufficientAnnualLeave: boolean; // Đủ phép hay không
  excludedDates?: { date: string; type: 'WEEKEND' | 'HOLIDAY'; label: string }[];
}

// Overtime matching Spring Boot OvertimeRecordStatus and OvertimeType
export type OvertimeStatus = 'pending' | 'accepted' | 'rejected';
export type OvertimeType = 'normal' | 'weekend' | 'holiday';

export interface OvertimeRecord {
  overtimeRecordId: string;
  requestorId: string;
  requestorName: string;
  requestorCode: string;
  requestorDepartment: DepartmentName;
  requestorJob: JobTitle;
  requestorEmail?: string;
  requestorPhoneNumber?: string;
  approvedDate: string; // YYYY-MM-DD
  approvedStartTime: string; // HH:mm
  approvedEndTime: string; // HH:mm
  clockInTime?: string; // HH:mm
  clockOutTime?: string; // HH:mm
  registeredHours: number;
  actualHours?: number;
  totalApprovedHours?: number;
  totalActualHours?: number;
  reason: string;
  status: OvertimeStatus;
  approverId?: string;
  approverName?: string;
  approverJob?: string;
  isHoliday: boolean;
  isWeekend: boolean;
  isNightTime: boolean;
  multiplier: number; // 1.5, 2.0, 3.0
  rejectionReason?: string;
  createdAt: string;
}

// Employee Detailed Profile Data (Spring Boot EmployeeDetailResponse)
export interface UserProfileData {
  phoneNumber: string;
  personalEmail: string;
  placeOfBirth: string;
  maritalStatus: 'Độc thân' | 'Đã kết hôn' | 'Khác';
  nationality: string;
  citizenIdNumber: string;
  socialInsuranceNumber: string;
  taxIdentificationNumber: string;
  socialInsuranceStartDate: string; // YYYY-MM-DD
  emergencyContactName: string;
  emergencyContactPhone: string;
  address?: string;
}

export interface UserBankAccountData {
  bankName: string;
  bankAccountNumber: string;
  accountHolder?: string;
}

export interface UserContractData {
  contractId?: string;
  contractType: 'Indefinite' | 'Fixed-term' | 'Probation' | string;
  contractStartDate: string; // YYYY-MM-DD
  contractEndDate?: string;   // YYYY-MM-DD
  probationEndDate?: string;  // YYYY-MM-DD
  isActive?: boolean;
}

export interface SalaryData {
  salaryId?: string;
  baseSalary: number; // VND
  payFrequency: 'HOURLY' | 'WEEKLY' | 'MONTHLY';
  workDays: number;
  startDate: string;
  endDate?: string;
  isActive: boolean;
}

export interface WorkShiftScheduleItem {
  dayOfWeek: number;      // 2 = T2, 3 = T3, ..., 8 = CN
  dayName: string;        // 'Thứ 2', ...
  isWorking: boolean;
  startTime: string;      // '08:30'
  endTime: string;        // '17:30'
  restStartTime?: string; // '12:00'
  restEndTime?: string;   // '13:00'
}

export interface EmployeeDetailed extends User {
  joinedDate: string; // YYYY-MM-DD
  birthDate: string;  // YYYY-MM-DD
  gender: 'Nam' | 'Nữ' | 'Khác';
  profile: UserProfileData;
  bankAccount: UserBankAccountData;
  contract: UserContractData;
  contracts?: UserContractData[];
  salary: SalaryData;
  weeklySchedule: WorkShiftScheduleItem[];
}

// Monthly Timesheet Summary matching MonthlyTimesheetSummaryResponse
export interface MonthlyTimesheetSummary {
  userId: string;
  employeeCode: string;
  fullName: string;
  department: DepartmentName;
  job: JobTitle;
  month: number;
  year: number;
  standardWorkingDays: number;
  actualWorkedDays: number;
  lateCount: number;
  totalLateMinutes: number;
  earlyDepartureCount: number;
  absentDays: number;
  paidLeaveDays: number;
  unpaidLeaveDays: number;
  remainingAnnualLeaveDays: number;
  totalActualHours: number;
  totalPaidHours: number;
  overtimeHours: number;
}

// Payroll calculation matching Spring Boot Payroll entity & PayrollDTO
export interface PayrollRecord {
  payrollId: string;
  userId: string;
  employeeName: string;
  employeeCode: string;
  department: DepartmentName;
  job: JobTitle;
  periodMonth: number;
  periodYear: number;
  baseSalary: number; // Lương thỏa thuận
  standardDays: number; // Ngày công chuẩn (e.g. 26)
  actualWorkedDays: number; // Ngày làm việc thực tế
  actualWorkHours: number; // Giờ công thực tế
  basicPay: number; // Lương theo ngày công thực tế
  overtimePay: number; // Lương làm thêm giờ
  allowancePay: number; // Phụ cấp ăn trưa, điện thoại...
  deductionPay: number; // Khấu trừ đi muộn, bảo hiểm...
  netPay: number; // Thực nhận = basicPay + overtimePay + allowancePay - deductionPay
  status: 'draft' | 'approved' | 'paid';
  calculatedAt: string;
}

export interface HolidayItem {
  holidayId: string;
  date: string; // YYYY-MM-DD
  description: string;
}

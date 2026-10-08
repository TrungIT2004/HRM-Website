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

export type RoleLevel = 'EXECUTIVE' | 'ADMIN' | 'HR' | 'MANAGER' | 'STAFF';

// Backend trả thẳng attendances.status (EmployeeService), nên phải bao đủ các giá trị
// thực tế — trước đây chỉ liệt 4 giá trị nên "đã đi về" bị rơi vào fallback.
export type TodayAttendanceStatus =
  | 'WORKING'
  | 'ON_LEAVE'
  | 'NOT_CHECKED'
  | 'ABSENT'
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
  | 'ADJUSTED'
  // Không có bản ghi attendances hôm nay = ngày nghỉ (cron chỉ tạo record ngày làm việc)
  | 'DAY_OFF';

/** null = không tăng ca. OVERTIMING = đã quẹt vào OT, chưa quẹt ra. */
export type TodayOvertimeStatus = 'OVERTIMING' | 'OVERTIME_DONE' | 'NONE' | null;

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
  todayOvertimeStatus?: TodayOvertimeStatus;
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
  bankCode?: string;
  accountNumber?: string;
  accountHolderName?: string;
  isDefault?: boolean;
  // Tên cũ giữ lại để không phá call site cũ
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
  // Nguồn chuẩn cho tab Lương & Ngân hàng (backend trả về tài khoản is_default)
  payroll?: {
    baseSalary?: number | null;
    bankName?: string | null;
    bankCode?: string | null;
    bankAccountNumber?: string | null;
    accountHolderName?: string | null;
    isDefaultBank?: boolean;
  };
  weeklySchedule: WorkShiftScheduleItem[];
}

// Monthly Timesheet Summary matching MonthlyTimesheetSummaryResponse
export interface MonthlyTimesheetSummary {
  timesheetId?: string;
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
  // ponytail: backend CompanyMonthlyTimesheetResponse có sẵn — frontend trước đây bỏ qua nên UI không biết tháng chốt chưa
  status?: 'DRAFT' | 'LOCKED' | string;
  lockedAt?: string | null;
  note?: string;
}

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
  hourlyRate?: number; // Lương theo giờ
  standardDays: number; // Ngày công chuẩn (e.g. 26)
  actualWorkedDays: number; // Ngày làm việc thực tế
  actualWorkHours: number; // Giờ công thực tế
  paidOvertimeHours?: number; // Số giờ làm thêm được tính lương
  basicPay: number; // Lương theo ngày công thực tế
  overtimePay: number; // Lương làm thêm giờ
  allowancePay: number; // Phụ cấp ăn trưa, điện thoại...
  bonusPay?: number; // Tiền thưởng
  grossPay?: number; // Tổng thu nhập trước thuế
  insuranceDeduction?: number; // Khấu trừ bảo hiểm
  taxDeduction?: number; // Thuế TNCN
  otherDeduction?: number; // Khấu trừ khác
  deductionPay: number; // Tổng các khoản khấu trừ
  netPay: number; // Thực nhận = basicPay + overtimePay + allowancePay - deductionPay
  status: 'draft' | 'approved' | 'paid';
  note?: string;
  calculatedAt: string;
  approvedAt?: string;
  paidAt?: string;
}

export interface HolidayItem {
  holidayId: string;
  date: string; // YYYY-MM-DD
  description: string;
}

// ─── Tài sản (khớp backend com.minhtrung.hrm.asset) ───
export type AssetStatus = 'available' | 'assigned' | 'under_maintenance' | 'broken' | 'lost' | 'retired';
export type AssetRequestStatus = 'pending' | 'approved' | 'rejected' | 'cancelled' | 'issued' | 'returned';
export type AssignmentStatus = 'active' | 'pending_return' | 'returned' | 'overdue' | 'lost';

export interface AssetCategory {
  categoryId: string;
  name: string;
  codePrefix: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Asset {
  assetId: string;
  assetCode: string;
  name: string;
  categoryId: string;
  serialNumber?: string;
  specs?: string;
  purchaseDate?: string;
  purchaseCost?: number;
  supplier?: string;
  usefulLifeMonths: number;
  warrantyUntil?: string;
  status: AssetStatus;
  conditionNote?: string;
  location?: string;
  currentHolderId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface AssetRequest {
  requestId: string;
  requestorId: string;
  categoryId: string;
  reason: string;
  neededByDate?: string;
  expectedReturnDate?: string;
  status: AssetRequestStatus;
  approverId?: string;
  rejectionReason?: string;
  createdAt: string;
  updatedAt: string;
}

export interface AssetAssignment {
  assignmentId: string;
  assetId: string;
  userId?: string | null;
  departmentId?: string | null;
  scope?: 'PERSONAL' | 'DEPARTMENT';
  requestId?: string;
  assignedAt: string;
  expectedReturnDate?: string;
  returnedAt?: string;
  status: AssignmentStatus;
  conditionOnAssign?: string;
  conditionOnReturn?: string;
  notes?: string;
  createdAt: string;
}

export interface AssetMaintenance {
  maintenanceId: string;
  assetId: string;
  type: string;
  status: string;
  description?: string;
  cost?: number;
  vendor?: string;
  sentAt?: string;
  returnedAt?: string;
  createdAt: string;
}

export interface AssetInventoryLog {
  logId: string;
  assetId: string;
  checkedAt: string;
  found: boolean;
  conditionNote?: string;
}

export interface AssetImage {
  imageId: string;
  assetId: string;
  imageUrl: string;
  caption?: string;
  cover: boolean;
  takenAt: string;
}

export interface AssetTimelineEvent {
  kind: 'created' | 'assign' | 'return' | 'maintenance' | 'inventory';
  at: string;
  actor?: string;
  title: string;
  note?: string;
}

// ─── IT Ticket (khớp backend com.minhtrung.hrm.itticket, V1 không link assets) ───
export type ItTicketCategory = 'LAPTOP_PC' | 'NETWORK' | 'PRINTER' | 'ACCOUNT_EMAIL' | 'SOFTWARE' | 'PERIPHERAL' | 'OTHER';
export type ItTicketStatus = 'OPEN' | 'IN_PROGRESS' | 'DONE' | 'CANCELLED';
export type ItTicketPriority = 'NORMAL' | 'HIGH';

export interface ItTicket {
  ticketId: string;
  deviceInfo: string;
  category: ItTicketCategory;
  description: string;
  location?: string;
  imageUrl?: string;
  priority: ItTicketPriority;
  reporterId: string;
  assigneeId?: string;
  status: ItTicketStatus;
  resolveNote?: string;
  resolvedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ItTicketOverview {
  total: number;
  mine: number;
  mineDone: number;
  open: number;
  byCategory: Record<string, number>;
  byStatus: Record<string, number>;
  topHandlers: { assigneeId: string; count: number }[];
  prev: { total: number; done: number; mineDone: number; open: number };
  attention: ItTicket[];
  trend: { ym: number; total: number; done: number }[];
}

// Performance review (Form 6, 10 tieu chi 1-5) matching Spring Boot PerformanceReviewResponse
export type ReviewStatus = 'DRAFT' | 'SELF_SUBMITTED' | 'MANAGER_SCORED' | 'LOCKED';
export type PeriodType = 'MONTHLY' | 'YEARLY';

export interface PerformanceScore {
  scoreId: string;
  criterionCode: string;
  criterionText: string;
  sortOrder: number;
  selfScore: number | null;
  managerScore: number | null;
  note?: string | null;
}

export interface PerformanceReview {
  reviewId: string;
  userId: string;
  employeeCode: string;
  revieweeName: string;
  department: string;
  job: string;
  periodType: PeriodType;
  periodMonth: number;
  periodYear: number;
  status: ReviewStatus;
  avgSelf: number | null;
  avgManager: number | null;
  overallSummary?: string | null;
  nextGoals?: string | null;
  selfAt?: string | null;
  managerAt?: string | null;
  evaluatorId?: string | null;
  evaluatorName?: string | null;
  departmentName?: string | null;
  lockedBy?: string | null;
  lockedAt?: string | null;
  leaderConfirmed: boolean;
  scores: PerformanceScore[];
}

export interface PerformanceOverview {
  total: number;
  avgScore: number | null;
  byStatus: Record<string, number>;
  avgByDept: { department: string; avg: number; count: number }[];
  excellent: PerformanceReview[];
  belowTarget: PerformanceReview[];
}

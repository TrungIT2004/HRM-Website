import { apiClient, buildQuery, PageResponse } from './apiClient';
import { AttendanceRecord, MonthlyTimesheetSummary } from '@/types';

export interface AttendanceFilterParams {
  startDate?: string;
  endDate?: string;
  status?: string;
  keyword?: string;
  departmentNames?: string[];
  page?: number;
  size?: number;
}

export interface TimesheetFilterParams {
  month?: number;
  year?: number;
  keyword?: string;
  departmentNames?: string[];
  page?: number;
  size?: number;
}

function mapAttendanceItem(item: any): AttendanceRecord {
  return {
    ...item,
    userName: item.fullName || item.userName || '',
    faceRecognitionVerified: item.faceRecognitionVerified ?? true,
    faceConfidence: item.faceConfidence ?? 98.5
  };
}

// ponytail: backend bọc chỉ số trong attendance/leave/overtime (cả 3 scope me/dept/company)
function mapTimesheetItem(item: any): MonthlyTimesheetSummary {
  const att = item.attendance || {};
  const leave = item.leave || {};
  const ot = item.overtime || {};
  return {
    // timesheetId/note có sẵn ở CompanyMonthlyTimesheetResponse — bỏ qua là nút "Sửa"
    // không biết gọi PUT /summary/{timesheetId} với id nào.
    timesheetId: item.timesheetId || '',
    userId: item.userId || '',
    employeeCode: item.employeeCode || '',
    fullName: item.fullName || '',
    department: item.department || '',
    job: item.job || '',
    month: item.month || item.periodMonth || 0,
    year: item.year || item.periodYear || 0,
    standardWorkingDays: att.standardWorkingDays ?? item.standardWorkingDays ?? 0,
    actualWorkedDays: att.actualWorkedDays ?? item.actualWorkedDays ?? 0,
    lateCount: att.lateCount ?? item.lateCount ?? 0,
    totalLateMinutes: att.totalLateMinutes ?? item.totalLateMinutes ?? 0,
    earlyDepartureCount: att.earlyDepartureCount ?? item.earlyDepartureCount ?? 0,
    absentDays: att.absentDays ?? item.absentDays ?? 0,
    paidLeaveDays: leave.paidLeaveDays ?? item.paidLeaveDays ?? 0,
    unpaidLeaveDays: leave.unpaidLeaveDays ?? item.unpaidLeaveDays ?? 0,
    remainingAnnualLeaveDays: leave.remainingAnnualLeaveDays ?? item.remainingAnnualLeaveDays ?? 0,
    totalActualHours: att.actualWorkHours ?? item.totalActualHours ?? 0,
    totalPaidHours: ot.totalPaidHours ?? item.totalPaidHours ?? (att.actualWorkHours ?? 0),
    overtimeHours: ot.totalActualHours ?? item.overtimeHours ?? 0,
    status: item.status,
    lockedAt: item.lockedAt ?? null,
    note: item.note || ''
  };
}

export const attendanceService = {
  getMyAttendances: async (params: AttendanceFilterParams = {}): Promise<PageResponse<AttendanceRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/attendances/my-attendances${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      const myId = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_user_id') : undefined;
      res.content = res.content.map((item: any) => ({
        ...mapAttendanceItem(item),
        userId: item.userId || myId || ''
      }));
    }
    return res;
  },

  getDepartmentAttendances: async (params: AttendanceFilterParams = {}): Promise<PageResponse<AttendanceRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/attendances/department${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapAttendanceItem);
    }
    return res;
  },

  getCompanyAttendances: async (params: AttendanceFilterParams = {}): Promise<PageResponse<AttendanceRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/attendances/company${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapAttendanceItem);
    }
    return res;
  },

  checkAttendance: async (userId: string): Promise<{ action: string; msg: string }> => {
    return apiClient.put<{ action: string; msg: string }>(`/api/attendances/${userId}`);
  },

  editAttendance: async (attendanceId: string, data: { clockInTime?: string; clockOutTime?: string; status?: string; reason: string }) => {
    // ponytail: backend EditAttendanceRequest dùng edited* keys + editedStatus @NotNull
    return apiClient.put(`/api/attendances/edit/${attendanceId}`, {
      editedClockInTime: data.clockInTime || null,
      editedClockOutTime: data.clockOutTime || null,
      editedStatus: data.status,
      editedReason: data.reason
    });
  },

  deleteAttendance: async (attendanceId: string) => {
    return apiClient.delete(`/api/attendances/${attendanceId}`);
  },

  exportAttendances: async (params: AttendanceFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/attendances/export${buildQuery(params)}`, 'attendance_report.xlsx');
  },

  // Monthly Timesheets
  getMyMonthlySummary: async (params: TimesheetFilterParams = {}): Promise<PageResponse<MonthlyTimesheetSummary>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/attendances/summary/me${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapTimesheetItem);
    }
    return res;
  },

  getDepartmentMonthlySummary: async (params: TimesheetFilterParams = {}): Promise<PageResponse<MonthlyTimesheetSummary>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/attendances/summary/department${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapTimesheetItem);
    }
    return res;
  },

  getCompanyMonthlySummary: async (params: TimesheetFilterParams = {}): Promise<PageResponse<MonthlyTimesheetSummary>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/attendances/summary/company${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapTimesheetItem);
    }
    return res;
  },

  generateMonthlySummary: async (month: number, year: number) => {
    return apiClient.post(`/api/attendances/summary/generate?month=${month}&year=${year}`);
  },

  editMonthlyTimesheet: async (timesheetId: string, data: any) => {
    return apiClient.put(`/api/attendances/summary/${timesheetId}`, data);
  },

  /** userIds rỗng = chốt cả tháng; có giá trị = chỉ chốt nhóm nhân viên đang tick trên bảng. */
  lockMonthlySummary: async (month: number, year: number, userIds: string[] = []) => {
    const qs = new URLSearchParams({ month: String(month), year: String(year) });
    userIds.forEach(id => qs.append('userIds', id));
    return apiClient.put(`/api/attendances/summary/lock?${qs.toString()}`);
  },

  exportMyMonthlySummary: async (params: TimesheetFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/attendances/summary/me/export${buildQuery(params)}`, 'my_monthly_timesheet.xlsx');
  },

  exportDepartmentMonthlySummary: async (params: TimesheetFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/attendances/summary/department/export${buildQuery(params)}`, 'dept_timesheets.xlsx');
  },

  exportCompanyMonthlySummary: async (params: TimesheetFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/attendances/summary/company/export${buildQuery(params)}`, 'company_timesheets.xlsx');
  },

  getOverview: async (params: { startDate?: string; endDate?: string; scope?: 'dept' | 'company' } = {}) => {
    return apiClient.get<any>(`/api/attendances/overview${buildQuery(params)}`);
  }
};

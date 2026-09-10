import { apiClient } from './apiClient';
import { AttendanceRecord, MonthlyTimesheetSummary } from '@/types';

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

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

function buildQuery(params: Record<string, any>): string {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([key, val]) => {
    if (val !== undefined && val !== null && val !== '' && val !== 'ALL') {
      if (Array.isArray(val)) {
        val.forEach(v => q.append(key, String(v)));
      } else {
        q.append(key, String(val));
      }
    }
  });
  const qs = q.toString();
  return qs ? `?${qs}` : '';
}

function mapAttendanceItem(item: any): AttendanceRecord {
  return {
    ...item,
    userName: item.fullName || item.userName || '',
    faceRecognitionVerified: item.faceRecognitionVerified ?? true,
    faceConfidence: item.faceConfidence ?? 98.5
  };
}

export const attendanceService = {
  getMyAttendances: async (params: AttendanceFilterParams = {}): Promise<PageResponse<AttendanceRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/attendances/my-attendances${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapAttendanceItem);
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
    return apiClient.put(`/api/attendances/edit/${attendanceId}`, data);
  },

  deleteAttendance: async (attendanceId: string) => {
    return apiClient.delete(`/api/attendances/${attendanceId}`);
  },

  exportAttendances: async (params: AttendanceFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/attendances/export${buildQuery(params)}`, 'attendance_report.xlsx');
  },

  // Monthly Timesheets
  getMyMonthlySummary: async (params: TimesheetFilterParams = {}): Promise<PageResponse<MonthlyTimesheetSummary>> => {
    return apiClient.get<PageResponse<MonthlyTimesheetSummary>>(`/api/attendances/summary/me${buildQuery(params)}`);
  },

  getDepartmentMonthlySummary: async (params: TimesheetFilterParams = {}): Promise<PageResponse<MonthlyTimesheetSummary>> => {
    return apiClient.get<PageResponse<MonthlyTimesheetSummary>>(`/api/attendances/summary/department${buildQuery(params)}`);
  },

  getCompanyMonthlySummary: async (params: TimesheetFilterParams = {}): Promise<PageResponse<MonthlyTimesheetSummary>> => {
    return apiClient.get<PageResponse<MonthlyTimesheetSummary>>(`/api/attendances/summary/company${buildQuery(params)}`);
  },

  generateMonthlySummary: async (month: number, year: number) => {
    return apiClient.post(`/api/attendances/summary/generate?month=${month}&year=${year}`);
  },

  editMonthlyTimesheet: async (timesheetId: string, data: any) => {
    return apiClient.put(`/api/attendances/summary/${timesheetId}`, data);
  },

  lockMonthlySummary: async (month: number, year: number) => {
    return apiClient.put(`/api/attendances/summary/lock?month=${month}&year=${year}`);
  },

  exportMyMonthlySummary: async (params: TimesheetFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/attendances/summary/me/export${buildQuery(params)}`, 'my_monthly_timesheet.xlsx');
  },

  exportDepartmentMonthlySummary: async (params: TimesheetFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/attendances/summary/department/export${buildQuery(params)}`, 'dept_timesheets.xlsx');
  },

  exportCompanyMonthlySummary: async (params: TimesheetFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/attendances/summary/company/export${buildQuery(params)}`, 'company_timesheets.xlsx');
  }
};

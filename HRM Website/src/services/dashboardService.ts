import { apiClient } from './apiClient';

export interface DashboardSummaryResponse {
  userRole: string;
  fullName: string;
  employeeCode: string;
  department: string;
  job: string;
  avatarUrl?: string;
  todayStatus: string;
  clockInTime?: string;
  clockOutTime?: string;
  monthSummary: {
    periodMonth: number;
    periodYear: number;
    totalWorkDays: number;
    standardWorkDays: number;
    totalWorkHours: number;
    remainingLeaveDays: number;
  };
  management?: {
    pendingLeavesCount: number;
    pendingOvertimesCount: number;
    departmentEmployeeCount?: number;
    todayPresentCount?: number;
    todayAbsentCount?: number;
  };
  todayShifts?: Array<{
    shiftName: string;
    startTime: string;
    endTime: string;
    restStartTime?: string;
    restEndTime?: string;
  }>;
  quickHolidays?: Array<{
    name: string;
    holidayDate: string;
    description?: string;
  }>;
}

function mapDashboardSummary(data: any): DashboardSummaryResponse {
  if (!data) return {} as any;
  const user = data.userProfile || {};
  const att = data.todayAttendance || {};
  const month = data.monthlySummary || {};
  const leave = data.leaveBalance || {};
  const approvals = data.pendingApprovals || {};

  return {
    userRole: data.userRole || user.job || '',
    fullName: user.fullName || data.fullName || '',
    employeeCode: user.employeeCode || data.employeeCode || '',
    department: user.department || data.department || '',
    job: user.job || data.job || '',
    avatarUrl: user.profilePicUrl || data.avatarUrl || '',
    todayStatus: att.status || data.todayStatus || 'NOT_CHECKED',
    clockInTime: att.clockInTime || data.clockInTime,
    clockOutTime: att.clockOutTime || data.clockOutTime,
    monthSummary: {
      periodMonth: month.month || data.monthSummary?.periodMonth || new Date().getMonth() + 1,
      periodYear: month.year || data.monthSummary?.periodYear || new Date().getFullYear(),
      totalWorkDays: month.actualWorkDays ?? data.monthSummary?.totalWorkDays ?? 0,
      standardWorkDays: month.standardWorkDays ?? data.monthSummary?.standardWorkDays ?? 22,
      totalWorkHours: month.totalWorkHours ?? data.monthSummary?.totalWorkHours ?? 0,
      remainingLeaveDays: leave.remainingLeaveDays ?? data.monthSummary?.remainingLeaveDays ?? 12
    },
    management: {
      pendingLeavesCount: approvals.pendingLeavesCount ?? data.management?.pendingLeavesCount ?? 0,
      pendingOvertimesCount: approvals.pendingOvertimesCount ?? data.management?.pendingOvertimesCount ?? 0,
      departmentEmployeeCount: data.management?.departmentEmployeeCount,
      todayPresentCount: data.management?.todayPresentCount,
      todayAbsentCount: data.management?.todayAbsentCount
    },
    todayShifts: data.todayShifts || [],
    quickHolidays: data.quickHolidays || []
  };
}

export const dashboardService = {
  getSummary: async (): Promise<DashboardSummaryResponse> => {
    const res = await apiClient.get<any>('/api/dashboard/summary');
    return mapDashboardSummary(res);
  }
};

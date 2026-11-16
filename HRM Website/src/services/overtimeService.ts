import { apiClient, buildQuery, PageResponse, toHHmm } from './apiClient';
import { OvertimeRecord } from '@/types';

export interface OvertimeFilterParams {
  fromDate?: string;
  toDate?: string;
  status?: string;
  keyword?: string;
  departmentNames?: string[];
  page?: number;
  size?: number;
}

export interface CreateOvertimeRequest {
  approvedDate: string;
  approvedStartTime: string;
  approvedEndTime: string;
  reason: string;
  type?: 'normal' | 'weekend' | 'holiday';
}

const computeHoursFromTimes = (start: string, end: string): number => {
  try {
    const s = start.includes('T') ? start.split('T')[1] : start;
    const e = end.includes('T') ? end.split('T')[1] : end;
    const [sh, sm] = s.split(':').map(Number);
    const [eh, em] = e.split(':').map(Number);
    let diff = (eh * 60 + (em || 0)) - (sh * 60 + (sm || 0));
    // Kết thúc <= bắt đầu = ca xuyên đêm → sang ngày hôm sau
    if (diff <= 0) diff += 24 * 60;
    return Math.round(diff / 6) / 10;
  } catch { return 0; }
};

function mapOtItem(item: any): OvertimeRecord {
  const startTime = toHHmm(item.approvedStartTime, '08:30');
  const endTime = toHHmm(item.approvedEndTime, '17:30');
  const clockIn = toHHmm(item.clockInTime, item.clockInTime);
  const clockOut = toHHmm(item.clockOutTime, item.clockOutTime);

  return {
    ...item,
    approvedStartTime: startTime,
    approvedEndTime: endTime,
    clockInTime: clockIn,
    clockOutTime: clockOut,
    registeredHours: item.totalApprovedHours || item.registeredHours || 
      computeHoursFromTimes(item.approvedStartTime || '', item.approvedEndTime || '') || 0,
    actualHours: item.totalActualHours || item.actualHours || 0,
    // Bảng hệ số phải khớp AttendanceService.calcOvertimeAmounts
    multiplier: item.multiplier ?? (
      item.isHoliday ? (item.isNightTime ? 3.9 : 3.0)
      : item.isWeekend ? (item.isNightTime ? 2.7 : 2.0)
      : (item.isNightTime ? 2.0 : 1.5)
    ),
    status: (item.status ? item.status.toLowerCase() : 'pending') as any
  };
}

export interface OvertimePreview {
  endDate: string | null;      // ngày kết thúc nếu ca xuyên đêm, null nếu cùng ngày
  totalHours: number;
  isWeekend: boolean;
  isHoliday: boolean;
  isNightTime: boolean;
  multiplier: number;
  paidHours: number;
}

export const overtimeService = {
  getMyOvertimes: async (params: OvertimeFilterParams = {}): Promise<PageResponse<OvertimeRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/overtime/my-records${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapOtItem);
    }
    return res;
  },

  getDepartmentOvertimes: async (params: OvertimeFilterParams = {}): Promise<PageResponse<OvertimeRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/overtime/approvals${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapOtItem);
    }
    return res;
  },

  getCompanyOvertimes: async (params: OvertimeFilterParams = {}): Promise<PageResponse<OvertimeRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/overtime/company${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapOtItem);
    }
    return res;
  },

  previewOvertime: async (date: string, startTime: string, endTime: string): Promise<OvertimePreview> => {
    const qs = new URLSearchParams({ date, startTime, endTime });
    return apiClient.get<OvertimePreview>(`/api/overtime/preview?${qs.toString()}`);
  },

  createOvertime: async (data: CreateOvertimeRequest): Promise<OvertimeRecord> => {
    const date = data.approvedDate || new Date().toISOString().split('T')[0];
    const startTime = data.approvedStartTime.includes('T') ? data.approvedStartTime : `${date}T${data.approvedStartTime}`;
    const endTime = data.approvedEndTime.includes('T') ? data.approvedEndTime : `${date}T${data.approvedEndTime}`;
    return apiClient.post<OvertimeRecord>('/api/overtime', {
      approvedStartTime: startTime,
      approvedEndTime: endTime,
      reason: data.reason
    });
  },

  approveOvertime: async (recordId: string): Promise<OvertimeRecord> => {
    // ponytail: backend HandleOvertimeReqApiRequest cần {status, rejectionReason}
    return apiClient.patch<OvertimeRecord>(`/api/overtime/${recordId}/handle`, {
      status: 'accepted'
    });
  },

  rejectOvertime: async (recordId: string, reason: string): Promise<OvertimeRecord> => {
    return apiClient.patch<OvertimeRecord>(`/api/overtime/${recordId}/handle`, {
      status: 'rejected',
      rejectionReason: reason
    });
  },

  cancelOvertime: async (recordId: string): Promise<void> => {
    return apiClient.delete(`/api/overtime/${recordId}`);
  },

  exportExcel: async (params: OvertimeFilterParams = {}): Promise<Blob> => {
    return apiClient.downloadBlob(`/api/overtime/export${buildQuery(params)}`);
  }
};

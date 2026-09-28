import { apiClient } from './apiClient';
import { OvertimeRecord } from '@/types';
import { PageResponse } from './attendanceService';

export interface OvertimeFilterParams {
  fromDate?: string;
  toDate?: string;
  status?: string;
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
    const diff = (eh * 60 + (em || 0)) - (sh * 60 + (sm || 0));
    return diff > 0 ? Math.round(diff / 6) / 10 : 0;
  } catch { return 0; }
};

function mapOtItem(item: any): OvertimeRecord {
  const startTime = item.approvedStartTime && item.approvedStartTime.includes('T')
    ? item.approvedStartTime.split('T')[1].substring(0, 5)
    : (item.approvedStartTime || '08:30');
  const endTime = item.approvedEndTime && item.approvedEndTime.includes('T')
    ? item.approvedEndTime.split('T')[1].substring(0, 5)
    : (item.approvedEndTime || '17:30');
  const clockIn = item.clockInTime && item.clockInTime.includes('T')
    ? item.clockInTime.split('T')[1].substring(0, 5)
    : item.clockInTime;
  const clockOut = item.clockOutTime && item.clockOutTime.includes('T')
    ? item.clockOutTime.split('T')[1].substring(0, 5)
    : item.clockOutTime;

  return {
    ...item,
    approvedStartTime: startTime,
    approvedEndTime: endTime,
    clockInTime: clockIn,
    clockOutTime: clockOut,
    registeredHours: item.totalApprovedHours || item.registeredHours || 
      computeHoursFromTimes(item.approvedStartTime || '', item.approvedEndTime || '') || 0,
    actualHours: item.totalActualHours || item.actualHours || 0,
    multiplier: item.multiplier || (item.isHoliday ? 3.0 : item.isWeekend ? 2.0 : 1.5),
    status: (item.status ? item.status.toLowerCase() : 'pending') as any
  };
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

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
    registeredHours: item.totalApprovedHours || item.registeredHours || 0,
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
    return apiClient.post<OvertimeRecord>('/api/overtime', data);
  },

  approveOvertime: async (recordId: string): Promise<OvertimeRecord> => {
    return apiClient.patch<OvertimeRecord>(`/api/overtime/${recordId}/handle`, {
      action: 'APPROVE'
    });
  },

  rejectOvertime: async (recordId: string, reason: string): Promise<OvertimeRecord> => {
    return apiClient.patch<OvertimeRecord>(`/api/overtime/${recordId}/handle`, {
      action: 'REJECT',
      reason
    });
  },

  cancelOvertime: async (recordId: string): Promise<void> => {
    return apiClient.delete(`/api/overtime/${recordId}`);
  },

  exportExcel: async (params: OvertimeFilterParams = {}): Promise<Blob> => {
    return apiClient.downloadBlob(`/api/overtime/export${buildQuery(params)}`);
  }
};

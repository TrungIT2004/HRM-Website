import { apiClient } from './apiClient';
import { LeaveRequest } from '@/types';
import { PageResponse } from './attendanceService';

export interface LeaveFilterParams {
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

export interface CreateLeaveRequest {
  fromDate: string;
  toDate: string;
  reason: string;
  paidLeaveDays?: number;
}

export const leaveService = {
  getMyLeaves: async (params: LeaveFilterParams = {}): Promise<PageResponse<LeaveRequest>> => {
    return apiClient.get<PageResponse<LeaveRequest>>(`/api/leave/my-requests${buildQuery(params)}`);
  },

  getDepartmentLeaves: async (params: LeaveFilterParams = {}): Promise<PageResponse<LeaveRequest>> => {
    return apiClient.get<PageResponse<LeaveRequest>>(`/api/leave/approvals${buildQuery(params)}`);
  },

  getCompanyLeaves: async (params: LeaveFilterParams = {}): Promise<PageResponse<LeaveRequest>> => {
    return apiClient.get<PageResponse<LeaveRequest>>(`/api/leave/company${buildQuery(params)}`);
  },

  previewLeave: async (fromDate: string, toDate: string): Promise<any> => {
    return apiClient.get<any>(`/api/leave/preview?fromDate=${fromDate}&toDate=${toDate}`);
  },

  createLeave: async (data: CreateLeaveRequest): Promise<LeaveRequest> => {
    return apiClient.post<LeaveRequest>('/api/leave', data);
  },

  approveLeave: async (requestId: string): Promise<LeaveRequest> => {
    // ponytail: backend HandleLeaveReqApiRequest cần {status, rejectionReason}
    return apiClient.patch<LeaveRequest>(`/api/leave/${requestId}/handle`, {
      status: 'accepted'
    });
  },

  rejectLeave: async (requestId: string, reason: string): Promise<LeaveRequest> => {
    return apiClient.patch<LeaveRequest>(`/api/leave/${requestId}/handle`, {
      status: 'rejected',
      rejectionReason: reason
    });
  },

  cancelLeave: async (requestId: string): Promise<void> => {
    return apiClient.delete(`/api/leave/${requestId}`);
  },

  exportExcel: async (params: LeaveFilterParams = {}): Promise<Blob> => {
    return apiClient.downloadBlob(`/api/leave/export${buildQuery(params)}`);
  }
};

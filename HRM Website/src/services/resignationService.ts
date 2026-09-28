import { apiClient } from './apiClient';
import { PageResponse } from './attendanceService';

export interface ResignationResponse {
  resignationId: string;
  userId: string;
  fullName: string;
  employeeCode: string;
  departmentName: string;
  jobTitle: string;
  contractType: string;
  requestDate: string;
  lastWorkingDate: string;
  noticePeriodDays: number;
  isCompliantNotice: boolean;
  reason: string;
  status: 'PENDING' | 'MANAGER_APPROVED' | 'MANAGER_REJECTED' | 'APPROVED' | 'REJECTED' | 'CANCELLED' | 'COMPLETED';
  managerComment?: string;
  managerApprovedAt?: string;
  executiveComment?: string;
  executiveApprovedAt?: string;
  hrComment?: string;
  hrReviewedAt?: string;
}

export interface CreateResignationPayload {
  lastWorkingDate: string;
  reason: string;
}

export interface TransferResignationPayload {
  resignationId: string;
  status: 'MANAGER_APPROVED' | 'MANAGER_REJECTED';
  managerComment?: string;
}

export interface ApproveResignationPayload {
  resignationId: string;
  status: 'APPROVED' | 'REJECTED';
  executiveComment?: string;
}

export const resignationService = {
  submitResignation: async (payload: CreateResignationPayload): Promise<ResignationResponse> => {
    return apiClient.post<ResignationResponse>('/api/resignations', payload);
  },

  getMyRequests: async (params: { page?: number; size?: number } = {}): Promise<PageResponse<ResignationResponse>> => {
    const q = new URLSearchParams();
    if (params.page !== undefined) q.append('page', String(params.page));
    if (params.size !== undefined) q.append('size', String(params.size));
    const qs = q.toString() ? `?${q.toString()}` : '';
    return apiClient.get<PageResponse<ResignationResponse>>(`/api/resignations/my-requests${qs}`);
  },

  getApprovals: async (params: { page?: number; size?: number } = {}): Promise<PageResponse<ResignationResponse>> => {
    const q = new URLSearchParams();
    if (params.page !== undefined) q.append('page', String(params.page));
    if (params.size !== undefined) q.append('size', String(params.size));
    const qs = q.toString() ? `?${q.toString()}` : '';
    return apiClient.get<PageResponse<ResignationResponse>>(`/api/resignations/approvals${qs}`);
  },

  getCompanyRequests: async (params: { status?: string; page?: number; size?: number } = {}): Promise<PageResponse<ResignationResponse>> => {
    const q = new URLSearchParams();
    if (params.status && params.status !== 'ALL') q.append('status', params.status);
    if (params.page !== undefined) q.append('page', String(params.page));
    if (params.size !== undefined) q.append('size', String(params.size));
    const qs = q.toString() ? `?${q.toString()}` : '';
    return apiClient.get<PageResponse<ResignationResponse>>(`/api/resignations/company${qs}`);
  },

  transferResignation: async (payload: TransferResignationPayload): Promise<ResignationResponse> => {
    return apiClient.put<ResignationResponse>('/api/resignations/transfer', payload);
  },

  approveResignation: async (payload: ApproveResignationPayload): Promise<ResignationResponse> => {
    return apiClient.put<ResignationResponse>('/api/resignations/approve', payload);
  },

  cancelResignation: async (resignationId: string): Promise<{ message: string }> => {
    return apiClient.patch<{ message: string }>(`/api/resignations/${resignationId}/cancel`);
  }
};

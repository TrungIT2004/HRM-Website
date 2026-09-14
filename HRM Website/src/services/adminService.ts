import { apiClient } from './apiClient';

export interface PendingUserItem {
  pendingId: string;
  firstName: string;
  lastName: string;
  fullName: string;
  gender: string;
  birthDate: string;
  personalEmail: string;
  phoneNumber?: string;
  citizenId?: string;
  placeOfBirth?: string;
  departmentId: string;
  departmentName: string;
  jobId: string;
  jobTitle: string;
  shiftId?: string;
  shiftName?: string;
  baseSalary?: number;
  contractType?: string;
  contractStartDate?: string;
  contractEndDate?: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  rejectionReason?: string;
  createdByName?: string;
  createdAt: string;
}

export interface AdminAccountItem {
  userId: string;
  employeeCode: string;
  fullName: string;
  email: string;
  departmentName: string;
  jobTitle: string;
  isActive: boolean;
  joinedDate: string;
  activeSessionCount: number;
}

export interface AdminSessionItem {
  sessionId: string;
  userId: string;
  userFullName: string;
  userEmail: string;
  departmentName?: string;
  deviceType?: string;
  deviceOS?: string;
  browser?: string;
  ipAddr?: string;
  city?: string;
  country?: string;
  isp?: string;
  createdAt: string;
  lastActiveAt?: string;
  revoked: boolean;
}

export interface ProvisionPayload {
  corporateEmail: string;
  temporaryPassword: string;
  employeeCode?: string;
}

export const adminService = {
  getPendingUsers: async (status: string = 'PENDING'): Promise<PendingUserItem[]> => {
    return apiClient.get<PendingUserItem[]>(`/api/admin/pending-users?status=${status}`);
  },

  provisionUser: async (pendingId: string, payload: ProvisionPayload): Promise<AdminAccountItem> => {
    return apiClient.post<AdminAccountItem>(`/api/admin/pending-users/${pendingId}/provision`, payload);
  },

  rejectPendingUser: async (pendingId: string, reason: string): Promise<{ message: string }> => {
    return apiClient.post<{ message: string }>(`/api/admin/pending-users/${pendingId}/reject`, { reason });
  },

  getAllAccounts: async (): Promise<AdminAccountItem[]> => {
    return apiClient.get<AdminAccountItem[]>('/api/admin/accounts');
  },

  updateAccountStatus: async (userId: string, isActive: boolean, reason?: string): Promise<AdminAccountItem> => {
    return apiClient.patch<AdminAccountItem>(`/api/admin/accounts/${userId}/status`, { isActive, reason });
  },

  resetPassword: async (userId: string, newPassword: string): Promise<{ message: string }> => {
    return apiClient.post<{ message: string }>(`/api/admin/accounts/${userId}/reset-password`, { newPassword });
  },

  getAllSessions: async (): Promise<AdminSessionItem[]> => {
    return apiClient.get<AdminSessionItem[]>('/api/admin/sessions');
  },

  revokeSession: async (sessionId: string): Promise<{ message: string }> => {
    return apiClient.delete<{ message: string }>(`/api/admin/sessions/${sessionId}`);
  },

  revokeAllUserSessions: async (userId: string): Promise<{ message: string }> => {
    return apiClient.delete<{ message: string }>(`/api/admin/users/${userId}/sessions`);
  }
};

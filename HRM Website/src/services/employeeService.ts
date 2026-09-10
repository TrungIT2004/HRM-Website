import { apiClient } from './apiClient';
import { EmployeeDetailed, User } from '@/types';
import { PageResponse } from './attendanceService';

export interface EmployeeFilterParams {
  keyword?: string;
  department?: string;
  page?: number;
  size?: number;
}

export interface CreateEmployeePayload {
  email: string;
  password?: string;
  firstName: string;
  lastName: string;
  gender?: string;
  birthDate?: string;
  joinedDate?: string;
  phoneNumber?: string;
  citizenId?: string;
  address?: string;
  departmentId: string;
  jobId: string;
  shiftId?: string;
  baseSalary?: number;
  profilePicUrl?: string;
}

function buildQuery(params: Record<string, any>): string {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([key, val]) => {
    if (val !== undefined && val !== null && val !== '' && val !== 'ALL') {
      q.append(key, String(val));
    }
  });
  const qs = q.toString();
  return qs ? `?${qs}` : '';
}

function mapDetailResponse(res: any): EmployeeDetailed {
  if (!res) return {} as any;
  const pub = res.publicProfile || res;
  const legal = res.legalProfile || res.profile || {};
  const contract = res.contract || {};
  const pay = res.payroll || res.salary || {};

  return {
    userId: pub.userId || res.userId || '',
    employeeCode: pub.employeeCode || res.employeeCode || '',
    email: pub.workEmail || pub.email || res.email || '',
    firstName: pub.firstName || res.firstName || '',
    lastName: pub.lastName || res.lastName || '',
    fullName: pub.fullName || res.fullName || `${pub.firstName || ''} ${pub.lastName || ''}`.trim(),
    department: pub.departmentName || pub.department || res.department || '',
    job: pub.jobTitle || pub.job || res.job || '',
    profilePicUrl: pub.profilePicUrl || res.profilePicUrl || '',
    todayStatus: pub.todayStatus || res.todayStatus || 'NOT_CHECKED',
    isActive: pub.isActive !== undefined ? pub.isActive : (res.isActive !== undefined ? res.isActive : true),
    gender: (pub.gender === 'Female' ? 'Nữ' : pub.gender === 'Male' ? 'Nam' : pub.gender) || 'Nam',
    birthDate: pub.birthDate || res.birthDate || '',
    joinedDate: pub.joinedDate || res.joinedDate || '',
    phoneNumber: pub.phoneNumber || res.phoneNumber || '',
    annualLeaveDays: pub.annualLeaveDays || res.annualLeaveDays || 12,
    usedLeaveDays: pub.usedLeaveDays || res.usedLeaveDays || 0,
    shiftName: pub.shiftName || res.shiftName || 'Giờ hành chính',
    shiftStartTime: pub.shiftStartTime || '08:30',
    shiftEndTime: pub.shiftEndTime || '17:30',
    restDays: pub.restDays || [6, 7],
    profile: {
      phoneNumber: pub.phoneNumber || res.phoneNumber || '',
      personalEmail: legal.personalEmail || '',
      placeOfBirth: legal.placeOfBirth || '',
      maritalStatus: (legal.maritalStatus || 'Độc thân') as any,
      nationality: legal.nationality || 'Việt Nam',
      citizenIdNumber: legal.citizenIdNumber || legal.citizenId || '',
      socialInsuranceNumber: legal.socialInsuranceNumber || legal.socialInsuranceCode || '',
      taxIdentificationNumber: legal.taxIdentificationNumber || legal.taxCode || '',
      socialInsuranceStartDate: legal.socialInsuranceStartDate || '',
      emergencyContactName: legal.emergencyContactName || '',
      emergencyContactPhone: legal.emergencyContactPhone || '',
      address: legal.address || ''
    },
    bankAccount: {
      bankName: pay.bankName || res.bankAccount?.bankName || '',
      bankAccountNumber: pay.bankAccountNumber || res.bankAccount?.bankAccountNumber || res.bankAccount?.accountNumber || '',
      accountHolder: pay.bankAccountHolder || res.bankAccount?.accountHolder || pub.fullName || ''
    },
    contract: {
      contractType: contract.contractType || 'Chính thức',
      contractStartDate: contract.contractStartDate || '',
      contractEndDate: contract.contractEndDate || '',
      probationEndDate: contract.probationEndDate || ''
    },
    salary: {
      salaryId: pay.salaryId || '',
      baseSalary: pay.baseSalary || 0,
      payFrequency: pay.payFrequency || 'MONTHLY',
      workDays: pay.workDays || 22,
      startDate: pay.startDate || '',
      endDate: pay.endDate || '',
      isActive: true
    },
    weeklySchedule: pub.weeklySchedule || res.weeklySchedule || []
  };
}

export const employeeService = {
  getEmployees: async (params: EmployeeFilterParams = {}): Promise<PageResponse<User>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/employees${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map((item: any) => ({
        ...item,
        department: item.departmentName || item.department || '',
        job: item.jobTitle || item.job || '',
        todayStatus: item.todayStatus || 'NOT_CHECKED',
        annualLeaveDays: item.annualLeaveDays ?? 12,
        usedLeaveDays: item.usedLeaveDays ?? 0,
        shiftName: item.shiftName || 'Giờ hành chính',
        shiftStartTime: item.shiftStartTime || '08:30',
        shiftEndTime: item.shiftEndTime || '17:30',
        restDays: item.restDays || [6, 7]
      }));
    }
    return res;
  },

  getPublicProfile: async (userId: string): Promise<User> => {
    const res = await apiClient.get<any>(`/api/employees/${userId}/public-profile`);
    return {
      ...res,
      department: res.departmentName || res.department || '',
      job: res.jobTitle || res.job || '',
      todayStatus: res.todayStatus || 'NOT_CHECKED',
      annualLeaveDays: res.annualLeaveDays ?? 12,
      usedLeaveDays: res.usedLeaveDays ?? 0,
      shiftName: res.shiftName || 'Giờ hành chính',
      shiftStartTime: res.shiftStartTime || '08:30',
      shiftEndTime: res.shiftEndTime || '17:30',
      restDays: res.restDays || [6, 7]
    };
  },

  getMyDetailedProfile: async (): Promise<EmployeeDetailed> => {
    const res = await apiClient.get<any>('/api/employees/me/detailed');
    return mapDetailResponse(res);
  },

  getDetailedProfile: async (userId: string): Promise<EmployeeDetailed> => {
    const res = await apiClient.get<any>(`/api/employees/${userId}/detailed`);
    return mapDetailResponse(res);
  },

  updateBasicInfo: async (userId: string, data: any): Promise<EmployeeDetailed> => {
    return apiClient.put<EmployeeDetailed>(`/api/employees/${userId}/basic-info`, data);
  },

  updateLegalProfile: async (userId: string, data: any): Promise<EmployeeDetailed> => {
    return apiClient.put<EmployeeDetailed>(`/api/employees/${userId}/legal-profile`, data);
  },

  updateContract: async (userId: string, data: any): Promise<EmployeeDetailed> => {
    return apiClient.put<EmployeeDetailed>(`/api/employees/${userId}/contract`, data);
  },

  updatePayroll: async (userId: string, data: any): Promise<EmployeeDetailed> => {
    return apiClient.put<EmployeeDetailed>(`/api/employees/${userId}/payroll`, data);
  },

  updateAssignment: async (userId: string, data: any): Promise<EmployeeDetailed> => {
    return apiClient.put<EmployeeDetailed>(`/api/employees/${userId}/assignment`, data);
  },

  createEmployee: async (data: CreateEmployeePayload): Promise<EmployeeDetailed> => {
    return apiClient.post<EmployeeDetailed>('/api/employees', data);
  },

  updateStatus: async (userId: string, isActive: boolean, reason?: string): Promise<EmployeeDetailed> => {
    return apiClient.patch<EmployeeDetailed>(`/api/employees/${userId}/status`, { isActive, reason });
  },

  uploadMyAvatar: async (file: File): Promise<{ profilePicUrl: string; message: string }> => {
    const fd = new FormData();
    fd.append('file', file);
    return apiClient.upload<{ profilePicUrl: string; message: string }>('/api/employees/me/avatar', fd);
  },

  uploadEmployeeAvatar: async (userId: string, file: File): Promise<{ profilePicUrl: string; message: string }> => {
    const fd = new FormData();
    fd.append('file', file);
    return apiClient.upload<{ profilePicUrl: string; message: string }>(`/api/employees/${userId}/avatar`, fd);
  }
};

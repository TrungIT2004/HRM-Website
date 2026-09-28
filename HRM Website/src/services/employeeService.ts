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

function sanitizeVietnameseText(str?: string): string {
  if (!str) return '';
  return str
    .replace(/Gi\?\s*h[…\.]*nh\s*ch[¡\?]nh/gi, 'Giờ hành chính')
    .replace(/Nguy\?n/g, 'Nguyễn');
}

function mapDetailResponse(res: any): EmployeeDetailed {
  if (!res) return {} as any;
  const pub = res.publicProfile || res;
  const legal = res.legalProfile || res.profile || {};
  const contract = res.contract || {};
  const pay = res.payroll || res.salary || {};

  const rawShiftName = pub.shiftName || res.shiftName || 'Giờ hành chính (T2-T6)';
  const cleanShiftName = sanitizeVietnameseText(rawShiftName);

  return {
    userId: pub.userId || res.userId || '',
    employeeCode: pub.employeeCode || res.employeeCode || '',
    email: pub.workEmail || pub.email || res.email || '',
    firstName: sanitizeVietnameseText(pub.firstName || res.firstName || ''),
    lastName: sanitizeVietnameseText(pub.lastName || res.lastName || ''),
    fullName: sanitizeVietnameseText(pub.fullName || res.fullName || `${pub.firstName || ''} ${pub.lastName || ''}`.trim()),
    department: pub.departmentName || pub.department || res.department || '',
    job: pub.jobTitle || pub.job || res.job || '',
    profilePicUrl: pub.profilePicUrl || res.profilePicUrl || '',
    todayStatus: pub.todayStatus || res.todayStatus || 'NOT_CHECKED',
    // EmployeePublicProfile.isActive là `boolean` primitive + Lombok @Getter isActive() → Jackson
    // đặt tên key là `active` (không phải `isActive` như các DTO dùng Boolean wrapper).
    // Đọc `active` trước; nếu backend đổi lại thì `isActive` vẫn chạy.
    isActive: (pub as any).active ?? pub.isActive ?? res.isActive ?? true,
    gender: (pub.gender === 'Female' ? 'Nữ' : pub.gender === 'Male' ? 'Nam' : pub.gender) || 'Nam',
    birthDate: pub.birthDate || res.birthDate || '',
    joinedDate: pub.joinedDate || res.joinedDate || '',
    phoneNumber: pub.phoneNumber || res.phoneNumber || '',
    annualLeaveDays: pub.annualLeaveDays || res.annualLeaveDays || 12,
    usedLeaveDays: pub.usedLeaveDays || res.usedLeaveDays || 0,
    shiftName: cleanShiftName,
    shiftStartTime: pub.shiftStartTime || '08:00',
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
      contractId: contract.contractId,
      contractType: contract.contractType || 'Fixed-term',
      contractStartDate: contract.contractStartDate || '',
      contractEndDate: contract.contractEndDate || '',
      probationEndDate: contract.probationEndDate || '',
      isActive: contract.isActive !== undefined ? contract.isActive : true
    },
    contracts: Array.isArray(res.contracts)
      ? res.contracts.map((c: any) => ({
          contractId: c.contractId,
          contractType: c.contractType,
          contractStartDate: c.contractStartDate,
          contractEndDate: c.contractEndDate,
          isActive: c.isActive
        }))
      : [],
    salary: {
      salaryId: pay.salaryId || '',
      baseSalary: pay.baseSalary || 0,
      payFrequency: pay.payFrequency || 'MONTHLY',
      workDays: pay.workDays || 22,
      startDate: pay.startDate || '',
      endDate: pay.endDate || '',
      isActive: true
    },
    weeklySchedule: Array.isArray(pub.weeklySchedule || res.weeklySchedule) && (pub.weeklySchedule || res.weeklySchedule).length > 0
      ? (pub.weeklySchedule || res.weeklySchedule).map((s: any) => ({
          dayOfWeek: Number(s.dayOfWeek),
          dayName: s.dayName || (Number(s.dayOfWeek) === 7 ? 'Chủ Nhật' : `Thứ ${Number(s.dayOfWeek) + 1}`),
          isWorking: s.isWorking !== undefined ? Boolean(s.isWorking) : Boolean(s.working),
          startTime: s.startTime ? String(s.startTime).substring(0, 5) : '08:00',
          endTime: s.endTime ? String(s.endTime).substring(0, 5) : '17:30',
          restStartTime: s.restStartTime ? String(s.restStartTime).substring(0, 5) : '12:00',
          restEndTime: s.restEndTime ? String(s.restEndTime).substring(0, 5) : '13:30',
        }))
      : [
          { dayOfWeek: 1, dayName: 'Thứ 2', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
          { dayOfWeek: 2, dayName: 'Thứ 3', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
          { dayOfWeek: 3, dayName: 'Thứ 4', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
          { dayOfWeek: 4, dayName: 'Thứ 5', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
          { dayOfWeek: 5, dayName: 'Thứ 6', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
          { dayOfWeek: 6, dayName: 'Thứ 7', isWorking: false, startTime: '00:00', endTime: '00:00' },
          { dayOfWeek: 7, dayName: 'Chủ Nhật', isWorking: false, startTime: '00:00', endTime: '00:00' },
        ]
  };
}

export const employeeService = {
  getEmployees: async (params: EmployeeFilterParams = {}): Promise<PageResponse<User>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/employees${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map((item: any) => ({
        ...item,
        firstName: sanitizeVietnameseText(item.firstName),
        lastName: sanitizeVietnameseText(item.lastName),
        fullName: sanitizeVietnameseText(item.fullName || `${item.firstName || ''} ${item.lastName || ''}`.trim()),
        department: item.departmentName || item.department || '',
        job: item.jobTitle || item.job || '',
        todayStatus: item.todayStatus || 'NOT_CHECKED',
        annualLeaveDays: item.annualLeaveDays ?? 12,
        usedLeaveDays: item.usedLeaveDays ?? 0,
        shiftName: sanitizeVietnameseText(item.shiftName || 'Giờ hành chính (T2-T6)'),
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
    const res = await apiClient.put<any>(`/api/employees/${userId}/contract`, data);
    return mapDetailResponse(res);
  },

  renewContract: async (userId: string, data: { contractType: string; contractStartDate: string; contractEndDate?: string }): Promise<EmployeeDetailed> => {
    const res = await apiClient.post<any>(`/api/employees/${userId}/contracts/renew`, data);
    return mapDetailResponse(res);
  },

  createContract: async (userId: string, data: { contractType: string; contractStartDate: string; contractEndDate?: string }): Promise<EmployeeDetailed> => {
    const res = await apiClient.post<any>(`/api/employees/${userId}/contracts`, data);
    return mapDetailResponse(res);
  },

  getContractHistory: async (userId: string): Promise<any[]> => {
    return apiClient.get<any[]>(`/api/employees/${userId}/contracts`);
  },

  updateSpecificContract: async (userId: string, contractId: string, data: any): Promise<EmployeeDetailed> => {
    const res = await apiClient.put<any>(`/api/employees/${userId}/contracts/${contractId}`, data);
    return mapDetailResponse(res);
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

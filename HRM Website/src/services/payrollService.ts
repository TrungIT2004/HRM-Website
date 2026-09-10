import { apiClient } from './apiClient';
import { PayrollRecord } from '@/types';
import { PageResponse } from './attendanceService';

export interface PayrollFilterParams {
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

function mapPayrollItem(item: any): PayrollRecord {
  return {
    payrollId: item.payrollId || '',
    userId: item.userId || '',
    employeeName: item.fullName || item.employeeName || '',
    employeeCode: item.employeeCode || '',
    department: item.department || '',
    job: item.job || '',
    periodMonth: item.periodMonth || 0,
    periodYear: item.periodYear || 0,
    baseSalary: Number(item.baseSalary) || 0,
    standardDays: item.standardWorkingDays || item.standardDays || 26,
    actualWorkedDays: Number(item.actualWorkedDays) || 0,
    actualWorkHours: Number(item.actualWorkHours) || 0,
    basicPay: Number(item.basicPay) || 0,
    overtimePay: Number(item.overtimePay) || 0,
    allowancePay: Number(item.allowancePay) || 0,
    deductionPay: Number(item.totalDeduction !== undefined ? item.totalDeduction : item.deductionPay) || 0,
    netPay: Number(item.netPay) || 0,
    status: (item.status ? String(item.status).toLowerCase() : 'draft') as any,
    calculatedAt: item.calculatedAt || ''
  };
}

export const payrollService = {
  getMyPayrolls: async (params: PayrollFilterParams = {}): Promise<PageResponse<PayrollRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/payrolls/me${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapPayrollItem);
    }
    return res;
  },

  getCompanyPayrolls: async (params: PayrollFilterParams = {}): Promise<PageResponse<PayrollRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/payrolls/company${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      res.content = res.content.map(mapPayrollItem);
    }
    return res;
  },

  generatePayroll: async (month: number, year: number) => {
    return apiClient.post(`/api/payrolls/generate?month=${month}&year=${year}`);
  },

  editPayroll: async (payrollId: string, data: any) => {
    return apiClient.put(`/api/payrolls/${payrollId}`, data);
  },

  lockPayroll: async (month: number, year: number) => {
    return apiClient.put(`/api/payrolls/lock?month=${month}&year=${year}`);
  },

  exportMyPayrolls: async (params: PayrollFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/payrolls/me/export${buildQuery(params)}`, 'my_payslips.xlsx');
  },

  exportCompanyPayrolls: async (params: PayrollFilterParams = {}) => {
    return apiClient.downloadBlob(`/api/payrolls/company/export${buildQuery(params)}`, 'company_payrolls.xlsx');
  }
};

import { apiClient, PageResponse } from './apiClient';
import { PayrollRecord } from '@/types';

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
    // Backend bind @ModelAttribute theo TÊN FIELD của DTO (periodMonth/periodYear).
    // Gửi month/year sẽ bị Spring bỏ qua âm thầm → filter null → trả về mọi tháng.
    const name = key === 'month' ? 'periodMonth' : key === 'year' ? 'periodYear' : key;
    if (val !== undefined && val !== null && val !== '' && val !== 'ALL') {
      if (Array.isArray(val)) {
        val.forEach(v => q.append(name, String(v)));
      } else {
        q.append(name, String(val));
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
    bonusPay: Number(item.bonusPay) || 0,
    grossPay: Number(item.grossPay) || 0,
    hourlyRate: Number(item.hourlyRate) || 0,
    taxDeduction: Number(item.taxDeduction) || 0,
    otherDeduction: Number(item.otherDeduction) || 0,
    note: item.note || '',
    paidAt: item.paidAt || '',
    approvedAt: item.approvedAt || '',
    deductionPay: Number(item.totalDeduction !== undefined ? item.totalDeduction : item.deductionPay) || 0,
    insuranceDeduction: Number(item.insuranceDeduction) || 0,
    netPay: Number(item.netPay) || 0,
    status: (item.status ? String(item.status).toLowerCase() : 'draft') as any,
    calculatedAt: item.calculatedAt || ''
  };
}

export const payrollService = {
  getMyPayrolls: async (params: PayrollFilterParams = {}): Promise<PageResponse<PayrollRecord>> => {
    const res = await apiClient.get<PageResponse<any>>(`/api/payrolls/me${buildQuery(params)}`);
    if (res && Array.isArray(res.content)) {
      const myId = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_user_id') : undefined;
      res.content = res.content.map(p => ({
        ...mapPayrollItem(p),
        userId: p.userId || myId || ''
      }));
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

  /**
   * filter: bộ lọc đang xem. userIds: vùng đang tick trên bảng (ưu tiên hơn filter).
   * Cả hai rỗng = tính toàn tháng.
   */
  generatePayroll: async (month: number, year: number, filter: PayrollFilterParams = {}, userIds: string[] = []) => {
    // month/year phải giữ nguyên tên: POST /generate nhận @RequestParam month/year, còn
    // buildQuery đổi thành periodMonth/periodYear (chỉ đúng cho GET filter theo DTO) →
    // gửi sai tên là Spring ném MissingServletRequestParameterException.
    const q = new URLSearchParams();
    userIds.forEach(id => q.append('userIds', id));
    const extra = q.toString();
    const filterQs = buildQuery({ ...filter }).replace(/^\?/, '');
    const query = [`month=${month}&year=${year}`, filterQs, extra].filter(Boolean).join('&');
    return apiClient.post(`/api/payrolls/generate?${query}`);
  },

  approvePayroll: async (month: number, year: number) => {
    return apiClient.put(`/api/payrolls/approve?month=${month}&year=${year}`);
  },

  markAsPaid: async (month: number, year: number) => {
    return apiClient.put(`/api/payrolls/pay?month=${month}&year=${year}`);
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

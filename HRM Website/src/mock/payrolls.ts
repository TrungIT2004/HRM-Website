import { PayrollRecord } from '@/types';
import { MOCK_USERS } from './users';
import { MOCK_EMPLOYEE_DETAILS, getEmployeeDetail } from './employeeDetails';

export const MOCK_PAYROLLS: PayrollRecord[] = MOCK_USERS.map((user, idx) => {
  const detail = getEmployeeDetail(user.userId);
  const baseSalary = detail.salary?.baseSalary || 20000000;
  const standardDays = 26;
  const actualDays = idx % 3 === 0 ? 25 : 26;
  const hourlyRate = baseSalary / (standardDays * 8.0);
  const actualHours = actualDays * 8.0;
  const basicPay = Math.round(actualHours * hourlyRate);

  // OT Pay
  const otHours = idx % 2 === 0 ? 6 : 0;
  const overtimePay = Math.round(otHours * hourlyRate * 1.5);

  const allowancePay = 1500000; // Tiền ăn trưa & xăng xe
  const deductionPay = (idx % 3 === 0 ? Math.round(1 * 8.0 * hourlyRate) : 0) + Math.round(baseSalary * 0.105); // Trừ ngày nghỉ + BHXH 10.5%
  const netPay = Math.round(basicPay + overtimePay + allowancePay - deductionPay);

  return {
    payrollId: `payroll-2026-08-${user.employeeCode}`,
    userId: user.userId,
    employeeName: user.fullName,
    employeeCode: user.employeeCode,
    department: user.department,
    job: user.job,
    periodMonth: 8,
    periodYear: 2026,
    baseSalary,
    standardDays,
    actualWorkedDays: actualDays,
    actualWorkHours: actualHours,
    basicPay,
    overtimePay,
    allowancePay,
    deductionPay,
    netPay,
    status: 'approved',
    calculatedAt: '2026-09-01 08:30:00'
  };
});

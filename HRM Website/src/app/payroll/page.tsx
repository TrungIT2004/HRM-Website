'use client';

import React, { useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { PayrollRecord } from '@/types';
import { payrollService } from '@/services/payrollService';
import {
  CreditCard,
  FileSpreadsheet,
  Calculator,
  CheckCircle2,
  AlertCircle,
  Building2,
  DollarSign,
  TrendingUp,
  Download,
  Calendar,
  Sparkles,
  ShieldCheck,
  ChevronRight
} from 'lucide-react';

export default function PayrollPage() {
  const { currentUser, isHR, isExecutive } = useAuth();
  const { payrolls, generateMonthlyPayroll } = useHRMData();

  const [activeTab, setActiveTab] = useState<'my' | 'company'>('my');
  const [selectedMonth, setSelectedMonth] = useState(8);
  const [selectedYear, setSelectedYear] = useState(2026);
  const [toastMsg, setToastMsg] = useState('');

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };

  const isFinanceOrExecutive = isExecutive || currentUser?.department === 'Finance & Accounting' || Boolean(currentUser?.job?.toLowerCase().includes('accountant'));

  // Reset tab if role switches and tab is no longer permitted
  React.useEffect(() => {
    if (!isFinanceOrExecutive && activeTab === 'company') {
      setActiveTab('my');
    }
  }, [isFinanceOrExecutive, activeTab]);

  // Find current user's payslip
  const myPayslip = payrolls.find(p => p.userId === currentUser?.userId);

  const handleRunPayroll = async () => {
    try {
      await generateMonthlyPayroll(selectedMonth, selectedYear);
      showToast(`Đã tính toán bảng lương tự động cho Tháng ${selectedMonth}/${selectedYear} thành công!`);
    } catch (err: any) {
      showToast('Lỗi tính lương: ' + (err.message || 'Không thể tính toán'));
    }
  };

  const handleExportExcel = async () => {
    try {
      if (activeTab === 'company') {
        await payrollService.exportCompanyPayrolls({ month: selectedMonth, year: selectedYear });
      } else {
        await payrollService.exportMyPayrolls({ month: selectedMonth, year: selectedYear });
      }
      showToast('Đã tải xuống file Excel bảng lương thành công!');
    } catch (err: any) {
      showToast('Lỗi xuất Excel: ' + (err.message || 'Không thể tải file'));
    }
  };

  const formatVND = (num?: number | null) => {
    if (num === undefined || num === null || isNaN(Number(num))) return '0 ₫';
    return Number(num).toLocaleString('vi-VN') + ' ₫';
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Toast */}
        {toastMsg && (
          <div className="fixed top-20 right-6 z-50 rounded-2xl bg-slate-900 text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold animate-in slide-in-from-top-4">
            <CheckCircle2 className="h-5 w-5 text-emerald-400" />
            <span>{toastMsg}</span>
          </div>
        )}

        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200 mb-2">
              <CreditCard className="h-3.5 w-3.5" />
              <span>Phân hệ Tính Lương Tự Động (Spring Boot /payrolls/caculate)</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Bảng Lương & Thu Nhập
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Tự động tính lương NET từ dữ liệu giờ làm việc thực tế, hệ số làm thêm giờ OT và các khoản khấu trừ.
            </p>
          </div>

          {isFinanceOrExecutive && (
            <div className="flex items-center gap-2.5">
              <button
                onClick={handleRunPayroll}
                className="flex items-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
              >
                <Calculator className="h-4 w-4" />
                <span>Chạy Tính Lương Tự Động</span>
              </button>
              <button
                onClick={handleExportExcel}
                className="flex items-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-emerald-500/20 transition cursor-pointer"
              >
                <FileSpreadsheet className="h-4 w-4" />
                <span>Xuất Bảng Lương (Excel)</span>
              </button>
            </div>
          )}
        </div>

        {/* Tabs */}
        <div className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-xs font-bold">
          <button
            onClick={() => setActiveTab('my')}
            className={`px-4 py-2 rounded-xl transition cursor-pointer ${
              activeTab === 'my' ? 'bg-emerald-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            Phiếu lương của tôi (Tháng 08/2026)
          </button>
          {isFinanceOrExecutive && (
            <button
              onClick={() => setActiveTab('company')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                activeTab === 'company' ? 'bg-emerald-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              Quản lý Bảng lương toàn công ty ({payrolls.length} nhân sự)
            </button>
          )}
        </div>

        {/* Tab 1: My Payslip */}
        {activeTab === 'my' && (
          <div className="space-y-6">
            {myPayslip ? (
              <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80 max-w-3xl mx-auto">
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between pb-6 border-b border-slate-200 gap-4">
                  <div>
                    <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200">
                      Phiếu Lương Điện Tử (ACT e-Payslip)
                    </span>
                    <h2 className="text-xl font-black text-slate-900 mt-2">
                      Kỳ Lương Tháng {myPayslip.periodMonth}/{myPayslip.periodYear}
                    </h2>
                    <p className="text-xs text-slate-500">
                      Nhân viên: <strong>{myPayslip.employeeName}</strong> ({myPayslip.employeeCode}) • {myPayslip.job}
                    </p>
                  </div>
                  <div className="text-left sm:text-right">
                    <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 text-emerald-800 px-3 py-1 text-xs font-bold">
                      ✓ Đã chuyển khoản
                    </span>
                    <p className="text-[11px] text-slate-400 mt-1">Ngày quyết toán: {myPayslip.calculatedAt}</p>
                  </div>
                </div>

                {/* Net Salary Highlight Banner */}
                <div className="my-6 rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-700 p-6 text-white text-center shadow-lg shadow-emerald-500/20">
                  <span className="text-xs font-semibold text-emerald-100 uppercase tracking-wider">
                    Lương Thực Nhận (NET PAY)
                  </span>
                  <div className="mt-1 text-3xl sm:text-4xl font-black">
                    {formatVND(myPayslip.netPay)}
                  </div>
                  <p className="mt-1 text-xs text-emerald-200">
                    Đã chuyển vào số tài khoản ngân hàng đã đăng ký
                  </p>
                </div>

                {/* Breakdown Table */}
                <div className="space-y-4 text-xs">
                  <h4 className="font-bold text-slate-800 uppercase tracking-wider text-[11px]">
                    1. Chi tiết Thu Nhập (Earnings)
                  </h4>
                  <div className="divide-y divide-slate-100 bg-slate-50 rounded-2xl p-4 border border-slate-200/80">
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Lương thỏa thuận cơ bản (Base Salary):</span>
                      <span className="font-bold text-slate-800">{formatVND(myPayslip.baseSalary)}</span>
                    </div>
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Lương công nhật thực tế ({myPayslip.actualWorkedDays}/{myPayslip.standardDays} ngày):</span>
                      <span className="font-bold text-slate-800">{formatVND(myPayslip.basicPay)}</span>
                    </div>
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Tiền làm thêm giờ (Overtime OT):</span>
                      <span className="font-bold text-orange-600">+{formatVND(myPayslip.overtimePay)}</span>
                    </div>
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Phụ cấp ăn trưa, điện thoại & xăng xe:</span>
                      <span className="font-bold text-emerald-600">+{formatVND(myPayslip.allowancePay)}</span>
                    </div>
                  </div>

                  <h4 className="font-bold text-slate-800 uppercase tracking-wider text-[11px] pt-2">
                    2. Các Khoản Khấu Trừ (Deductions)
                  </h4>
                  <div className="divide-y divide-slate-100 bg-slate-50 rounded-2xl p-4 border border-slate-200/80">
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Bảo hiểm xã hội, BHYT & BHTN (10.5%):</span>
                      <span className="font-bold text-red-600">-{formatVND(myPayslip.deductionPay)}</span>
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="p-12 text-center text-xs text-slate-500 bg-white rounded-3xl border border-slate-200">
                Chưa có dữ liệu phiếu lương cho tài khoản này.
              </div>
            )}
          </div>
        )}

        {/* Tab 2: Company All (Finance / Executive) */}
        {activeTab === 'company' && isFinanceOrExecutive && (
          <div className="space-y-4">
            <div className="rounded-2xl bg-white p-4 border border-slate-200 shadow-xs flex flex-wrap items-center justify-between gap-4">
              <div className="flex items-center gap-3">
                <span className="text-xs font-bold text-slate-700">Kỳ lương:</span>
                <select
                  value={selectedMonth}
                  onChange={e => setSelectedMonth(Number(e.target.value))}
                  className="rounded-xl border border-slate-200 py-1.5 px-3 text-xs text-slate-800 bg-white font-bold"
                >
                  <option value={8}>Tháng 08/2026</option>
                  <option value={9}>Tháng 09/2026</option>
                </select>
              </div>

              <div className="text-xs text-slate-500">
                Tổng quỹ lương chi trả: <strong className="text-emerald-700 font-black text-sm">
                  {formatVND(payrolls.reduce((sum, p) => sum + (p.netPay || 0), 0))}
                </strong>
              </div>
            </div>

            <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3 px-4">Nhân sự</th>
                      <th className="py-3 px-4">Phòng ban</th>
                      <th className="py-3 px-4 text-right">Lương Cơ Bản</th>
                      <th className="py-3 px-4 text-center">Công Chuẩn/Thực</th>
                      <th className="py-3 px-4 text-right">Tiền OT</th>
                      <th className="py-3 px-4 text-right">Phụ Cấp</th>
                      <th className="py-3 px-4 text-right">Khấu Trừ</th>
                      <th className="py-3 px-4 text-right">Lương Thực Nhận (NET)</th>
                      <th className="py-3 px-4 text-center">Trạng Thái</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {payrolls.map(item => (
                      <tr key={item.payrollId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900">{item.employeeName}</div>
                          <div className="text-[10px] text-slate-400 font-mono">{item.employeeCode}</div>
                        </td>
                        <td className="py-3 px-4 text-slate-600">{item.department}</td>
                        <td className="py-3 px-4 text-right font-mono font-medium text-slate-800">
                          {formatVND(item.baseSalary)}
                        </td>
                        <td className="py-3 px-4 text-center font-mono">
                          {item.actualWorkedDays} / {item.standardDays}
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-orange-600 font-bold">
                          {item.overtimePay > 0 ? `+${formatVND(item.overtimePay)}` : '0 ₫'}
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-emerald-600 font-bold">
                          +{formatVND(item.allowancePay)}
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-red-600 font-bold">
                          -{formatVND(item.deductionPay)}
                        </td>
                        <td className="py-3 px-4 text-right font-mono font-black text-slate-900 text-sm">
                          {formatVND(item.netPay)}
                        </td>
                        <td className="py-3 px-4 text-center">
                          <span className="inline-flex rounded-full bg-emerald-100 text-emerald-800 px-2.5 py-0.5 text-[10px] font-bold">
                            Đã chốt
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}

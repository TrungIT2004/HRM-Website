'use client';

import React, { useState, useEffect, useMemo } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { PayrollRecord } from '@/types';
import { payrollService } from '@/services/payrollService';
import { DEPARTMENTS } from '@/constants/departments';
import { formatDateVN } from '@/utils/format';
import ConfirmDialog from '@/components/ConfirmDialog';
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
  Sparkles,
  Pencil,
  X,
  Filter,
  Search,
  ShieldCheck,
  ChevronRight
} from 'lucide-react';

export default function PayrollPage() {
  const { currentUser, isExecutive, isAccounting, isChiefAccountant, isHR, can, isLoading: isAuthLoading } = useAuth();
  const { payrolls } = useHRMData(); // ponytail: fallback khi API lỗi

  const [activeTab, setActiveTab] = useState<'my' | 'company'>('my');
  // Kỳ lương (tháng/năm) là biến toàn cục dùng chung cho cả 2 tab + bộ lọc bảng lương.
  // Riêng phòng ban / từ khoá có 2 lớp: `draft` là form đang sửa, `filters` mới là giá trị
  // đã áp dụng — nút "Tra cứu" mới copy draft sang filters.
  // Mặc định là kỳ lương vừa qua (tháng dương lịch 1-12 của năm đang tại) —
  // kỳ hiện tại chưa chốt công nên không có dữ liệu để hiện.
  const [filters, setFilters] = useState(() => {
    const prev = new Date();
    prev.setMonth(prev.getMonth() - 1);
    return { month: prev.getMonth() + 1, year: prev.getFullYear(), dept: 'ALL', keyword: '' };
  });
  const [draft, setDraft] = useState({ dept: 'ALL', keyword: '' });
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  // Bản ghi đang mở modal chỉnh sửa (chỉ DRAFT mới sửa được — backend chặn vậy).
  const [editing, setEditing] = useState<PayrollRecord | null>(null);
  const [editForm, setEditForm] = useState({ allowancePay: '', bonusPay: '', otherDeduction: '', taxDeduction: '', note: '' });
  const [savingEdit, setSavingEdit] = useState(false);
  const [toastMsg, setToastMsg] = useState('');

  // Backend PayrollService: bảng công ty = Ban Giám đốc/Kế toán (HR thường bị 403)
  // ponytail: grant PAYROLL_MANAGE mở cả xem + tính/duyệt (backend đã OR ở cả 2 validator)
  const canViewCompanyPayroll = isExecutive || isAccounting || can('PAYROLL_MANAGE');
  // Sửa bảng lương: HR hoặc Kế toán. Backend (editPayroll) chỉ cho sửa khi DRAFT.
  const canEditPayroll = canViewCompanyPayroll || isHR;
  const canApprovePayroll = isExecutive || isChiefAccountant || can('PAYROLL_MANAGE');

  const [myPayrolls, setMyPayrolls] = useState<PayrollRecord[]>([]);
  const [companyPayrolls, setCompanyPayrolls] = useState<PayrollRecord[]>([]);

  const fetchPayrolls = async () => {
    const params = {
      month: filters.month,
      year: filters.year,
      keyword: filters.keyword.trim(),
      departmentNames: filters.dept === 'ALL' ? [] : [filters.dept],
      size: 100
    };
    try {
      const res = await payrollService.getMyPayrolls(params);
      setMyPayrolls(Array.isArray(res?.content) ? res.content : []);
    } catch {
      setMyPayrolls(payrolls.filter(p =>
        (!p.userId || p.userId === currentUser?.userId) &&
        p.periodMonth === filters.month && p.periodYear === filters.year));
    }
    if (!canViewCompanyPayroll) {
      setCompanyPayrolls([]);
      return;
    }
    try {
      const res = await payrollService.getCompanyPayrolls(params);
      setCompanyPayrolls(Array.isArray(res?.content) ? res.content : []);
    } catch {
      setCompanyPayrolls(payrolls.filter(p =>
        p.periodMonth === filters.month && p.periodYear === filters.year));
    }
  };

  useEffect(() => {
    fetchPayrolls();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, currentUser?.userId, canViewCompanyPayroll]);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };

  // Reset tab if role switches and tab is no longer permitted.
  // ponytail: chờ isAuthLoading — xem giải thích ở leave/page.tsx (reset tab khi chưa có profile)
  useEffect(() => {
    if (isAuthLoading) return;
    if (!canViewCompanyPayroll && activeTab === 'company') {
      setActiveTab('my');
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthLoading, canViewCompanyPayroll, activeTab]);

  // Phiếu lương kỳ đang chọn. KHÔNG fallback sang bản ghi khác: trước đây `|| myPayrolls[0]`
  // khiến chọn tháng chưa có dữ liệu vẫn hiện phiếu của tháng khác.
  const myPayslip = myPayrolls.find(p =>
    p.periodMonth === filters.month && p.periodYear === filters.year
  );

  // generatePayroll vẫn sinh bản ghi DRAFT gross=0 khi timesheet kỳ đó còn trống
  // (chưa chốt công) → coi như chưa có lương. Nâng cấp: chặn ngay trong generatePayroll
  // nếu muốn backend không sinh bản ghi rác.
  const hasPayroll = !!myPayslip && ((myPayslip.actualWorkedDays ?? 0) > 0 || (myPayslip.grossPay ?? 0) > 0);
  const periodLabel = `Tháng ${filters.month < 10 ? `0${filters.month}` : filters.month}/${filters.year}`;

  // Kỳ chưa kết thúc (tháng hiện tại hoặc tương lai) thì khoá toàn bộ chuỗi tính lương —
  // chỉ tính/duyệt/trả được kỳ đã qua. Ví dụ hôm 27/09 thì tháng 09 chưa tính lương được.
  const now = new Date();
  const isOpenPeriod = filters.year > now.getFullYear()
    || (filters.year === now.getFullYear() && filters.month >= now.getMonth() + 1);
  // Chưa bấm "Chạy Tính Lương" thì không có bản ghi nào để duyệt / trả / xuất.
  const hasPayrollData = companyPayrolls.length > 0;

  // UUID từ token (profile) và từ response có thể lệch hoa/thường → so sánh đã chuẩn hoá,
  // không so thẳng `===` (lỗi này làm hàng của chính mình không được đẩy lên đầu / không tô màu).
  const selfId = (currentUser?.userId || '').trim().toLowerCase();
  const isSelf = (id?: string) => !!selfId && (id || '').trim().toLowerCase() === selfId;

  // Hàng của chính mình đẩy lên đầu bảng.
  // ponytail: sort ở client vì 1 kỳ chỉ ~16 nhân viên và đã fetch size=100.
  // Nếu danh sách lớn hơn 1 trang thì chuyển sort xuống tầng DB (ORDER BY user_id = me DESC).
  const companyRows = useMemo(() => {
    if (!selfId) return companyPayrolls;
    return [...companyPayrolls].sort((a, b) => Number(isSelf(b.userId)) - Number(isSelf(a.userId)));
  }, [companyPayrolls, selfId]);

  // Chỉ dòng DRAFT mới tính lại được; APPROVED/PAID đã khoá số liệu.
  const selectableIds = useMemo(
    () => companyRows.filter(r => String(r.status).toUpperCase() === 'DRAFT').map(r => r.userId),
    [companyRows]);

  const toggleRow = (userId: string) => {    setSelectedIds(prev => prev.includes(userId) ? prev.filter(id => id !== userId) : [...prev, userId]);
  };
  const toggleAll = () => {
    setSelectedIds(prev => (selectableIds.every(id => prev.includes(id)) ? [] : selectableIds));
  };

  const handleRunPayroll = async () => {
    const ids = selectedIds;
    const n = ids.length;
    if (n > 0 && !confirm(`Tính lương cho ${n} nhân viên đã chọn? Những dòng khác của kỳ giữ nguyên.`)) return;
    const scope = n > 0
      ? `${n} nhân viên đã chọn`
      : filters.keyword.trim() ? `bộ lọc "${filters.keyword.trim()}"`
        : filters.dept !== 'ALL' ? `phòng ${filters.dept}` : 'toàn tháng';
    try {
      const res: any = await payrollService.generatePayroll(
        filters.month, filters.year,
        { keyword: filters.keyword.trim(), departmentNames: filters.dept === 'ALL' ? [] : [filters.dept] },
        ids);
      showToast(res?.msg || `Đã tính lương Tháng ${filters.month}/${filters.year} (${scope}) thành công!`);
      setSelectedIds([]);
      fetchPayrolls();
    } catch (err: any) {
      showToast('Lỗi tính lương: ' + (err.response?.data?.msg || err.message || 'Không thể tính toán'));
    }
  };

  // Phê duyệt là bước không hoàn tác (chuyển hết DRAFT → APPROVED, rồi không sửa được) → hỏi lại.
  const [approveConfirm, setApproveConfirm] = useState(false);
  const [approving, setApproving] = useState(false);

  const handleApprovePayroll = async () => {
    try {
      setApproving(true);
      await payrollService.approvePayroll(filters.month, filters.year);
      showToast(`Đã phê duyệt bảng lương Tháng ${filters.month}/${filters.year}!`);
      fetchPayrolls();
    } catch (err: any) {
      showToast('Lỗi phê duyệt: ' + (err.message || 'Không thể phê duyệt'));
    } finally {
      setApproving(false);
      setApproveConfirm(false);
    }
  };

  const handleMarkPaid = async () => {
    try {
      await payrollService.markAsPaid(filters.month, filters.year);
      showToast(`Đã xác nhận chi trả lương Tháng ${filters.month}/${filters.year}!`);
      fetchPayrolls();
    } catch (err: any) {
      showToast('Lỗi chi trả: ' + (err.message || 'Không thể xác nhận'));
    }
  };

  const openEditPayroll = (p: PayrollRecord) => {
    setEditing(p);
    setEditForm({
      allowancePay: String(p.allowancePay ?? 0),
      bonusPay: String(p.bonusPay ?? 0),
      otherDeduction: String(p.otherDeduction ?? 0),
      taxDeduction: '',
      note: p.note || ''
    });
  };

  // ponytail: backend tự tính lại gross/thuế/net, chỉ cần gửi 4 khoản + ghi chú.
  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editing) return;
    setSavingEdit(true);
    try {
      await payrollService.editPayroll(editing.payrollId, {
        allowancePay: Number(editForm.allowancePay) || 0,
        bonusPay: Number(editForm.bonusPay) || 0,
        otherDeduction: Number(editForm.otherDeduction) || 0,
        taxDeduction: editForm.taxDeduction.trim() === '' ? null : Number(editForm.taxDeduction),
        note: editForm.note
      });
      showToast(`Đã cập nhật bảng lương của ${editing.employeeName}!`);
      setEditing(null);
      fetchPayrolls();
    } catch (err: any) {
      showToast('Lỗi cập nhật: ' + (err.response?.data?.msg || err.message || 'Không lưu được'));
    } finally {
      setSavingEdit(false);
    }
  };

  const handleExportExcel = async () => {    try {
      if (activeTab === 'company') {
        await payrollService.exportCompanyPayrolls({ month: filters.month, year: filters.year });
      } else {
        await payrollService.exportMyPayrolls({ month: filters.month, year: filters.year });
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

  // Quy ước màu của bảng lương: cộng tiền = xanh lá, trừ tiền = đỏ.
  // `mode='add'` dùng cho khoản thu (luôn +), `mode='sub'` cho khoản trừ (luôn −),
  // `mode='auto'` để dấu và màu theo chính dấu của số.
  const signedMoney = (v: number | undefined, mode: 'add' | 'sub' | 'auto') => {
    const n = Number(v) || 0;
    const negative = mode === 'sub' ? true : mode === 'add' ? false : n < 0;
    const sign = mode === 'auto'
      ? (n < 0 ? '-' : n > 0 ? '+' : '')
      : negative ? '-' : '+';
    return sign + Math.abs(n).toLocaleString('vi-VN') + ' ₫';
  };
  const moneyTone = (v: number | undefined, mode: 'add' | 'sub' | 'auto') => {
    const n = Number(v) || 0;
    if (mode === 'sub') return 'text-red-600';
    if (mode === 'add') return 'text-emerald-600';
    if (n > 0) return 'text-emerald-600';
    if (n < 0) return 'text-red-600';
    return 'text-slate-400';
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
              <span>Phân hệ Tính Lương Tự Động</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Bảng Lương & Thu Nhập
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Tự động tính lương NET từ dữ liệu giờ làm việc thực tế, hệ số làm thêm giờ OT và các khoản khấu trừ.
            </p>
          </div>
        </div>

        {/* Tabs & Month Selector */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-xs font-bold">
            <button
              onClick={() => setActiveTab('my')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                activeTab === 'my' ? 'bg-emerald-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              Phiếu lương của tôi (Tháng {filters.month < 10 ? `0${filters.month}` : filters.month}/{filters.year})
            </button>
            {canViewCompanyPayroll && (
              <button
                onClick={() => setActiveTab('company')}
                className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                  activeTab === 'company' ? 'bg-emerald-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
                }`}
              >
                Quản lý Bảng lương toàn công ty ({companyRows.length} bản ghi)
              </button>
            )}
          </div>
        </div>

        {/* Tab "phiếu của tôi" chỉ cần chọn kỳ; phòng ban / tìm kiếm / tổng quỹ là của tab bảng lương. */}
        <div className="rounded-2xl bg-white border border-slate-200 shadow-xs p-5">
          <div className="flex items-center gap-2 pb-4 border-b border-slate-100">
                <Filter className="w-4 h-4 text-emerald-600" aria-hidden="true" />
                <span className="text-xs font-black uppercase tracking-wide text-slate-700">
                  {activeTab === 'company' ? 'Bộ lọc bảng lương' : 'Kỳ lương'}
                </span>
              </div>

              <div className={`grid gap-4 pt-4 ${activeTab === 'company' ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4' : 'grid-cols-1 sm:grid-cols-2 max-w-md'}`}>
                <label className="block text-xs">
                  <span className="block font-bold text-slate-600 pb-1.5">Tháng làm việc</span>
                  <select
                    value={filters.month}
                    onChange={e => setFilters({ ...filters, month: Number(e.target.value) })}
                    className="w-full rounded-xl border border-slate-300 bg-slate-50/50 px-3 py-2.5 text-xs font-bold text-slate-800 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                  >
                    {Array.from({ length: 12 }, (_, i) => i + 1).map(m => (
                      <option key={m} value={m}>Tháng {m < 10 ? `0${m}` : m}</option>
                    ))}
                  </select>
                </label>

                <label className="block text-xs">
                  <span className="block font-bold text-slate-600 pb-1.5">Năm</span>
                  <select
                    value={filters.year}
                    onChange={e => setFilters({ ...filters, year: Number(e.target.value) })}
                    className="w-full rounded-xl border border-slate-300 bg-slate-50/50 px-3 py-2.5 text-xs font-bold text-slate-800 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                  >
                    {/* Hệ thống bắt đầu năm 2026; sang 2027 thì 2027 tự xuất hiện. */}
                    {Array.from(
                      { length: new Date().getFullYear() - 2025 },
                      (_, i) => 2026 + i
                    ).map(y => (
                      <option key={y} value={y}>Năm {y}</option>
                    ))}
                  </select>
                </label>

                {activeTab === 'company' && (
                <label className="block text-xs">
                  <span className="block font-bold text-slate-600 pb-1.5">Phòng ban</span>
                  <select
                    value={draft.dept}
                    onChange={e => setDraft({ ...draft, dept: e.target.value })}
                    className="w-full rounded-xl border border-slate-300 bg-slate-50/50 px-3 py-2.5 text-xs font-bold text-slate-800 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                  >
                    <option value="ALL">Tất cả phòng ban</option>
                    {DEPARTMENTS.map(d => (
                      <option key={d.dbName} value={d.dbName}>{d.label}</option>
                    ))}
                  </select>
                </label>
                )}

                {activeTab === 'company' && (
                <label className="block text-xs">
                  <span className="block font-bold text-slate-600 pb-1.5">Tìm kiếm nhân sự</span>
                  <span className="relative block">
                    <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" aria-hidden="true" />
                    <input
                      type="search"
                      value={draft.keyword}
                      onChange={e => setDraft({ ...draft, keyword: e.target.value })}
                      placeholder="Tìm theo tên, mã NV..."
                      className="w-full rounded-xl border border-slate-300 bg-slate-50/50 py-2.5 pl-9 pr-3 text-xs text-slate-800 placeholder:text-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                    />
                  </span>
                </label>
                )}
              </div>

              {activeTab === 'company' && (
              <div className="flex flex-wrap items-center justify-between gap-3 pt-4">
                <span className="text-xs text-slate-500">
                  Tổng quỹ lương chi trả: <strong className="text-emerald-700 font-black text-sm">
                    {formatVND(companyRows.reduce((sum, p) => sum + (p.netPay || 0), 0))}
                  </strong>
                </span>
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => {
                      setDraft({ dept: 'ALL', keyword: '' });
                      // Xoá cả filter đã áp dụng, không chỉ form — trước đây bảng vẫn giữ
                      // kỳ lọc cũ nên người dùng tưởng mất hàng của chính mình.
                      setFilters({ ...filters, dept: 'ALL', keyword: '' });
                      setSelectedIds([]);
                    }}
                    className="rounded-xl border border-slate-300 bg-white px-4 py-2.5 text-xs font-bold text-slate-700 hover:bg-slate-50 transition cursor-pointer"
                  >
                    Đặt lại
                  </button>
                  <button
                    onClick={() => { setFilters({ ...filters, ...draft }); setSelectedIds([]); }}
                    className="flex items-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 text-xs font-bold shadow-sm transition cursor-pointer"
                  >
                    <Search className="w-4 h-4" aria-hidden="true" />
                    Tra cứu bảng lương
                  </button>
                </div>
              </div>
              )}
            </div>


        {/* Tab 1: My Payslip */}
        {activeTab === 'my' && (
          <div className="space-y-6">
            {hasPayroll && myPayslip ? (
              <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80 max-w-3xl mx-auto">
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between pb-6 border-b border-slate-200 gap-4">
                  <div>
                    <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200">
                      Phiếu Lương Điện Tử
                    </span>
                    <h2 className="text-xl font-black text-slate-900 mt-2">
                      Kỳ Lương Tháng {myPayslip.periodMonth}/{myPayslip.periodYear}
                    </h2>
                    <p className="text-xs text-slate-500">
                      Nhân viên: <strong>{myPayslip.employeeName || currentUser?.fullName}</strong> ({myPayslip.employeeCode || currentUser?.employeeCode}) • {myPayslip.job || currentUser?.job}
                    </p>
                  </div>
                  <div className="text-left sm:text-right">
                    <span className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-bold ${
                      String(myPayslip.status).toUpperCase() === 'PAID'
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-blue-100 text-blue-800'
                    }`}>
                      {String(myPayslip.status).toUpperCase() === 'PAID' ? 'Đã chuyển khoản' : String(myPayslip.status).toUpperCase() === 'APPROVED' ? 'Đã phê duyệt' : 'Nháp'}
                    </span>
                    <p className="text-[11px] text-slate-400 mt-1">Ngày quyết toán: {formatDateVN(myPayslip.calculatedAt) || '26/08/2026'}</p>
                  </div>
                </div>

                {/* Net Salary Highlight Banner */}
                <div className="my-6 rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-700 p-6 text-white text-center shadow-lg shadow-emerald-500/20">
                  <span className="text-xs font-semibold text-emerald-100 uppercase tracking-wider">
                    Lương Thực Nhận
                  </span>
                  <div className="mt-1 text-3xl sm:text-4xl font-black">
                    {formatVND(myPayslip.netPay)}
                  </div>
                  {String(myPayslip.status).toUpperCase() === 'PAID' && (
                    <p className="mt-1 text-xs text-emerald-200">
                      Đã chuyển vào số tài khoản ngân hàng đã đăng ký
                    </p>
                  )}
                </div>

                {/* Breakdown Table */}
                <div className="space-y-4 text-xs">
                  <h4 className="font-bold text-slate-800 uppercase tracking-wider text-[11px]">
                    1. Chi tiết Thu Nhập
                  </h4>
                  <div className="divide-y divide-slate-100 bg-slate-50 rounded-2xl p-4 border border-slate-200/80">
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Lương thỏa thuận cơ bản:</span>
                      <span className="font-bold text-slate-800">{formatVND(myPayslip.baseSalary)}</span>
                    </div>
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Lương công nhật thực tế:</span>
                      <span className="font-bold text-slate-800">{formatVND(myPayslip.basicPay)}</span>
                    </div>
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Tiền làm thêm giờ:</span>
                      <span className="font-bold text-emerald-600">+{formatVND(myPayslip.overtimePay)}</span>
                    </div>
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Phụ cấp ăn trưa, điện thoại & xăng xe:</span>
                      <span className="font-bold text-emerald-600">+{formatVND(myPayslip.allowancePay)}</span>
                    </div>
                    {(myPayslip.bonusPay || 0) > 0 && (
                      <div className="flex justify-between py-2">
                        <span className="text-slate-600">Tiền thưởng (Bonus):</span>
                        <span className="font-bold text-emerald-600">+{formatVND(myPayslip.bonusPay)}</span>
                      </div>
                    )}
                    {(myPayslip.grossPay || 0) > 0 && (
                      <div className="flex justify-between py-2">
                        <span className="text-slate-600">Tổng thu nhập trước thuế:</span>
                        <span className="font-bold text-slate-800">{formatVND(myPayslip.grossPay)}</span>
                      </div>
                    )}
                    {(myPayslip.hourlyRate || 0) > 0 && (
                      <div className="flex justify-between py-2">
                        <span className="text-slate-600">Lương theo giờ:</span>
                        <span className="font-bold text-slate-800">{formatVND(myPayslip.hourlyRate)}</span>
                      </div>
                    )}
                  </div>

                  <h4 className="font-bold text-slate-800 uppercase tracking-wider text-[11px] pt-2">
                    2. Các Khoản Khấu Trừ
                  </h4>
                  <div className="divide-y divide-slate-100 bg-slate-50 rounded-2xl p-4 border border-slate-200/80">
                    <div className="flex justify-between py-2">
                      <span className="text-slate-600">Bảo hiểm xã hội, BHYT & BHTN (10.5%):</span>
                      <span className="font-bold text-red-600">-{formatVND(myPayslip.deductionPay)}</span>
                    </div>
                    {(myPayslip.taxDeduction || 0) > 0 && (
                      <div className="flex justify-between py-2">
                        <span className="text-slate-600">Thuế TNCN:</span>
                        <span className="font-bold text-red-600">-{formatVND(myPayslip.taxDeduction)}</span>
                      </div>
                    )}
                    {(myPayslip.otherDeduction || 0) > 0 && (
                      <div className="flex justify-between py-2">
                        <span className="text-slate-600">Khấu trừ khác:</span>
                        <span className="font-bold text-red-600">-{formatVND(myPayslip.otherDeduction)}</span>
                      </div>
                    )}
                  </div>
                  {(myPayslip.note || myPayslip.paidAt) && (
                    <p className="text-[11px] text-slate-500">
                      {myPayslip.note && <span>Ghi chú: {myPayslip.note} </span>}
                      {myPayslip.paidAt && <span className="font-mono">• Đã trả: {formatDateVN(myPayslip.paidAt)}</span>}
                    </p>
                  )}
                </div>
              </div>
            ) : (
              <div className="p-12 text-center text-xs text-slate-500 bg-white rounded-3xl border border-slate-200">
                <p className="font-bold text-slate-700 text-sm">Chưa có lương cho {periodLabel}</p>
                <p className="mt-1.5">Bảng lương kỳ này chưa được tính hoặc thời gian làm việc chưa được chốt.</p>
              </div>
            )}
          </div>
        )}

        {/* Tab 2: Company All (Ban Giám đốc / Kế toán) */}
        {activeTab === 'company' && canViewCompanyPayroll && (
          <div className="space-y-4">
            <div className="flex items-center gap-2.5 flex-wrap">
              <button
                onClick={handleRunPayroll}
                disabled={isOpenPeriod || (companyRows.length > 0 && selectableIds.length === 0)}
                title={isOpenPeriod
                  ? 'Kỳ chưa kết thúc — chỉ tính lương được kỳ đã qua'
                  : companyRows.length === 0
                    ? 'Tạo bảng lương cho kỳ này (cần bảng chấm công đã chốt sổ)'
                    : selectableIds.length === 0
                      ? 'Không còn bảng lương Nháp nào để tính lại'
                      : selectedIds.length > 0
                        ? `Tính lại cho ${selectedIds.length} nhân viên đã chọn`
                        : 'Tính lại theo bộ lọc đang xem'}
                className="flex items-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
              >
                <Calculator className="h-4 w-4" />
                <span>
                  {selectedIds.length > 0
                    ? `Tính lại ${selectedIds.length} dòng đã chọn`
                    : 'Chạy Tính Lương Tự Động'}
                </span>
              </button>
              {canApprovePayroll && (
                <>
                  <button
                    onClick={() => setApproveConfirm(true)}
                    disabled={!hasPayrollData || isOpenPeriod}
                    title={isOpenPeriod
                      ? 'Kỳ chưa kết thúc — chưa có bảng lương để phê duyệt'
                      : !hasPayrollData
                        ? 'Chưa có dữ liệu lương — bấm "Chạy Tính Lương Tự Động" trước'
                        : undefined}
                    className="flex items-center gap-2 rounded-xl bg-amber-600 hover:bg-amber-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-2.5 text-xs font-bold shadow-md transition cursor-pointer"
                  >
                    <CheckCircle2 className="h-4 w-4" />
                    <span>Phê duyệt</span>
                  </button>
                  <button
                    onClick={handleMarkPaid}
                    disabled={!hasPayrollData || isOpenPeriod}
                    title={isOpenPeriod
                      ? 'Kỳ chưa kết thúc — chưa có bảng lương để chi trả'
                      : !hasPayrollData
                        ? 'Chưa có dữ liệu lương để chi trả'
                        : undefined}
                    className="flex items-center gap-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-2.5 text-xs font-bold shadow-md transition cursor-pointer"
                  >
                    <DollarSign className="h-4 w-4" />
                    <span>Xác nhận Chi trả</span>
                  </button>
                </>
              )}
              <button
                onClick={handleExportExcel}
                disabled={!hasPayrollData || isOpenPeriod}
                title={isOpenPeriod
                  ? 'Kỳ chưa kết thúc — chưa có bảng lương để xuất'
                  : !hasPayrollData
                    ? 'Chưa có dữ liệu lương để xuất'
                    : undefined}
                className="flex items-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-emerald-500/20 transition cursor-pointer"
              >
                <FileSpreadsheet className="h-4 w-4" />
                <span>Xuất Bảng Lương (Excel)</span>
              </button>
            </div>
            <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3 pl-4 pr-2 w-12">
                        <input
                          type="checkbox"
                          aria-label="Chọn tất cả nhân viên đang hiển thị"
                          checked={selectableIds.length > 0 && selectableIds.every(id => selectedIds.includes(id))}
                          ref={el => { if (el) el.indeterminate = selectableIds.some(id => selectedIds.includes(id)) && !selectableIds.every(id => selectedIds.includes(id)); }}
                          onChange={toggleAll}
                          className="w-4 h-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500 cursor-pointer"
                        />
                      </th>
                      <th className="py-3 px-2.5">Mã NV</th>
                      <th className="py-3 px-2.5">Họ tên</th>
                      <th className="py-3 px-2.5">Phòng ban</th>
                      <th className="py-3 px-2.5 text-right">Lương Cơ Bản</th>
                      <th className="py-3 px-2.5 text-right">Tiền Lương</th>
                      <th className="py-3 px-2.5 text-right">Tiền OT</th>
                      <th className="py-3 px-2.5 text-right">Phụ Cấp</th>
                      <th className="py-3 px-2.5 text-right">Bảo Hiểm</th>
                      <th className="py-3 px-2.5 text-right">Thuế TNCN</th>
                      <th className="py-3 px-2.5 text-right">Lương Thực Nhận</th>
                      <th className="py-3 px-2.5 text-center">Trạng Thái</th>
                      <th className="py-3 px-2.5 text-center">Thao tác</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {companyRows.length === 0 && (
                      <tr><td colSpan={12} className="py-8 text-center text-xs text-slate-400">Chưa có dữ liệu lương cho kỳ này.</td></tr>
                    )}
                    {companyRows.map(item => {
                      const isMe = isSelf(item.userId);
                      const isDraft = String(item.status).toUpperCase() === 'DRAFT';
                      const checked = selectedIds.includes(item.userId);
                      const numCell = 'py-3 px-2.5 text-right font-mono tabular-nums whitespace-nowrap';
                      return (
                      <tr
                        key={item.payrollId}
                        className={checked ? 'bg-blue-50/70 transition' : isMe ? 'bg-blue-50/40 hover:bg-blue-50/70 transition' : 'hover:bg-slate-50/80 transition'}
                      >
                        <td className="py-3 pl-4 pr-2 text-center">
                          <input
                            type="checkbox"
                            aria-label={`Chọn bảng lương của ${item.employeeName}`}
                            checked={checked}
                            disabled={!isDraft}
                            onChange={() => toggleRow(item.userId)}
                            className="w-4 h-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500 cursor-pointer disabled:cursor-not-allowed disabled:opacity-40"
                          />
                        </td>
                        <td className="py-3 px-2.5 font-mono text-[11px] text-slate-500">{item.employeeCode}</td>
                        <td className="py-3 px-2.5 font-bold text-slate-900 whitespace-nowrap">
                          {item.employeeName}
                          {isMe && (
                            <span className="ml-1.5 inline-flex align-middle rounded-full bg-blue-600 px-1.5 py-0.5 text-[9px] font-black uppercase tracking-wide text-white">
                              Bạn
                            </span>
                          )}
                        </td>
                        <td className="py-3 px-2.5 text-slate-600">{item.department}</td>
                        <td className={`${numCell} font-medium text-slate-700`}>{formatVND(item.baseSalary)}</td>
                        <td className={`${numCell} font-bold ${moneyTone(item.grossPay, 'add')}`}>
                          {signedMoney(item.grossPay, 'add')}
                        </td>
                        <td className={`${numCell} font-bold ${moneyTone(item.overtimePay, 'add')}`}>
                          {signedMoney(item.overtimePay, 'add')}
                        </td>
                        <td className={`${numCell} font-bold ${moneyTone(item.allowancePay, 'add')}`}>
                          {signedMoney(item.allowancePay, 'add')}
                        </td>
                        <td className={`${numCell} font-bold ${moneyTone(item.insuranceDeduction, 'sub')}`}>
                          {signedMoney(item.insuranceDeduction, 'sub')}
                        </td>
                        <td className={`${numCell} font-bold ${moneyTone(item.taxDeduction, 'sub')}`}>
                          {signedMoney(item.taxDeduction, 'sub')}
                        </td>
                        <td className={`${numCell} font-black text-sm ${moneyTone(item.netPay, 'auto')}`}>
                          {signedMoney(item.netPay, 'auto')}
                        </td>
                        <td className="py-3 px-2.5 text-center">
                          {String(item.status).toUpperCase() === 'PAID' ? (
                            <span className="inline-flex whitespace-nowrap rounded-full bg-emerald-100 text-emerald-800 px-2 py-0.5 text-[10px] font-bold">
                              Đã trả
                            </span>
                          ) : String(item.status).toUpperCase() === 'APPROVED' ? (
                            <span className="inline-flex whitespace-nowrap rounded-full bg-blue-100 text-blue-800 px-2 py-0.5 text-[10px] font-bold">
                              Đã duyệt
                            </span>
                          ) : (
                            <span className="inline-flex whitespace-nowrap rounded-full bg-slate-100 text-slate-600 px-2 py-0.5 text-[10px] font-bold">
                              Nháp
                            </span>
                          )}
                        </td>
                        <td className="py-3 px-2.5 text-center">
                          {canEditPayroll && isDraft ? (
                            <button
                              onClick={() => openEditPayroll(item)}
                              aria-label={`Chỉnh sửa bảng lương của ${item.employeeName}`}
                              title="Chỉnh sửa phụ cấp / thưởng / khấu trừ"
                              className="inline-flex items-center gap-1 rounded-lg border border-slate-300 px-2 py-1 text-[10px] font-bold text-slate-700 hover:bg-slate-50 transition cursor-pointer whitespace-nowrap"
                            >
                              <Pencil className="w-3 h-3" aria-hidden="true" />
                              Sửa
                            </button>
                          ) : (
                            <span className="text-slate-300 text-[10px]">—</span>
                          )}
                        </td>
                      </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Xác nhận trước khi phê duyệt — không hoàn tác được */}
        <ConfirmDialog
          open={approveConfirm}
          busy={approving}
          title={`Phê duyệt bảng lương Tháng ${filters.month}/${filters.year}?`}
          body={`${companyRows.length} bảng lương trong bảng đang xem sẽ chuyển sang trạng thái Đã duyệt. Sau bước này bảng lương bị khoá số liệu, không sửa phụ cấp / thưởng / khấu trừ được nữa.`}
          confirmLabel="Phê duyệt"
          onClose={() => !approving && setApproveConfirm(false)}
          onConfirm={handleApprovePayroll}
        />

        {/* Modal chỉnh sửa bảng lương — backend tự tính lại gross / thuế / net */}
        {editing && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-lg rounded-3xl bg-white p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
              <button
                onClick={() => setEditing(null)}
                aria-label="Đóng"
                className="absolute right-4 top-4 rounded-full p-1 text-slate-400 hover:bg-slate-100 transition"
              >
                <X className="w-5 h-5" />
              </button>
              <h2 className="text-lg font-black text-slate-900 mb-1">Chỉnh sửa bảng lương</h2>
              <p className="text-xs text-slate-500 mb-5">
                {editing.employeeName} ({editing.employeeCode}) · kỳ {periodLabel}
              </p>

              <form onSubmit={handleSaveEdit} className="space-y-3 text-xs">
                {[
                  { key: 'allowancePay', label: 'Phụ cấp (thêm vào thu nhập)' },
                  { key: 'bonusPay', label: 'Tiền thưởng' },
                  { key: 'otherDeduction', label: 'Khấu trừ khác' }
                ].map(f => (
                  <label key={f.key} className="block">
                    <span className="block font-bold text-slate-700 mb-1">{f.label}</span>
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      value={(editForm as any)[f.key]}
                      onChange={e => setEditForm({ ...editForm, [f.key]: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                    />
                  </label>
                ))}

                <label className="block">
                  <span className="block font-bold text-slate-700 mb-1">
                    Thuế TNCN (để trống = hệ thống tự tính)
                  </span>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={editForm.taxDeduction}
                    onChange={e => setEditForm({ ...editForm, taxDeduction: e.target.value })}
                    placeholder="Tự tính"
                    className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                  />
                </label>

                <label className="block">
                  <span className="block font-bold text-slate-700 mb-1">Ghi chú</span>
                  <textarea
                    rows={2}
                    maxLength={500}
                    value={editForm.note}
                    onChange={e => setEditForm({ ...editForm, note: e.target.value })}
                    className="w-full rounded-xl border border-slate-300 p-2.5 focus:border-blue-600 focus:outline-hidden"
                  />
                </label>

                <div className="flex items-center justify-end gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setEditing(null)}
                    className="rounded-xl border border-slate-300 px-4 py-2.5 font-bold text-slate-700 hover:bg-slate-50 transition cursor-pointer"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={savingEdit}
                    className="rounded-xl bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white px-5 py-2.5 font-bold shadow-sm transition cursor-pointer"
                  >
                    {savingEdit ? 'Đang lưu…' : 'Lưu thay đổi'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}

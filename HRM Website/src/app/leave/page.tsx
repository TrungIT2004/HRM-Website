'use client';

import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { LeaveRequest, LeaveRequestStatus, User } from '@/types';
import { leaveService, LeaveFilterParams } from '@/services/leaveService';
import { formatDateVN } from '@/utils/format';
import { DATE_PRESETS, DatePreset, dateRangeFor, fillDateInputs } from '@/utils/dateRange';
import { useTabFromUrl } from '@/utils/useTabFromUrl';
import { DEPARTMENTS } from '@/constants/departments';
import {
  CalendarDays,
  Plus,
  CheckCircle2,
  XCircle,
  Clock,
  AlertCircle,
  Calendar,
  Sparkles,
  Search,
  Filter,
  Trash2,
  FileCheck,
  Building2,
  User as UserIcon,
  X,
  Send,
  RefreshCw,
  ChevronLeft,
  ChevronRight,
  Download
} from 'lucide-react';

interface PreviewInfo {
  requestedLeaveDays: number;
  workDays: number;
  restDays: number;
  holidayDays: number;
  remainingAnnualLeaveDays: number;
  remainingAfterThisRequest: number;
  isSufficientAnnualLeave: boolean;
}

function computeLocalPreview(user: User | null, fromDateStr: string, toDateStr: string): PreviewInfo {
  const from = new Date(fromDateStr);
  const to = new Date(toDateStr);
  if (isNaN(from.getTime()) || isNaN(to.getTime()) || from > to) {
    const rem = user ? (user.annualLeaveDays - user.usedLeaveDays) : 12;
    return {
      requestedLeaveDays: 0,
      workDays: 0,
      restDays: 0,
      holidayDays: 0,
      remainingAnnualLeaveDays: rem,
      remainingAfterThisRequest: rem,
      isSufficientAnnualLeave: true
    };
  }
  let cur = new Date(from);
  let totalDays = 0;
  let workDays = 0;
  let restDays = 0;
  while (cur <= to) {
    totalDays++;
    const day = cur.getDay();
    if (day === 0 || day === 6) {
      restDays++;
    } else {
      workDays++;
    }
    cur.setDate(cur.getDate() + 1);
  }
  const remaining = user ? (user.annualLeaveDays - user.usedLeaveDays) : 12;
  const remainingAfter = remaining - workDays;
  return {
    requestedLeaveDays: totalDays,
    workDays,
    restDays,
    holidayDays: 0,
    remainingAnnualLeaveDays: remaining,
    remainingAfterThisRequest: remainingAfter,
    isSufficientAnnualLeave: remainingAfter >= 0
  };
}

export default function LeavePage() {
  const { currentUser, isHR, isManager, isExecutive, can, isLoading: isAuthLoading } = useAuth();

  const [activeTab, setActiveTab] = useTabFromUrl(['my', 'approvals', 'company'] as const, 'my');
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [exporting, setExporting] = useState(false);

  // Leave records list & pagination
  const [requests, setRequests] = useState<LeaveRequest[]>([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [totalElements, setTotalElements] = useState(0);

  // Form states for creating leave request
  // Không cho xin nghỉ quá khứ hoặc hôm nay → mốc nhỏ nhất là ngày mai
  const minLeaveDate = useMemo(() => {
    const d = new Date();
    d.setDate(d.getDate() + 1);
    return d.toISOString().split('T')[0];
  }, []);
  const [fromDate, setFromDate] = useState(minLeaveDate);
  const [toDate, setToDate] = useState(minLeaveDate);
  const [reason, setReason] = useState('');
  const [paidLeaveDays, setPaidLeaveDays] = useState(1);
  const [previewData, setPreviewData] = useState<PreviewInfo | null>(null);

  // Filter states — formRef reads values directly on submit
  const filterFormRef = useRef<HTMLFormElement>(null);
  const [appliedFilters, setAppliedFilters] = useState({
    status: 'ALL',
    fromDate: '',
    toDate: '',
    keyword: '',
    dept: 'ALL'
  });

  const handleApplyFilters = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const fd = new FormData(filterFormRef.current!);
    setPage(0);
    setAppliedFilters({
      status: fd.get('status') as string || 'ALL',
      fromDate: fd.get('fromDate') as string || '',
      toDate: fd.get('toDate') as string || '',
      keyword: fd.get('keyword') as string || '',
      dept: fd.get('dept') as string || 'ALL'
    });
  };

  const handleResetFilters = () => {
    filterFormRef.current?.reset();
    setPage(0);
    setAppliedFilters({ status: 'ALL', fromDate: '', toDate: '', keyword: '', dept: 'ALL' });
  };

  // Xem nhanh: Hôm nay / Tuần này / Tháng này — set luôn 2 input + áp dụng ngay.
  const applyDatePreset = (preset: DatePreset) => {
    const range = dateRangeFor(preset);
    fillDateInputs(filterFormRef.current, range, ['fromDate', 'toDate']);
    setPage(0);
    setAppliedFilters(prev => ({ ...prev, fromDate: range.startDate, toDate: range.endDate }));
  };

  const [rejectingReq, setRejectingReq] = useState<LeaveRequest | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  const [toastMsg, setToastMsg] = useState('');

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };


  // Reset tab if role switches.
  // ponytail: phải chờ isAuthLoading — nếu không, lúc mount useAuth() còn chưa có
  // profile thì isManager=false/can() rỗng → đẩy tab về 'my' trước khi dữ liệu về,
  // làm hỏng cả deep-link ?tab=approvals.
  useEffect(() => {
    if (isAuthLoading) return;
    if (!isHR && !can('LEAVE_VIEW_ALL') && activeTab === 'company') {
      setActiveTab('my');
    }
    if (!isManager && !isExecutive && !can('LEAVE_APPROVE') && activeTab === 'approvals') {
      setActiveTab('my');
    }
  }, [isAuthLoading, isHR, isManager, isExecutive, can, activeTab]);

  // Load live preview from backend when fromDate/toDate change
  useEffect(() => {
    if (!fromDate || !toDate) return;
    let isMounted = true;

    leaveService.previewLeave(fromDate, toDate)
      .then(res => {
        if (!isMounted) return;
        if (res && typeof res.workDays === 'number') {
          setPreviewData({
            requestedLeaveDays: res.requestedLeaveDays ?? 0,
            workDays: res.workDays,
            restDays: res.restDays ?? 0,
            holidayDays: res.holidayDays ?? 0,
            remainingAnnualLeaveDays: res.remainingAnnualLeaveDays ?? (currentUser ? currentUser.annualLeaveDays - currentUser.usedLeaveDays : 12),
            remainingAfterThisRequest: res.remainingAfterThisRequest ?? (res.remainingAnnualLeaveDays - res.workDays),
            isSufficientAnnualLeave: res.isSufficientAnnualLeave ?? true
          });
          setPaidLeaveDays(res.workDays);
        }
      })
      .catch(() => {
        if (!isMounted) return;
        // Fallback to local computation
        const local = computeLocalPreview(currentUser, fromDate, toDate);
        setPreviewData(local);
        setPaidLeaveDays(local.workDays);
      });

    return () => {
      isMounted = false;
    };
  }, [fromDate, toDate, currentUser]);

  // Fetch leaves from Backend
  const fetchLeaves = useCallback(async () => {
    setLoading(true);
    try {
      const params: LeaveFilterParams = {
        page,
        size: 10,
        status: appliedFilters.status !== 'ALL' ? appliedFilters.status : undefined,
        fromDate: appliedFilters.fromDate || undefined,
        toDate: appliedFilters.toDate || undefined,
        keyword: appliedFilters.keyword || undefined
      };

      if (activeTab === 'company' && appliedFilters.dept !== 'ALL') {
        params.departmentNames = [appliedFilters.dept];
      }

      let res: any;
      if (activeTab === 'my') {
        res = await leaveService.getMyLeaves(params);
      } else if (activeTab === 'approvals') {
        res = await leaveService.getDepartmentLeaves(params);
      } else {
        res = await leaveService.getCompanyLeaves(params);
      }

      if (res && Array.isArray(res.content)) {
        setRequests(res.content);
        setTotalPages(res.totalPages || 1);
        setTotalElements(res.totalElements || res.content.length);
      } else if (Array.isArray(res)) {
        setRequests(res);
        setTotalPages(1);
        setTotalElements(res.length);
      } else {
        setRequests([]);
      }
    } catch {
      // Fallback empty
      setRequests([]);
    } finally {
      setLoading(false);
    }
  }, [activeTab, page, appliedFilters]);

  useEffect(() => {
    fetchLeaves();
  }, [fetchLeaves]);

  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser) return;

    // Chỉ ngày CÓ LƯƠNG mới tiêu quỹ phép năm → kiểm tra theo paidLeaveDays, không theo workDays
    if (previewData && paidLeaveDays > previewData.remainingAnnualLeaveDays) {
      showToast('Cảnh báo: Số ngày nghỉ có lương vượt quá quỹ phép năm còn lại của bạn!');
      return;
    }

    setSubmitting(true);
    try {
      await leaveService.createLeave({
        fromDate,
        toDate,
        reason: reason || 'Nghỉ giải quyết công việc cá nhân',
        paidLeaveDays
      });
      showToast('Đã gửi đơn xin nghỉ phép thành công! Đang chờ Quản lý phê duyệt.');
      setIsCreateModalOpen(false);
      setReason('');
      fetchLeaves();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Có lỗi xảy ra khi tạo đơn');
    } finally {
      setSubmitting(false);
    }
  };

  const handleApprove = async (req: LeaveRequest) => {
    try {
      await leaveService.approveLeave(req.requestId);
      showToast(`Đã duyệt đơn nghỉ phép cho ${req.requestorName || 'nhân viên'}`);
      fetchLeaves();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Không thể phê duyệt đơn');
    }
  };

  const handleRejectSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!rejectingReq) return;
    try {
      await leaveService.rejectLeave(rejectingReq.requestId, rejectionReason || 'Không phù hợp với kế hoạch công việc');
      showToast(`Đã từ chối đơn nghỉ phép của ${rejectingReq.requestorName || 'nhân viên'}`);
      setRejectingReq(null);
      setRejectionReason('');
      fetchLeaves();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Không thể từ chối đơn');
    }
  };

  const handleCancel = async (requestId: string) => {
    if (!confirm('Bạn có chắc chắn muốn hủy đơn nghỉ phép này không?')) return;
    try {
      await leaveService.cancelLeave(requestId);
      showToast('Đã hủy đơn xin nghỉ phép thành công');
      fetchLeaves();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Không thể hủy đơn');
    }
  };

  const handleExport = async () => {
    setExporting(true);
    try {
      const blob = await leaveService.exportExcel({
        fromDate: appliedFilters.fromDate || undefined,
        toDate: appliedFilters.toDate || undefined,
        status: appliedFilters.status !== 'ALL' ? appliedFilters.status : undefined,
        keyword: appliedFilters.keyword || undefined
      });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `Bao_Cao_Nghi_Phep_${new Date().toISOString().split('T')[0]}.xlsx`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
      showToast('Tải xuống báo cáo nghỉ phép Excel thành công!');
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Xuất báo cáo thất bại');
    } finally {
      setExporting(false);
    }
  };

  const statusBadge = (status: LeaveRequestStatus | string) => {
    const s = String(status).toLowerCase();
    switch (s) {
      case 'accepted':
        return (
          <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 px-2.5 py-0.5 text-[11px] font-bold">
            <CheckCircle2 className="w-3 h-3 text-emerald-600" />
            Đã duyệt
          </span>
        );
      case 'rejected':
        return (
          <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 text-rose-700 border border-rose-200 px-2.5 py-0.5 text-[11px] font-bold">
            <XCircle className="w-3 h-3 text-rose-600" />
            Từ chối
          </span>
        );
      case 'pending':
      default:
        return (
          <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 px-2.5 py-0.5 text-[11px] font-bold">
            <Clock className="w-3 h-3 text-amber-600" />
            Chờ duyệt
          </span>
        );
    }
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
            <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full border border-blue-200 mb-2">
              <CalendarDays className="h-3.5 w-3.5" />
              <span>Phân hệ Nghỉ Phép Tự Động</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Quản Lý Đơn Xin Nghỉ Phép
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Tính toán ngày nghỉ tự động trừ cuối tuần & ngày lễ, kiểm tra quỹ phép năm tức thời và quy trình duyệt phân cấp.
            </p>
          </div>

          <div className="flex items-center gap-2.5 flex-wrap">
            <button
              onClick={() => setIsCreateModalOpen(true)}
              className="inline-flex items-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
            >
              <Plus className="h-4 w-4" />
              <span>Tạo đơn nghỉ phép mới</span>
            </button>

            {(isHR || can('LEAVE_VIEW_ALL')) && (
              <button
                onClick={handleExport}
                disabled={exporting}
                className="flex items-center gap-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-emerald-500/20 transition cursor-pointer disabled:opacity-60"
              >
                {exporting ? (
                  <RefreshCw className="h-4 w-4 animate-spin" />
                ) : (
                  <Download className="h-4 w-4" />
                )}
                <span>Xuất Báo Cáo (Excel)</span>
              </button>
            )}
          </div>
        </div>

        {/* Quota Summary Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="rounded-2xl bg-white p-5 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Tổng Quỹ Phép Năm</span>
              <div className="mt-1 text-2xl font-black text-slate-900">
                {currentUser?.annualLeaveDays ?? 12} ngày
              </div>
            </div>
            <div className="p-3 rounded-xl bg-blue-50 text-blue-600"><Calendar className="h-6 w-6" /></div>
          </div>

          <div className="rounded-2xl bg-white p-5 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Phép Đã Sử Dụng</span>
              <div className="mt-1 text-2xl font-black text-amber-600">
                {currentUser?.usedLeaveDays ?? 0} ngày
              </div>
            </div>
            <div className="p-3 rounded-xl bg-amber-50 text-amber-600"><Clock className="h-6 w-6" /></div>
          </div>

          <div className="rounded-2xl bg-white p-5 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Phép Còn Lại</span>
              <div className="mt-1 text-2xl font-black text-emerald-600">
                {(currentUser?.annualLeaveDays ?? 12) - (currentUser?.usedLeaveDays ?? 0)} ngày
              </div>
            </div>
            <div className="p-3 rounded-xl bg-emerald-50 text-emerald-600"><CheckCircle2 className="h-6 w-6" /></div>
          </div>
        </div>

        {/* Tabs */}
        <div className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-xs font-bold">
          <button
            onClick={() => { setActiveTab('my'); setPage(0); }}
            className={`px-4 py-2 rounded-xl transition cursor-pointer ${
              activeTab === 'my' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            Đơn của tôi
          </button>
          {(isManager || isExecutive || can('LEAVE_APPROVE')) && (
            <button
              onClick={() => { setActiveTab('approvals'); setPage(0); }}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'approvals' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <span>Hộp thư Duyệt đơn</span>
            </button>
          )}
          {(isHR || can('LEAVE_VIEW_ALL')) && (
            <button
              onClick={() => { setActiveTab('company'); setPage(0); }}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                activeTab === 'company' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              Toàn công ty
            </button>
          )}
        </div>

        {/* Filter Toolbar */}
        <form ref={filterFormRef} onSubmit={handleApplyFilters} className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
              <Filter className="h-4 w-4 text-blue-600" />
              <span>Bộ lọc đơn nghỉ phép</span>
            </div>
            {(appliedFilters.status !== 'ALL' || appliedFilters.fromDate || appliedFilters.toDate || appliedFilters.keyword || appliedFilters.dept !== 'ALL') && (
              <button
                type="button"
                onClick={handleResetFilters}
                className="text-xs text-blue-600 hover:text-blue-800 font-semibold cursor-pointer"
              >
                Xóa bộ lọc
              </button>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-2 text-xs">
            <span className="text-[11px] font-medium text-slate-500">Xem nhanh:</span>
            {DATE_PRESETS.map(([key, label]) => (
              <button
                key={key}
                type="button"
                onClick={() => applyDatePreset(key)}
                className="px-3 py-1 rounded-full border border-slate-200 text-slate-600 hover:bg-blue-50 hover:text-blue-700 hover:border-blue-300 font-semibold transition cursor-pointer"
              >
                {label}
              </button>
            ))}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 text-xs">
            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">Từ ngày</label>
              <input
                type="date"
                name="fromDate"
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden font-mono"
              />
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">Đến ngày</label>
              <input
                type="date"
                name="toDate"
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden font-mono"
              />
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">Trạng thái đơn</label>
              <select
                name="status"
                defaultValue="ALL"
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
              >
                <option value="ALL">Tất cả trạng thái</option>
                <option value="pending">Đang chờ duyệt</option>
                <option value="accepted">Đã chấp thuận</option>
                <option value="rejected">Đã từ chối</option>
              </select>
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">
                {activeTab === 'company' ? 'Phòng ban' : 'Tìm kiếm'}
              </label>
              {activeTab === 'company' ? (
                <select
                  name="dept"
                  defaultValue="ALL"
                  className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
                >
                  <option value="ALL">Tất cả phòng ban</option>
                  {DEPARTMENTS.map(d => (
                    <option key={d.dbName} value={d.dbName}>{d.label}</option>
                  ))}
                </select>
              ) : (
                <div className="relative">
                  <Search className="h-4 w-4 text-slate-400 absolute left-2.5 top-2.5" />
                  <input
                    type="text"
                    name="keyword"
                    placeholder="Tìm tên, mã, lý do..."
                    className="w-full rounded-xl border border-slate-200 py-2 pl-8 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                  />
                </div>
              )}
            </div>

            {activeTab === 'company' && (
              <div className="sm:col-span-12">
                <div className="relative">
                  <Search className="h-4 w-4 text-slate-400 absolute left-3 top-2.5" />
                  <input
                    type="text"
                    name="keyword"
                    placeholder="Tìm kiếm theo tên nhân viên, mã nhân viên, lý do nghỉ..."
                    className="w-full rounded-xl border border-slate-200 py-2 pl-9 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                  />
                </div>
              </div>
            )}
          </div>

          <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
            <button
              type="button"
              onClick={handleResetFilters}
              className="px-3.5 py-1.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-xs font-semibold transition cursor-pointer"
            >
              Đặt lại
            </button>
            <button
              type="submit"
              className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-xs transition cursor-pointer"
            >
              <Search className="h-3.5 w-3.5" />
              <span>Tìm kiếm & Lọc</span>
            </button>
          </div>
        </form>


        {/* Content Container */}
        <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-4 border-b border-slate-100 flex items-center justify-between">
            <h3 className="text-xs font-bold text-slate-800">
              {activeTab === 'my' && 'Lịch sử nộp đơn của tôi'}
              {activeTab === 'approvals' && 'Danh sách đơn cần phê duyệt cấp quản lý'}
              {activeTab === 'company' && 'Theo dõi nghỉ phép toàn công ty'}
            </h3>
            <span className="text-xs font-semibold text-slate-500">
              {loading ? 'Đang tải...' : `${totalElements} bản ghi`}
            </span>
          </div>

          {loading ? (
            <div className="py-12 flex flex-col items-center justify-center gap-2 text-slate-400 text-xs">
              <RefreshCw className="h-6 w-6 animate-spin text-blue-600" />
              <span>Đang tải danh sách đơn nghỉ phép...</span>
            </div>
          ) : requests.length === 0 ? (
            <div className="py-12 text-center text-slate-400 text-xs">
              Không tìm thấy đơn xin nghỉ phép nào phù hợp với bộ lọc.
            </div>
          ) : (
            <>
              {/* MOBILE CARDS VIEW (block md:hidden) */}
              <div className="block md:hidden divide-y divide-slate-100">
                {requests.map(req => (
                  <div key={req.requestId} className="p-4 space-y-3">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        {activeTab !== 'my' && (
                          <div className="font-bold text-slate-900 text-sm">{req.requestorName || 'Nhân viên'}</div>
                        )}
                        <div className="text-[11px] font-mono text-slate-500 font-semibold">
                          {formatDateVN(req.fromDate)} → {formatDateVN(req.toDate)}
                        </div>
                      </div>
                      <div>{statusBadge(req.status)}</div>
                    </div>

                    <div className="flex items-center gap-2 text-xs">
                      <span className="font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded border border-blue-100">
                        {req.paidLeaveDays} ngày phép
                      </span>
                      {req.requestorDepartment && (
                        <span className="text-slate-500 text-[11px] truncate">{req.requestorDepartment}</span>
                      )}
                    </div>

                    <div className="text-xs text-slate-600 bg-slate-50 p-2.5 rounded-xl border border-slate-100">
                      <span className="font-medium text-slate-700">Lý do: </span>
                      {req.reason}
                      {req.rejectionReason && (
                        <div className="text-rose-600 font-semibold text-[11px] mt-1">
                          Lý do từ chối: {req.rejectionReason}
                        </div>
                      )}
                    </div>

                    <div className="flex items-center justify-between pt-1">
                      <div className="text-[10px] text-slate-400">
                        {req.approverName ? `Người duyệt: ${req.approverName} (${req.approverJob || 'Quản lý'})` : 'Chờ phân công'}
                      </div>

                      {activeTab === 'approvals' && req.status === 'pending' && (
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => handleApprove(req)}
                            className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs shadow-xs"
                          >
                            Duyệt
                          </button>
                          <button
                            onClick={() => {
                              setRejectingReq(req);
                              setRejectionReason('');
                            }}
                            className="px-3 py-1.5 rounded-xl bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold text-xs border border-rose-200"
                          >
                            Từ chối
                          </button>
                        </div>
                      )}

                      {activeTab === 'my' && req.status === 'pending' && (
                        <button
                          onClick={() => handleCancel(req.requestId)}
                          className="px-3 py-1.5 rounded-xl bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold text-xs border border-rose-200"
                        >
                          Hủy đơn
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {/* DESKTOP TABLE VIEW (hidden md:block) */}
              <div className="hidden md:block overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      {activeTab !== 'my' && <th className="py-3 px-4">Mã NV</th>}
                      {activeTab !== 'my' && <th className="py-3 px-4">Họ tên</th>}
                      {activeTab !== 'my' && <th className="py-3 px-4">Vị trí</th>}
                      {activeTab === 'company' && <th className="py-3 px-4">Phòng ban</th>}
                      <th className="py-3 px-4">Thời gian nghỉ</th>
                      <th className="py-3 px-4 text-center">Số ngày trừ phép</th>
                      <th className="py-3 px-4">Lý do</th>
                      <th className="py-3 px-4">Người duyệt</th>
                      <th className="py-3 px-4">Trạng thái</th>
                      <th className="py-3 px-4 text-right">Thao tác</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {requests.map(req => (
                      <tr key={req.requestId} className="hover:bg-slate-50/80 transition">
                        {activeTab !== 'my' && (
                          <td className="py-3 px-4 font-mono text-[11px] text-slate-500">{req.requestorCode}</td>
                        )}
                        {activeTab !== 'my' && (
                          <td className="py-3 px-4 font-bold text-slate-900">{req.requestorName}</td>
                        )}
                        {activeTab !== 'my' && (
                          <td className="py-3 px-4 text-slate-600">{req.requestorJob || '—'}</td>
                        )}
                        {activeTab === 'company' && (
                          <td className="py-3 px-4 text-slate-600">{req.requestorDepartment}</td>
                        )}
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900 font-mono">{formatDateVN(req.fromDate)} → {formatDateVN(req.toDate)}</div>
                          <div className="text-[10px] text-slate-400" title={req.requestId}>Nộp: {formatDateVN(req.createdAt) || 'Gần đây'}</div>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <span className="font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded border border-blue-100">
                            {req.paidLeaveDays} ngày
                          </span>
                        </td>
                        <td className="py-3 px-4 text-slate-600 max-w-xs">
                          <div>{req.reason}</div>
                          {req.rejectionReason && (
                            <div className="text-[11px] text-rose-600 font-medium mt-0.5">Lý do từ chối: {req.rejectionReason}</div>
                          )}
                        </td>
                        <td className="py-3 px-4 text-slate-600" title={req.approverId || ''}>
                          {req.approverName ? `${req.approverName} (${req.approverJob || 'Quản lý'})` : 'Chờ phân công'}
                        </td>
                        <td className="py-3 px-4">
                          {statusBadge(req.status)}
                        </td>
                        <td className="py-3 px-4 text-right">
                          {activeTab === 'approvals' && req.status === 'pending' && (
                            <div className="flex items-center justify-end gap-2">
                              <button
                                onClick={() => handleApprove(req)}
                                className="rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 text-xs font-bold transition cursor-pointer shadow-xs"
                              >
                                Duyệt
                              </button>
                              <button
                                onClick={() => {
                                  setRejectingReq(req);
                                  setRejectionReason('');
                                }}
                                className="rounded-xl bg-rose-50 hover:bg-rose-100 text-rose-700 px-3 py-1.5 text-xs font-bold transition cursor-pointer border border-rose-200"
                              >
                                Từ chối
                              </button>
                            </div>
                          )}
                          {activeTab === 'my' && req.status === 'pending' && (
                            <button
                              onClick={() => handleCancel(req.requestId)}
                              className="text-rose-600 hover:text-rose-800 font-bold text-xs cursor-pointer"
                            >
                              Hủy đơn
                            </button>
                          )}
                          {req.status !== 'pending' && <span className="text-slate-400">—</span>}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="p-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
              <span>Trang {page + 1} / {totalPages}</span>
              <div className="flex items-center gap-1">
                <button
                  disabled={page === 0}
                  onClick={() => setPage(p => Math.max(0, p - 1))}
                  className="p-1.5 rounded-lg border border-slate-200 hover:bg-slate-50 disabled:opacity-40"
                >
                  <ChevronLeft className="h-4 w-4" />
                </button>
                <button
                  disabled={page >= totalPages - 1}
                  onClick={() => setPage(p => p + 1)}
                  className="p-1.5 rounded-lg border border-slate-200 hover:bg-slate-50 disabled:opacity-40"
                >
                  <ChevronRight className="h-4 w-4" />
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Modal Tạo Đơn Nghỉ Phép Mới */}
        {isCreateModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 overflow-y-auto">
            <div className="relative w-full max-w-xl rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto my-8">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2 text-blue-600 font-bold text-sm">
                  <CalendarDays className="h-5 w-5" />
                  <span>Tạo Đơn Xin Nghỉ Phép</span>
                </div>
                <button
                  onClick={() => setIsCreateModalOpen(false)}
                  className="rounded-full p-1 text-slate-400 hover:bg-slate-100 transition"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <form onSubmit={handleCreateSubmit} className="mt-4 space-y-4 text-xs">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Từ ngày</label>
                    <input
                      type="date"
                      value={fromDate}
                      min={minLeaveDate}
                      onChange={e => {
                        const next = e.target.value;
                        setFromDate(next);
                        if (toDate < next) setToDate(next);
                      }}
                      required
                      className="w-full rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Đến ngày</label>
                    <input
                      type="date"
                      value={toDate}
                      min={fromDate || minLeaveDate}
                      onChange={e => setToDate(e.target.value)}
                      required
                      className="w-full rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                    />
                  </div>
                </div>

                {/* Live Preview Box */}
                {previewData && (
                  <div className="rounded-2xl bg-blue-50/70 p-4 border border-blue-100 space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-blue-900 flex items-center gap-1.5">
                        <Sparkles className="h-4 w-4 text-blue-600" />
                        <span>Xem trước tính toán ngày phép</span>
                      </span>
                    </div>

                    <div className="grid grid-cols-3 gap-2 text-[11px] pt-1">
                      <div className="bg-white p-2 rounded-lg border border-blue-100 text-center">
                        <span className="text-slate-400 block">Tổng ngày lịch:</span>
                        <span className="font-bold text-slate-900 text-xs">{previewData.requestedLeaveDays} ngày</span>
                      </div>
                      <div className="bg-white p-2 rounded-lg border border-blue-100 text-center">
                        <span className="text-slate-400 block">Nghỉ T7/CN & Lễ:</span>
                        <span className="font-bold text-amber-600 text-xs">{previewData.restDays + previewData.holidayDays} ngày</span>
                      </div>
                      <div className="bg-white p-2 rounded-lg border border-blue-100 text-center">
                        <span className="text-blue-600 block font-bold">Thực tính nghỉ:</span>
                        <span className="font-black text-blue-700 text-xs">{previewData.workDays} ngày</span>
                      </div>
                    </div>

                    <div className="pt-2 border-t border-blue-200/60 flex items-center justify-between text-[11px]">
                      <span>Quỹ phép còn lại: <strong>{previewData.remainingAnnualLeaveDays} ngày</strong></span>
                      <span>Sau khi nghỉ còn: <strong className={previewData.remainingAfterThisRequest < 0 ? 'text-rose-600' : 'text-emerald-700'}>{previewData.remainingAfterThisRequest} ngày</strong></span>
                    </div>

                    {!previewData.isSufficientAnnualLeave && (
                      <div className="flex items-center gap-1 text-[11px] font-bold text-rose-600">
                        <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                        <span>Số ngày nghỉ vượt quá quỹ phép năm còn lại của bạn!</span>
                      </div>
                    )}
                  </div>
                )}

                <div>
                  <label htmlFor="paidLeaveDays" className="block font-bold text-slate-700 mb-1">
                    Số ngày nghỉ có lương
                  </label>
                  <div className="flex items-center gap-3">
                    <input
                      id="paidLeaveDays"
                      type="number"
                      inputMode="numeric"
                      min={0}
                      max={previewData ? Math.min(previewData.workDays, previewData.remainingAnnualLeaveDays) : undefined}
                      value={paidLeaveDays}
                      onChange={e => {
                        const n = Number(e.target.value);
                        setPaidLeaveDays(Number.isFinite(n) ? Math.max(0, Math.trunc(n)) : 0);
                      }}
                      required
                      className="w-24 rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                    />
                    <span className="text-[11px] text-slate-500">
                      {previewData
                        ? `Tối đa ${Math.min(previewData.workDays, previewData.remainingAnnualLeaveDays)} / ${previewData.workDays} ngày làm việc. Phần còn lại tính là nghỉ không lương.`
                        : 'Chọn khoảng ngày nghỉ để xem số ngày làm việc.'}
                    </span>
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Lý do xin nghỉ</label>
                  <textarea
                    rows={3}
                    value={reason}
                    onChange={e => setReason(e.target.value)}
                    required
                    placeholder="Nhập lý do chi tiết (ví dụ: việc gia đình, khám sức khỏe, giải quyết việc riêng...)"
                    className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
                  />
                </div>

                <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2.5">
                  <button
                    type="button"
                    onClick={() => setIsCreateModalOpen(false)}
                    className="rounded-xl px-4 py-2 font-bold text-slate-600 hover:bg-slate-100 transition"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={submitting || (previewData ? !previewData.isSufficientAnnualLeave : false)}
                    className="flex items-center gap-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white px-5 py-2 font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
                  >
                    {submitting ? (
                      <>
                        <RefreshCw className="h-4 w-4 animate-spin" />
                        <span>Đang gửi đơn...</span>
                      </>
                    ) : (
                      <>
                        <Send className="h-4 w-4" />
                        <span>Gửi đơn xin nghỉ</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Modal Từ Chối Đơn Nghỉ */}
        {rejectingReq && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl border border-slate-200">
              <h3 className="text-sm font-bold text-rose-600 flex items-center gap-2 mb-2">
                <XCircle className="h-5 w-5" />
                <span>Từ chối đơn xin nghỉ phép</span>
              </h3>
              <p className="text-xs text-slate-600 mb-4">
                Nhân viên: <strong>{rejectingReq.requestorName}</strong> ({formatDateVN(rejectingReq.fromDate)} → {formatDateVN(rejectingReq.toDate)})
              </p>

              <form onSubmit={handleRejectSubmit} className="space-y-4 text-xs">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Lý do từ chối (Bắt buộc)</label>
                  <textarea
                    rows={3}
                    value={rejectionReason}
                    onChange={e => setRejectionReason(e.target.value)}
                    required
                    placeholder="Nhập lý do từ chối để thông báo lại cho nhân viên..."
                    className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
                  />
                </div>

                <div className="flex items-center justify-end gap-2.5 pt-2">
                  <button
                    type="button"
                    onClick={() => setRejectingReq(null)}
                    className="rounded-xl px-4 py-2 font-bold text-slate-600 hover:bg-slate-100 transition"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    className="rounded-xl bg-rose-600 hover:bg-rose-700 text-white px-5 py-2 font-bold transition cursor-pointer"
                  >
                    Xác nhận từ chối
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

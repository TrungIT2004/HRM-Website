'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { LeaveRequest, OvertimeRecord } from '@/types';
import { leaveService } from '@/services/leaveService';
import { overtimeService } from '@/services/overtimeService';
import { formatDateVN } from '@/utils/format';
import { DATE_PRESETS, DatePreset, dateRangeFor, fillDateInputs } from '@/utils/dateRange';
import {
  CalendarDays,
  Briefcase,
  CheckCircle2,
  XCircle,
  Clock,
  Filter,
  Search,
  ExternalLink,
  Plus,
  AlertCircle,
  FileCheck,
  ChevronRight,
  Download
} from 'lucide-react';

export default function LeaveOvertimeHubTab({ scope }: { scope?: 'dept' | 'company' }) {
  const { currentUser, isHR, isManager, isExecutive, can } = useAuth();
  const canCompanyLeave = isHR || isExecutive || can('LEAVE_VIEW_ALL');
  const canDeptLeave = isManager || can('LEAVE_VIEW_DEPT') || can('LEAVE_APPROVE_DEPT');
  const canCompanyOt = isHR || isExecutive || can('OVERTIME_VIEW_ALL');
  const canDeptOt = isManager || can('OVERTIME_VIEW_DEPT') || can('OVERTIME_APPROVE_DEPT');
  // ponytail: scope do workspace truyền xuống (tabs Công ty/Phòng ban); không có = suy từ quyền như cũ
  const leaveScope = scope ?? (canCompanyLeave ? 'company' : 'dept');
  const otScope = scope ?? (canCompanyOt ? 'company' : 'dept');
  const canApproveLeave = isManager || isHR || isExecutive || can('LEAVE_APPROVE') || can('LEAVE_APPROVE_DEPT');
  const canApproveOt = isManager || isHR || isExecutive || can('OVERTIME_APPROVE') || can('OVERTIME_APPROVE_DEPT');

  const [subTab, setSubTab] = useState<'leave' | 'ot'>('leave');

  // Leave Requests state
  const [leaveRequests, setLeaveRequests] = useState<LeaveRequest[]>([]);
  const [isLeaveLoading, setIsLeaveLoading] = useState(false);

  // Overtime Requests state
  const [otRecords, setOtRecords] = useState<OvertimeRecord[]>([]);
  const [isOtLoading, setIsOtLoading] = useState(false);

  const [toastMsg, setToastMsg] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');
  const [exporting, setExporting] = useState(false);

  // ponytail: 1 thanh lọc duy nhất mỗi subtab (ngày + trạng thái + tìm kiếm) — submit mới lọc
  const leaveFormRef = useRef<HTMLFormElement>(null);
  const otFormRef = useRef<HTMLFormElement>(null);
  const [leaveApplied, setLeaveApplied] = useState({ status: 'ALL', fromDate: '', toDate: '', keyword: '' });
  const [otApplied, setOtApplied] = useState({ status: 'ALL', fromDate: '', toDate: '', keyword: '' });

  const readFilterForm = (form: HTMLFormElement | null) => {
    const fd = new FormData(form!);
    return {
      status: fd.get('status') as string || 'ALL',
      fromDate: fd.get('fromDate') as string || '',
      toDate: fd.get('toDate') as string || '',
      keyword: fd.get('keyword') as string || ''
    };
  };

  const applyLeaveFilters = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    setLeaveApplied(readFilterForm(leaveFormRef.current));
  };

  const resetLeaveFilters = () => {
    leaveFormRef.current?.reset();
    setLeaveApplied({ status: 'ALL', fromDate: '', toDate: '', keyword: '' });
  };

  const applyLeavePreset = (p: DatePreset) => {
    const r = dateRangeFor(p);
    fillDateInputs(leaveFormRef.current, r);
    setLeaveApplied(prev => ({ ...prev, fromDate: r.startDate, toDate: r.endDate }));
  };

  const applyOtFilters = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    setOtApplied(readFilterForm(otFormRef.current));
  };

  const resetOtFilters = () => {
    otFormRef.current?.reset();
    setOtApplied({ status: 'ALL', fromDate: '', toDate: '', keyword: '' });
  };

  const applyOtPreset = (p: DatePreset) => {
    const r = dateRangeFor(p);
    fillDateInputs(otFormRef.current, r);
    setOtApplied(prev => ({ ...prev, fromDate: r.startDate, toDate: r.endDate }));
  };

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToastMsg(msg);
    setToastType(type);
    setTimeout(() => setToastMsg(''), 3000);
  };

  const fetchLeaves = async () => {
    setIsLeaveLoading(true);
    try {
      const params = {
        size: 100,
        status: leaveApplied.status !== 'ALL' ? leaveApplied.status : undefined,
        fromDate: leaveApplied.fromDate || undefined,
        toDate: leaveApplied.toDate || undefined,
        keyword: leaveApplied.keyword || undefined
      };
      let res;
      if (leaveScope === 'company' && canCompanyLeave) {
        res = await leaveService.getCompanyLeaves(params);
      } else if (leaveScope === 'dept' && canDeptLeave) {
        res = await leaveService.getDepartmentLeaves(params);
      } else {
        res = await leaveService.getMyLeaves(params);
      }
      setLeaveRequests(Array.isArray(res?.content) ? res.content : []);
    } catch {
      setLeaveRequests([]);
    } finally {
      setIsLeaveLoading(false);
    }
  };

  const fetchOvertimes = async () => {
    setIsOtLoading(true);
    try {
      const params = {
        size: 100,
        status: otApplied.status !== 'ALL' ? otApplied.status : undefined,
        fromDate: otApplied.fromDate || undefined,
        toDate: otApplied.toDate || undefined,
        keyword: otApplied.keyword || undefined
      };
      let res;
      if (otScope === 'company' && canCompanyOt) {
        res = await overtimeService.getCompanyOvertimes(params);
      } else if (otScope === 'dept' && canDeptOt) {
        res = await overtimeService.getDepartmentOvertimes(params);
      } else {
        res = await overtimeService.getMyOvertimes(params);
      }
      setOtRecords(Array.isArray(res?.content) ? res.content : []);
    } catch {
      setOtRecords([]);
    } finally {
      setIsOtLoading(false);
    }
  };

  useEffect(() => {
    if (subTab === 'leave') {
      fetchLeaves();
    } else {
      fetchOvertimes();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [subTab, leaveApplied, otApplied, scope]);

  const handleApproveLeave = async (requestId: string) => {
    try {
      await leaveService.approveLeave(requestId);
      showToast('Đã phê duyệt đơn nghỉ phép thành công');
      fetchLeaves();
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi duyệt đơn', 'error');
    }
  };

  const handleRejectLeave = async (requestId: string) => {
    const reason = prompt('Nhập lý do từ chối đơn:');
    if (reason === null) return;
    try {
      await leaveService.rejectLeave(requestId, reason || 'Không phù hợp với kế hoạch nhân sự');
      showToast('Đã từ chối đơn nghỉ phép');
      fetchLeaves();
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi từ chối đơn', 'error');
    }
  };

  const handleApproveOt = async (recordId: string) => {
    try {
      await overtimeService.approveOvertime(recordId);
      showToast('Đã phê duyệt đơn làm thêm giờ thành công');
      fetchOvertimes();
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi duyệt đơn tăng ca', 'error');
    }
  };

  const handleRejectOt = async (recordId: string) => {
    const reason = prompt('Nhập lý do từ chối:');
    if (reason === null) return;
    try {
      await overtimeService.rejectOvertime(recordId, reason || 'Không đủ căn cứ tăng ca');
      showToast('Đã từ chối đơn làm thêm giờ');
      fetchOvertimes();
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi từ chối', 'error');
    }
  };

  const appliedToExport = (a: typeof leaveApplied) => ({
    status: a.status !== 'ALL' ? a.status : undefined,
    fromDate: a.fromDate || undefined,
    toDate: a.toDate || undefined,
    keyword: a.keyword || undefined
  });

  const doExport = async (kind: 'leave' | 'ot') => {
    setExporting(true);
    try {
      if (kind === 'leave') await leaveService.exportExcel(appliedToExport(leaveApplied));
      else await overtimeService.exportExcel(appliedToExport(otApplied));
      showToast(`Đã xuất Excel ${kind === 'leave' ? 'đơn nghỉ phép' : 'đơn làm thêm giờ'}.`);
    } catch (e: any) { showToast(e.message || 'Xuất Excel thất bại.', 'error'); }
    finally { setExporting(false); }
  };

  // ponytail: lọc server-side qua applied params — không lọc lại ở client
  const pendingLeaveCount = leaveRequests.filter(l => l.status === 'pending').length;
  const pendingOtCount = otRecords.filter(o => o.status === 'pending').length;

  // 1 thanh lọc đầy đủ (ngày + trạng thái + tìm kiếm) — header đổi theo subtab
  const fullFilterBar = (kind: 'leave' | 'ot') => {
    const isLeave = kind === 'leave';
    const applied = isLeave ? leaveApplied : otApplied;
    const hasActive = applied.status !== 'ALL' || applied.fromDate || applied.toDate || applied.keyword;
    return (
      <form
        ref={isLeave ? leaveFormRef : otFormRef}
        onSubmit={isLeave ? applyLeaveFilters : applyOtFilters}
        className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
            <Filter className="h-4 w-4 text-orange-600" />
            <span>{isLeave ? 'Bộ lọc đơn nghỉ phép' : 'Bộ lọc đơn làm thêm giờ'}</span>
          </div>
          <div className="flex items-center gap-2">
            {hasActive && (
              <button
                type="button"
                onClick={isLeave ? resetLeaveFilters : resetOtFilters}
                className="text-xs text-orange-600 hover:text-orange-800 font-semibold cursor-pointer"
              >
                Xóa bộ lọc
              </button>
            )}
            {(isLeave ? canCompanyLeave : canCompanyOt) && (
              <button
                type="button"
                onClick={() => doExport(kind)}
                disabled={exporting}
                className="flex items-center gap-1 px-3 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-xs font-bold shadow-xs transition cursor-pointer disabled:opacity-50"
              >
                <Download className="h-3.5 w-3.5" />
                <span>Xuất Excel</span>
              </button>
            )}
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2 text-xs">
          <span className="text-[11px] font-medium text-slate-500">Xem nhanh:</span>
          {DATE_PRESETS.map(([k, label]) => (
            <button
              key={k}
              type="button"
              onClick={() => (isLeave ? applyLeavePreset : applyOtPreset)(k)}
              className="px-3 py-1 rounded-full border border-slate-200 text-slate-600 hover:bg-orange-50 hover:text-orange-700 hover:border-orange-300 font-semibold transition cursor-pointer"
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
              className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-orange-500 focus:outline-hidden font-mono"
            />
          </div>
          <div className="sm:col-span-3">
            <label className="block text-[11px] font-medium text-slate-500 mb-1">Đến ngày</label>
            <input
              type="date"
              name="toDate"
              className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-orange-500 focus:outline-hidden font-mono"
            />
          </div>
          <div className="sm:col-span-3">
            <label className="block text-[11px] font-medium text-slate-500 mb-1">Trạng thái đơn</label>
            <select
              name="status"
              defaultValue="ALL"
              className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-orange-500 focus:outline-hidden"
            >
              <option value="ALL">Tất cả trạng thái</option>
              <option value="pending">Chờ duyệt</option>
              <option value="accepted">Đã duyệt</option>
              <option value="rejected">Từ chối</option>
            </select>
          </div>
          <div className="sm:col-span-3">
            <label className="block text-[11px] font-medium text-slate-500 mb-1">Tìm kiếm</label>
            <div className="relative">
              <Search className="h-4 w-4 text-slate-400 absolute left-2.5 top-2.5" />
              <input
                type="text"
                name="keyword"
                placeholder="Tìm người nộp, lý do..."
                className="w-full rounded-xl border border-slate-200 py-2 pl-8 pr-3 text-xs text-slate-800 focus:border-orange-500 focus:outline-hidden"
              />
            </div>
          </div>
        </div>

        <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
          <button
            type="button"
            onClick={isLeave ? resetLeaveFilters : resetOtFilters}
            className="px-3.5 py-1.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-xs font-semibold transition cursor-pointer"
          >
            Đặt lại
          </button>
          <button
            type="submit"
            className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-xs font-bold shadow-xs transition cursor-pointer"
          >
            <Search className="h-3.5 w-3.5" />
            <span>Tìm kiếm & Lọc</span>
          </button>
        </div>
      </form>
    );
  };

  return (
    <div className="space-y-6">
      {/* Toast message */}
      {toastMsg && (
        <div
          className={`p-3 rounded-xl border text-xs font-semibold flex items-center gap-2 ${
            toastType === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-700'
              : 'bg-rose-50 border-rose-200 text-rose-700'
          }`}
        >
          {toastType === 'success' ? (
            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
          ) : (
            <AlertCircle className="h-4 w-4 text-rose-600" />
          )}
          <span>{toastMsg}</span>
        </div>
      )}

      {/* Sub-tab selection bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setSubTab('leave')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition cursor-pointer ${
              subTab === 'leave'
                ? 'bg-orange-600 text-white shadow-md shadow-orange-500/20'
                : 'text-slate-600 hover:bg-slate-100'
            }`}
          >
            <CalendarDays className="h-4 w-4" />
            <span>Đơn Nghỉ Phép</span>
            {pendingLeaveCount > 0 && (
              <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-white text-orange-600 font-extrabold">
                {pendingLeaveCount}
              </span>
            )}
          </button>

          <button
            onClick={() => setSubTab('ot')}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition cursor-pointer ${
              subTab === 'ot'
                ? 'bg-orange-600 text-white shadow-md shadow-orange-500/20'
                : 'text-slate-600 hover:bg-slate-100'
            }`}
          >
            <Briefcase className="h-4 w-4" />
            <span>Đơn Làm Thêm Giờ (OT)</span>
            {pendingOtCount > 0 && (
              <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-white text-orange-600 font-extrabold">
                {pendingOtCount}
              </span>
            )}
          </button>
        </div>

        {/* Deep link button to full module */}
        <Link
          href={subTab === 'leave' ? '/attendance/leave' : '/attendance/overtime'}
          className="inline-flex items-center gap-1.5 text-xs font-bold text-orange-600 hover:text-orange-700 bg-orange-50 hover:bg-orange-100/80 px-3 py-1.5 rounded-xl border border-orange-200/80 transition"
        >
          <span>Mở giao diện {subTab === 'leave' ? 'Nghỉ phép' : 'Làm thêm giờ'} chi tiết</span>
          <ExternalLink className="h-3.5 w-3.5" />
        </Link>
      </div>

      {/* Leave Section */}
      {subTab === 'leave' && (
        <div className="space-y-4">
          {fullFilterBar('leave')}

          {/* Table */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Nhân sự nộp đơn</th>
                    <th className="py-3 px-4">Thời gian nghỉ</th>
                    <th className="py-3 px-4">Số ngày</th>
                    <th className="py-3 px-4">Lý do</th>
                    <th className="py-3 px-4">Trạng thái</th>
                    {canApproveLeave && <th className="py-3 px-4 text-right">Phê duyệt</th>}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {isLeaveLoading ? (
                    <tr>
                      <td colSpan={6} className="py-8 text-center text-xs text-slate-400">
                        Đang tải danh sách đơn nghỉ phép...
                      </td>
                    </tr>
                  ) : leaveRequests.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="py-8 text-center text-xs text-slate-400">
                        Không có đơn nghỉ phép nào phù hợp.
                      </td>
                    </tr>
                  ) : (
                    leaveRequests.map(leave => (
                      <tr key={leave.requestId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4">
                          <p className="font-bold text-slate-900">{leave.requestorName}</p>
                          <p className="text-[10px] text-slate-400">
                            {leave.requestorCode} - {leave.requestorDepartment}
                          </p>
                        </td>
                        <td className="py-3 px-4 font-mono text-[11px]">
                          {formatDateVN(leave.fromDate)} → {formatDateVN(leave.toDate)}
                        </td>
                        <td className="py-3 px-4 font-bold text-slate-900">
                          {leave.paidLeaveDays || leave.totalWorkingDays || 1} ngày
                        </td>
                        <td className="py-3 px-4 max-w-xs truncate text-slate-600">
                          {leave.reason}
                        </td>
                        <td className="py-3 px-4">
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                              leave.status === 'accepted'
                                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                : leave.status === 'rejected'
                                  ? 'bg-rose-50 text-rose-700 border border-rose-200'
                                  : 'bg-amber-50 text-amber-700 border border-amber-200'
                            }`}
                          >
                            {leave.status === 'accepted'
                              ? 'Đã duyệt'
                              : leave.status === 'rejected'
                                ? 'Từ chối'
                                : 'Chờ duyệt'}
                          </span>
                        </td>
                        {canApproveLeave && (
                          <td className="py-3 px-4 text-right">
                            {leave.status === 'pending' ? (
                              <div className="flex items-center justify-end gap-1.5">
                                <button
                                  onClick={() => handleApproveLeave(leave.requestId)}
                                  className="px-2.5 py-1 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-[11px] transition cursor-pointer"
                                >
                                  Duyệt
                                </button>
                                <button
                                  onClick={() => handleRejectLeave(leave.requestId)}
                                  className="px-2.5 py-1 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-600 font-bold text-[11px] border border-rose-200 transition cursor-pointer"
                                >
                                  Từ chối
                                </button>
                              </div>
                            ) : (
                              <span className="text-[11px] text-slate-400">
                                {leave.approverName ? `Bởi ${leave.approverName}` : 'Hoàn tất'}
                              </span>
                            )}
                          </td>
                        )}
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Overtime Section */}
      {subTab === 'ot' && (
        <div className="space-y-4">
          {fullFilterBar('ot')}

          {/* Table */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Nhân sự tăng ca</th>
                    <th className="py-3 px-4">Ngày làm thêm</th>
                    <th className="py-3 px-4">Khung giờ</th>
                    <th className="py-3 px-4">Số giờ OT</th>
                    <th className="py-3 px-4">Nội dung công việc</th>
                    <th className="py-3 px-4">Trạng thái</th>
                    {canApproveOt && <th className="py-3 px-4 text-right">Phê duyệt</th>}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {isOtLoading ? (
                    <tr>
                      <td colSpan={7} className="py-8 text-center text-xs text-slate-400">
                        Đang tải danh sách đơn tăng ca...
                      </td>
                    </tr>
                  ) : otRecords.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-8 text-center text-xs text-slate-400">
                        Không có đơn làm thêm giờ nào phù hợp.
                      </td>
                    </tr>
                  ) : (
                    otRecords.map(ot => (
                      <tr key={ot.overtimeRecordId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4">
                          <p className="font-bold text-slate-900">{ot.requestorName}</p>
                          <p className="text-[10px] text-slate-400">
                            {ot.requestorCode} - {ot.requestorDepartment}
                          </p>
                        </td>
                        <td className="py-3 px-4 font-mono text-[11px]">
                          {formatDateVN(ot.approvedDate)}
                        </td>
                        <td className="py-3 px-4 font-mono text-[11px] text-slate-600">
                          {ot.approvedStartTime?.substring(0, 5)} - {ot.approvedEndTime?.substring(0, 5)}
                        </td>
                        <td className="py-3 px-4 font-bold text-orange-600 font-mono">
                          {ot.registeredHours || ot.totalApprovedHours || 0} giờ
                        </td>
                        <td className="py-3 px-4 max-w-xs truncate text-slate-600">
                          {ot.reason}
                        </td>
                        <td className="py-3 px-4">
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                              ot.status === 'accepted'
                                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                : ot.status === 'rejected'
                                  ? 'bg-rose-50 text-rose-700 border border-rose-200'
                                  : 'bg-amber-50 text-amber-700 border border-amber-200'
                            }`}
                          >
                            {ot.status === 'accepted'
                              ? 'Đã duyệt'
                              : ot.status === 'rejected'
                                ? 'Từ chối'
                                : 'Chờ duyệt'}
                          </span>
                        </td>
                        {canApproveOt && (
                          <td className="py-3 px-4 text-right">
                            {ot.status === 'pending' ? (
                              <div className="flex items-center justify-end gap-1.5">
                                <button
                                  onClick={() => handleApproveOt(ot.overtimeRecordId)}
                                  className="px-2.5 py-1 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-[11px] transition cursor-pointer"
                                >
                                  Duyệt
                                </button>
                                <button
                                  onClick={() => handleRejectOt(ot.overtimeRecordId)}
                                  className="px-2.5 py-1 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-600 font-bold text-[11px] border border-rose-200 transition cursor-pointer"
                                >
                                  Từ chối
                                </button>
                              </div>
                            ) : (
                              <span className="text-[11px] text-slate-400">
                                {ot.approverName ? `Bởi ${ot.approverName}` : 'Hoàn tất'}
                              </span>
                            )}
                          </td>
                        )}
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

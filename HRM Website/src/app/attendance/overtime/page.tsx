'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { OvertimeRecord, OvertimeStatus } from '@/types';
import { overtimeService, OvertimeFilterParams, OvertimePreview } from '@/services/overtimeService';
import { formatDateVN } from '@/utils/format';
import { DATE_PRESETS, DatePreset, dateRangeFor, fillDateInputs } from '@/utils/dateRange';
import ConfirmDialog from '@/components/ConfirmDialog';
import { DEPARTMENTS } from '@/constants/departments';
import {
  Briefcase,
  Plus,
  CheckCircle2,
  XCircle,
  Clock,
  AlertCircle,
  Trash2,
  Sparkles,
  Building2,
  Calendar,
  X,
  Send,
  Moon,
  Filter,
  Search,
  RefreshCw,
  ChevronLeft,
  ChevronRight,
  Download
} from 'lucide-react';

const OT_PRESETS = [
  { label: '+1h', start: '18:00', end: '19:00' },
  { label: '+2h', start: '18:00', end: '20:00' },
  { label: '+3h', start: '18:00', end: '21:00' },
  { label: 'Ca đêm 22h–06h', start: '22:00', end: '06:00' }
];

function otTypeLabel(p: OvertimePreview): string {
  if (p.isHoliday) return p.isNightTime ? 'Lễ + Đêm' : 'Ngày lễ';
  if (p.isWeekend) return p.isNightTime ? 'Cuối tuần + Đêm' : 'Cuối tuần';
  return p.isNightTime ? 'Thường + Đêm' : 'Ngày thường';
}

export default function OvertimePage() {
  const { currentUser, isHR, isManager, isExecutive, can, isLoading: isAuthLoading } = useAuth();

  // ponytail: trang đơn cá nhân — scope cố định 'my', duyệt đơn nằm bên /management/requests
  const activeTab = 'my' as const;
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [exporting, setExporting] = useState(false);

  // OT Records list & pagination
  const [records, setRecords] = useState<OvertimeRecord[]>([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [totalElements, setTotalElements] = useState(0);

  // OT Request form states
  const todayStr = new Date().toISOString().split('T')[0];
  const [otDate, setOtDate] = useState(todayStr);
  const [startTime, setStartTime] = useState('18:00');
  const [endTime, setEndTime] = useState('21:00');
  const [reason, setReason] = useState('');

  // Filter states — formRef reads values on submit
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

  // ponytail: trang đơn cá nhân — modal từ chối của luồng duyệt đã chuyển sang /management/requests

  const [toastMsg, setToastMsg] = useState('');

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };


  // ponytail: scope cố định 'my' nên không cần effect reset tab theo role

  // Hệ số & thời gian OT do backend tính (OvertimeRecord.setFlags + calcOvertimeAmounts).
  // Frontend KHÔNG tự tính lại — trước đây làm sai ca xuyên đêm và thiếu hệ số ngày lễ.
  const [preview, setPreview] = useState<OvertimePreview | null>(null);
  const [previewLoading, setPreviewLoading] = useState(false);

  useEffect(() => {
    if (!otDate || !startTime || !endTime) return;
    let isMounted = true;
    setPreviewLoading(true);
    overtimeService.previewOvertime(otDate, startTime, endTime)
      .then(res => { if (isMounted) setPreview(res); })
      .catch(() => { if (isMounted) setPreview(null); })
      .finally(() => { if (isMounted) setPreviewLoading(false); });
    return () => { isMounted = false; };
  }, [otDate, startTime, endTime]);

  const totalHours = preview?.totalHours ?? 0;

  // Fetch OT records từ Backend — chỉ đơn của chính mình
  const fetchOvertimes = useCallback(async () => {
    setLoading(true);
    try {
      const params: OvertimeFilterParams = {
        page,
        size: 10,
        status: appliedFilters.status !== 'ALL' ? appliedFilters.status : undefined,
        fromDate: appliedFilters.fromDate || undefined,
        toDate: appliedFilters.toDate || undefined,
        keyword: appliedFilters.keyword || undefined
      };

      const res: any = await overtimeService.getMyOvertimes(params);

      if (res && Array.isArray(res.content)) {
        setRecords(res.content);
        setTotalPages(res.totalPages || 1);
        setTotalElements(res.totalElements || res.content.length);
      } else if (Array.isArray(res)) {
        setRecords(res);
        setTotalPages(1);
        setTotalElements(res.length);
      } else {
        setRecords([]);
      }
    } catch {
      setRecords([]);
    } finally {
      setLoading(false);
    }
  }, [page, appliedFilters]);

  useEffect(() => {
    fetchOvertimes();
  }, [fetchOvertimes]);

  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser) return;

    if (totalHours <= 0) {
      showToast('Thời gian kết thúc phải sau thời gian bắt đầu!');
      return;
    }

    setSubmitting(true);
    try {
      await overtimeService.createOvertime({
        approvedDate: otDate,
        approvedStartTime: startTime,
        approvedEndTime: endTime,
        reason: reason || 'Tăng ca hoàn thành công việc theo dự án'
      });
      showToast('Đã gửi đơn đăng ký làm thêm giờ thành công! Đang chờ Quản lý phê duyệt.');
      setIsCreateModalOpen(false);
      setReason('');
      fetchOvertimes();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Có lỗi xảy ra khi tạo đơn');
    } finally {
      setSubmitting(false);
    }
  };

  // ponytail: trang đơn cá nhân — duyệt/từ chối nằm bên /management/requests

  // Popup xác nhận hủy đơn (thay confirm() native)
  const [cancelTarget, setCancelTarget] = useState<string | null>(null);
  const [isCancelling, setIsCancelling] = useState(false);

  const handleCancelConfirm = async () => {
    if (!cancelTarget) return;
    setIsCancelling(true);
    try {
      await overtimeService.cancelOvertime(cancelTarget);
      showToast('Đã hủy đơn làm thêm giờ thành công');
      setCancelTarget(null);
      fetchOvertimes();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Không thể hủy đơn');
    } finally {
      setIsCancelling(false);
    }
  };

  const handleExport = async () => {
    setExporting(true);
    try {
      const blob = await overtimeService.exportExcel({
        fromDate: appliedFilters.fromDate || undefined,
        toDate: appliedFilters.toDate || undefined,
        status: appliedFilters.status !== 'ALL' ? appliedFilters.status : undefined,
        keyword: appliedFilters.keyword || undefined
      });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `Bao_Cao_Tang_Ca_${new Date().toISOString().split('T')[0]}.xlsx`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
      showToast('Tải xuống báo cáo làm thêm giờ Excel thành công!');
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Xuất báo cáo thất bại');
    } finally {
      setExporting(false);
    }
  };

  const statusBadge = (status: OvertimeStatus | string) => {
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
            <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-orange-600 bg-orange-50 px-2.5 py-1 rounded-full border border-orange-200 mb-2">
              <Briefcase className="h-3.5 w-3.5" />
              <span>Phân hệ Làm Thêm Giờ</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Quản Lý Làm Thêm Giờ
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Đăng ký tăng ca, hệ số áp dụng theo ngày thường 1.5x / cuối tuần 2.0x / ngày lễ 3.0x, ca ban đêm tính 2.0x / 2.7x / 3.9x và đối soát quẹt thẻ thực tế.
            </p>
          </div>

          <div className="flex items-center gap-2.5 flex-wrap">
            <button
              onClick={() => setIsCreateModalOpen(true)}
              className="inline-flex items-center gap-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-orange-500/20 transition cursor-pointer"
            >
              <Plus className="h-4 w-4" />
              <span>Đăng ký làm thêm giờ</span>
            </button>

            {(isHR || can('OVERTIME_VIEW_ALL')) && (
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

        {/* Rate Information Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
          <div className="rounded-2xl bg-white p-4 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Ngày Thường</span>
              <div className="mt-1 text-2xl font-black text-slate-900">1.5x</div>
              <span className="text-[10px] text-slate-400">150% tiền lương cơ bản</span>
            </div>
            <div className="p-3 rounded-xl bg-blue-50 text-blue-600"><Clock className="h-5 w-5" /></div>
          </div>

          <div className="rounded-2xl bg-white p-4 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Cuối Tuần (T7/CN)</span>
              <div className="mt-1 text-2xl font-black text-indigo-600">2.0x</div>
              <span className="text-[10px] text-indigo-500">200% tiền lương cơ bản</span>
            </div>
            <div className="p-3 rounded-xl bg-indigo-50 text-indigo-600"><Calendar className="h-5 w-5" /></div>
          </div>

          <div className="rounded-2xl bg-white p-4 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Ngày Lễ & Tết</span>
              <div className="mt-1 text-2xl font-black text-orange-600">3.0x</div>
              <span className="text-[10px] text-orange-500">300% tiền lương cơ bản</span>
            </div>
            <div className="p-3 rounded-xl bg-orange-50 text-orange-600"><Sparkles className="h-5 w-5" /></div>
          </div>

          <div className="rounded-2xl bg-white p-4 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Ban Đêm (22h - 06h)</span>
              <div className="mt-1 text-2xl font-black text-purple-600">2.0 / 2.7 / 3.9x</div>
              <span className="text-[10px] text-purple-500">Theo ngày thường / cuối tuần / lễ</span>
            </div>
            <div className="p-3 rounded-xl bg-purple-50 text-purple-600"><Moon className="h-5 w-5" /></div>
          </div>
        </div>

        {/* ponytail: bỏ pill chuyển scope — trang đơn cá nhân chỉ hiện đơn của mình */}

        {/* Filter Toolbar */}
        <form ref={filterFormRef} onSubmit={handleApplyFilters} className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
              <Filter className="h-4 w-4 text-orange-600" />
              <span>Bộ lọc đơn làm thêm giờ</span>
            </div>
            {(appliedFilters.status !== 'ALL' || appliedFilters.fromDate || appliedFilters.toDate || appliedFilters.keyword || appliedFilters.dept !== 'ALL') && (
              <button
                type="button"
                onClick={handleResetFilters}
                className="text-xs text-orange-600 hover:text-orange-800 font-semibold cursor-pointer"
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
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-orange-600 focus:outline-hidden font-mono"
              />
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">Đến ngày</label>
              <input
                type="date"
                name="toDate"
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-orange-600 focus:outline-hidden font-mono"
              />
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">Trạng thái đơn</label>
              <select
                name="status"
                defaultValue="ALL"
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-orange-600 focus:outline-hidden"
              >
                <option value="ALL">Tất cả trạng thái</option>
                <option value="pending">Đang chờ duyệt</option>
                <option value="accepted">Đã chấp thuận</option>
                <option value="rejected">Đã từ chối</option>
              </select>
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">
                Tìm kiếm
              </label>
              <div className="relative">
                <Search className="h-4 w-4 text-slate-400 absolute left-2.5 top-2.5" />
                <input
                  type="text"
                  name="keyword"
                  placeholder="Tìm tên, mã, lý do..."
                  className="w-full rounded-xl border border-slate-200 py-2 pl-8 pr-3 text-xs text-slate-800 focus:border-orange-600 focus:outline-hidden"
                />
              </div>
            </div>
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
              className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-xs font-bold shadow-xs transition cursor-pointer"
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
              Lịch sử đơn làm thêm giờ của tôi
            </h3>
            <span className="text-xs font-semibold text-slate-500">
              {loading ? 'Đang tải...' : `${totalElements} bản ghi`}
            </span>
          </div>

          {loading ? (
            <div className="py-12 flex flex-col items-center justify-center gap-2 text-slate-400 text-xs">
              <RefreshCw className="h-6 w-6 animate-spin text-orange-600" />
              <span>Đang tải danh sách đơn OT...</span>
            </div>
          ) : records.length === 0 ? (
            <div className="py-12 text-center text-slate-400 text-xs">
              Không có đơn làm thêm giờ nào phù hợp với bộ lọc.
            </div>
          ) : (
            <>
              {/* MOBILE CARDS VIEW (block md:hidden) */}
              <div className="block md:hidden divide-y divide-slate-100">
                {records.map(ot => (
                  <div key={ot.overtimeRecordId} className="p-4 space-y-3">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="text-[11px] font-mono text-slate-500 font-semibold">
                          Ngày {formatDateVN(ot.approvedDate)}: {ot.approvedStartTime} → {ot.approvedEndTime}
                        </div>
                      </div>
                      <div>{statusBadge(ot.status)}</div>
                    </div>

                    <div className="flex items-center gap-2 flex-wrap text-xs">
                      <span className="font-bold text-orange-700 bg-orange-50 px-2 py-0.5 rounded border border-orange-200">
                        {ot.registeredHours}h đăng ký
                      </span>
                      {ot.actualHours ? (
                        <span className="text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200 font-semibold">
                          {ot.actualHours}h thực tế
                        </span>
                      ) : null}
                      <span className="font-mono font-bold text-slate-700 bg-slate-100 px-2 py-0.5 rounded">
                        Hệ số {ot.multiplier}x
                      </span>
                    </div>

                    {ot.clockInTime && (
                      <div className="text-[11px] text-slate-600 font-mono">
                        Quẹt thẻ: {ot.clockInTime} → {ot.clockOutTime || 'Chưa quẹt ra'}
                      </div>
                    )}

                    <div className="text-xs text-slate-600 bg-slate-50 p-2.5 rounded-xl border border-slate-100">
                      <span className="font-medium text-slate-700">Lý do: </span>
                      {ot.reason}
                      {ot.rejectionReason && (
                        <div className="text-rose-600 font-semibold text-[11px] mt-1">
                          Lý do từ chối: {ot.rejectionReason}
                        </div>
                      )}
                    </div>

                    <div className="flex items-center justify-between pt-1">
                      <div className="text-[10px] text-slate-400">
                        {ot.approverName ? `Người duyệt: ${ot.approverName}` : 'Chờ phân công'}
                      </div>

                      {ot.status === 'pending' && (
                        <button
                          onClick={() => setCancelTarget(ot.overtimeRecordId)}
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
                      <th className="py-3 px-4">Ngày tăng ca</th>
                      <th className="py-3 px-4">Khung giờ đăng ký</th>
                      <th className="py-3 px-4">Giờ quẹt thẻ</th>
                      <th className="py-3 px-4">Số giờ (ĐK / TT)</th>
                      <th className="py-3 px-4">Hệ số & Chế độ</th>
                      <th className="py-3 px-4">Người duyệt</th>
                      <th className="py-3 px-4">Lý do & Phản hồi</th>
                      <th className="py-3 px-4">Trạng thái</th>
                      <th className="py-3 px-4 text-right">Thao tác</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {records.map(ot => (
                      <tr key={ot.overtimeRecordId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4 font-mono font-bold text-slate-900 whitespace-nowrap" title={ot.overtimeRecordId}>
                          {formatDateVN(ot.approvedDate)}
                        </td>
                        <td className="py-3 px-4 font-mono text-slate-800 whitespace-nowrap">
                          {ot.approvedStartTime} → {ot.approvedEndTime}
                        </td>
                        <td className="py-3 px-4 font-mono whitespace-nowrap">
                          {ot.clockInTime ? (
                            <span className="text-emerald-700 font-semibold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                              {ot.clockInTime} - {ot.clockOutTime || 'Chưa ra'}
                            </span>
                          ) : (
                            <span className="text-slate-400 italic">Chưa điểm danh</span>
                          )}
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <span className="font-bold text-orange-600">{ot.registeredHours}h</span>
                          {ot.actualHours ? (
                            <span className="text-slate-500 text-[11px] ml-1">({ot.actualHours}h TT)</span>
                          ) : null}
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="flex items-center gap-1.5 flex-wrap">
                            <span className="font-bold text-slate-900 bg-slate-100 px-2 py-0.5 rounded font-mono">
                              {ot.multiplier}x
                            </span>
                            {ot.isHoliday && (
                              <span className="rounded bg-orange-100 text-orange-800 text-[10px] px-1.5 py-0.5 font-bold">Ngày Lễ</span>
                            )}
                            {ot.isWeekend && (
                              <span className="rounded bg-indigo-100 text-indigo-800 text-[10px] px-1.5 py-0.5 font-bold">Cuối tuần</span>
                            )}
                            {ot.isNightTime && (
                              <span className="rounded bg-purple-100 text-purple-800 text-[10px] px-1.5 py-0.5 font-bold flex items-center gap-0.5">
                                <Moon className="h-2.5 w-2.5" /> Đêm
                              </span>
                            )}
                          </div>
                        </td>
                        <td className="py-3 px-4" title={ot.approverId || ''}>
                          {ot.approverName ? (
                            <div>
                              <div className="font-semibold text-slate-900">{ot.approverName}</div>
                              {ot.approverJob && <div className="text-[10px] text-slate-400">{ot.approverJob}</div>}
                            </div>
                          ) : (
                            <span className="text-slate-400">—</span>
                          )}
                        </td>
                        <td className="py-3 px-4 max-w-xs">
                          <div className="text-slate-700 truncate" title={ot.reason}>{ot.reason}</div>
                          {ot.rejectionReason && (
                            <div className="text-[11px] text-rose-600 font-semibold mt-0.5 bg-rose-50 p-1 rounded">
                              Từ chối: {ot.rejectionReason}
                            </div>
                          )}
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          {statusBadge(ot.status)}
                        </td>
                        <td className="py-3 px-4 text-right whitespace-nowrap">
                          {ot.status === 'pending' && (
                            <button
                              onClick={() => setCancelTarget(ot.overtimeRecordId)}
                              className="text-rose-600 hover:text-rose-800 font-bold text-xs cursor-pointer"
                            >
                              Hủy đơn
                            </button>
                          )}
                          {ot.status !== 'pending' && <span className="text-slate-400">—</span>}
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

        {/* Modal Tạo Đăng Ký OT Mới */}
        {isCreateModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 overflow-y-auto">
            <div className="relative w-full max-w-lg rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto my-8">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2 text-orange-600 font-bold text-sm">
                  <Briefcase className="h-5 w-5" />
                  <span>Đăng Ký Làm Thêm Giờ</span>
                </div>
                <button
                  onClick={() => setIsCreateModalOpen(false)}
                  className="rounded-full p-1 text-slate-400 hover:bg-slate-100 transition"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <form onSubmit={handleCreateSubmit} className="mt-4 space-y-4 text-xs">
                <div>
                  <label htmlFor="otDate" className="block font-bold text-slate-700 mb-1">Ngày làm thêm giờ</label>
                  <input
                    id="otDate"
                    type="date"
                    value={otDate}
                    min={todayStr}
                    onChange={e => setOtDate(e.target.value)}
                    required
                    className="w-full rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label htmlFor="startTime" className="block font-bold text-slate-700 mb-1">Giờ bắt đầu</label>
                    <input
                      id="startTime"
                      type="time"
                      step={900}
                      value={startTime}
                      onChange={e => setStartTime(e.target.value)}
                      required
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-sm font-mono text-slate-800 tabular-nums"
                    />
                  </div>
                  <div>
                    <label htmlFor="endTime" className="block font-bold text-slate-700 mb-1">
                      Giờ kết thúc
                      {preview?.endDate && (
                        <span className="ml-1 font-semibold text-indigo-600">
                          (hôm sau {formatDateVN(preview.endDate)})
                        </span>
                      )}
                    </label>
                    <input
                      id="endTime"
                      type="time"
                      step={900}
                      value={endTime}
                      onChange={e => setEndTime(e.target.value)}
                      required
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-sm font-mono text-slate-800 tabular-nums"
                    />
                  </div>
                </div>

                <div className="flex flex-wrap items-center gap-1.5">
                  <span className="text-[11px] font-bold text-slate-500 mr-0.5">Ca nhanh:</span>
                  {OT_PRESETS.map(p => (
                    <button
                      key={p.label}
                      type="button"
                      onClick={() => { setStartTime(p.start); setEndTime(p.end); }}
                      className="rounded-lg border border-slate-200 bg-white px-2 py-1 text-[11px] font-semibold text-slate-600 hover:border-orange-300 hover:bg-orange-50 hover:text-orange-700 transition"
                    >
                      {p.label}
                    </button>
                  ))}
                </div>

                {/* Live OT Calculation Box */}
                <div className="rounded-2xl bg-orange-50/70 p-4 border border-orange-200/80 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-orange-900 flex items-center gap-1.5">
                      <Sparkles className="h-4 w-4 text-orange-600" />
                      <span>Dự tính thời gian & hệ số làm thêm</span>
                    </span>
                    <span className="font-black text-orange-700 text-sm font-mono tabular-nums">
                      {previewLoading ? '…' : `${totalHours} giờ`}
                    </span>
                  </div>

                  <div className="grid grid-cols-4 gap-2 text-[11px] pt-1">
                    <div className="bg-white p-2 rounded-lg border border-orange-100 text-center">
                      <span className="text-slate-400 block">Thực tế:</span>
                      <span className="font-bold text-slate-900 text-xs tabular-nums">
                        {previewLoading ? '…' : `${totalHours}h`}
                      </span>
                    </div>
                    <div className="bg-white p-2 rounded-lg border border-orange-100 text-center">
                      <span className="text-slate-400 block">Hệ số:</span>
                      <span className="font-black text-orange-600 text-xs tabular-nums">
                        {previewLoading ? '…' : `${preview?.multiplier ?? 0}x`}
                      </span>
                    </div>
                    <div className="bg-white p-2 rounded-lg border border-orange-100 text-center">
                      <span className="text-slate-400 block">Giờ tính tiền:</span>
                      <span className="font-black text-emerald-600 text-xs tabular-nums">
                        {previewLoading ? '…' : `${(preview?.paidHours ?? 0).toFixed(1)}h`}
                      </span>
                    </div>
                    <div className="bg-white p-2 rounded-lg border border-orange-100 text-center">
                      <span className="text-slate-400 block">Phân loại:</span>
                      <span className="font-bold text-slate-800 text-xs leading-tight">
                        {previewLoading ? '…' : preview ? otTypeLabel(preview) : 'Không tính được'}
                      </span>
                    </div>
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Lý do làm thêm giờ</label>
                  <textarea
                    rows={3}
                    value={reason}
                    onChange={e => setReason(e.target.value)}
                    required
                    placeholder="Nhập lý do chi tiết (ví dụ: hoàn thành sprint release đúng hạn, hỗ trợ triển khai hệ thống ngoài giờ...)"
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
                    disabled={submitting || totalHours <= 0}
                    className="flex items-center gap-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 disabled:opacity-50 text-white px-5 py-2 font-bold shadow-md shadow-orange-500/20 transition cursor-pointer"
                  >
                    {submitting ? (
                      <>
                        <RefreshCw className="h-4 w-4 animate-spin" />
                        <span>Đang gửi đơn...</span>
                      </>
                    ) : (
                      <>
                        <Send className="h-4 w-4" />
                        <span>Gửi đơn làm thêm</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Popup xác nhận hủy đơn */}
        <ConfirmDialog
          open={cancelTarget !== null}
          title="Hủy đơn làm thêm giờ?"
          body="Đơn của bạn sẽ bị rút lại. Bạn có thể đăng ký mới sau nếu đổi ý."
          confirmLabel="Hủy đơn"
          busy={isCancelling}
          onConfirm={handleCancelConfirm}
          onClose={() => !isCancelling && setCancelTarget(null)}
        />
      </div>
    </AppShell>
  );
}
